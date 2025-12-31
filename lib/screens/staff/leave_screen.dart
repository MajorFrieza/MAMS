import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  String? selectedLeaveType;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedFileName;
  PlatformFile? _selectedFile;
  final List<String> leaveTypes = ['Annual Leave', 'Compassionate Leave'];

  // Live leave history and balances
  List<Map<String, dynamic>> leaveHistory = [];
  Map<String, int> leaveBalances = {'Annual': 0, 'Compassionate': 0};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _leaveSub;
  StreamSubscription? _balanceSub; // Real-time balance updates
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // Enforce 5MB max
        final sizeBytes = file.size;
        const maxBytes = 5 * 1024 * 1024;
        if (sizeBytes > maxBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File too large. Max size is 5MB.')),
          );
          return;
        }
        setState(() {
          _selectedFile = file;
          selectedFileName = file.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File selection failed: $e')));
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (selectedLeaveType == null || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to submit a leave'),
        ),
      );
      return;
    }

    // Validate balance before submitting
    final daysRequested = endDate!.difference(startDate!).inDays + 1;
    final balanceKey = selectedLeaveType!.toLowerCase().contains('annual')
        ? 'Annual'
        : 'Compassionate';
    final currentBalance = leaveBalances[balanceKey] ?? 0;

    if (currentBalance < daysRequested) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient $balanceKey balance. Available: $currentBalance days, Requested: $daysRequested days',
            ),
          ),
        );
      }
      return;
    }

    try {
      String? attachmentName;

      if (_selectedFile != null) {
        attachmentName = _selectedFile!.name;
      }

      final doc = {
        'staffId': user.uid,
        'staffName': user.displayName ?? user.email ?? user.uid,
        'leaveType': selectedLeaveType,
        'startDate': startDate!.toIso8601String(),
        'endDate': endDate!.toIso8601String(),
        'reason': '',
        'attachmentUrl': null,
        'attachmentName': attachmentName,
        'attachmentStatus': _selectedFile != null ? 'pending' : null,
        'status': 'Pending',
        'adminComment': null,
        'appliedDate': DateTime.now().toIso8601String(),
        'approvedDate': null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': null,
      };

      // Create the leave request immediately so user sees quick submit.
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('leaveRequests')
          .add(doc);

      // Capture the selected file locally before we reset the form
      final PlatformFile? fileToUpload = _selectedFile;
      final String? fileNameToUse = attachmentName;

      // Reset form immediately for perceived responsiveness
      if (mounted) {
        setState(() {
          selectedLeaveType = null;
          startDate = null;
          endDate = null;
          selectedFileName = null;
          _selectedFile = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted')),
        );
      }

      // If there was an attachment, upload it in the background and update the doc when done
      if (fileToUpload != null) {
        // Fire-and-forget background upload; errors handled inside
        _uploadAttachmentToDoc(
          docRef,
          fileToUpload,
          fileNameToUse ?? 'attachment',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
      }
    }
  }

  Future<void> _uploadAttachmentToDoc(
    DocumentReference docRef,
    PlatformFile file,
    String attachmentName,
  ) async {
    try {
      // Validate file
      if (file.bytes == null && file.path == null) {
        await docRef.update({
          'attachmentStatus': 'failed',
          'attachmentError': 'File invalid',
        });
        return;
      }

      if (file.path != null && !await File(file.path!).exists()) {
        await docRef.update({
          'attachmentStatus': 'failed',
          'attachmentError': 'File not found',
        });
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await docRef.update({
          'attachmentStatus': 'failed',
          'attachmentError': 'User not signed in',
        });
        return;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('leave_attachments')
          .child(user.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}_$attachmentName');

      final ext = (file.extension ?? '').toLowerCase();
      String? contentType;
      if (ext == 'pdf') contentType = 'application/pdf';
      if (ext == 'jpg' || ext == 'jpeg') contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';

      final metadata = SettableMetadata(contentType: contentType);

      UploadTask uploadTask;
      if (file.bytes != null) {
        uploadTask = storageRef.putData(file.bytes!, metadata);
      } else {
        uploadTask = storageRef.putFile(File(file.path!), metadata);
      }

      // Track progress in UI
      if (mounted) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });
      }

      final sub = uploadTask.snapshotEvents.listen((snap) {
        final total = snap.totalBytes;
        final transferred = snap.bytesTransferred;
        double progress = 0.0;
        if (total > 0) progress = transferred / total;
        if (mounted) {
          setState(() => _uploadProgress = progress);
        }
      });

      TaskSnapshot snapshot;
      try {
        snapshot = await uploadTask.timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Upload timed out'),
        );
      } finally {
        await sub.cancel();
      }

      if (snapshot.state != TaskState.success) {
        await docRef.update({
          'attachmentStatus': 'failed',
          'attachmentError': 'Upload failed: ${snapshot.state}',
        });
        return;
      }

      try {
        final url = await snapshot.ref.getDownloadURL();
        await docRef.update({
          'attachmentUrl': url,
          'attachmentStatus': 'uploaded',
        });
      } catch (e) {
        // Upload succeeded but download URL unavailable (permissions); mark accordingly
        await docRef.update({
          'attachmentStatus': 'uploaded_no_url',
          'attachmentError': e.toString(),
        });
      }
    } catch (e) {
      try {
        await docRef.update({
          'attachmentStatus': 'failed',
          'attachmentError': e.toString(),
        });
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Apply Leave',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Request time off for your absences',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                if (_isUploading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: _uploadProgress),
                      SizedBox(height: 8),
                      Text(
                        'Uploading attachment... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),

                // Leave Balance Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.yellow[300]!, width: 2),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining Leave Balance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.calendar_today, color: Colors.yellow[700]),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    'Annual',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '${leaveBalances['Annual']}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    'Compassionate',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '${leaveBalances['Compassionate']}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // New Leave Request Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'New Leave Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Type of Leave
                      Text(
                        'Type of Leave',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedLeaveType,
                          hint: Text('Select leave type'),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: leaveTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedLeaveType = value);
                          },
                        ),
                      ),
                      SizedBox(height: 20),

                      // Start Date
                      Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            startDate == null
                                ? 'Select Start Date'
                                : _formatDate(startDate),
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => startDate = picked);
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 20),

                      // End Date
                      Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            endDate == null
                                ? 'Select End Date'
                                : _formatDate(endDate),
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  endDate ?? (startDate ?? DateTime.now()),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => endDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Attachment Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attachment (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[400]!,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 16,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Drag and drop your file here, or',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () async {
                                await _pickFile();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              child: Text('Browse Files'),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'PDF, DOC, DOCX, JPG, PNG (Max 5MB)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedFileName != null) ...[
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedFileName!,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() {
                                  selectedFileName = null;
                                  _selectedFile = null;
                                }),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _submitLeaveRequest();
                    },
                    icon: Icon(Icons.send),
                    label: Text('Submit Leave Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[600],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Leave History Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Leave History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: leaveHistory.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 20),
                        itemBuilder: (context, index) {
                          final leave = leaveHistory[index];
                          final statusLower = (leave['status'] ?? '')
                              .toString()
                              .toLowerCase();
                          final isApproved = statusLower == 'approved';
                          final isPending = statusLower == 'pending';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          leave['dateRange'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          leave['days'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isApproved
                                          ? Colors.green[100]
                                          : isPending
                                          ? Colors.yellow[100]
                                          : Colors.red[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isApproved
                                              ? Icons.check_circle
                                              : isPending
                                              ? Icons.access_time
                                              : Icons.cancel,
                                          size: 16,
                                          color: isApproved
                                              ? Colors.green
                                              : isPending
                                              ? Colors.orange
                                              : Colors.red,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          leave['status'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isApproved
                                                ? Colors.green
                                                : isPending
                                                ? Colors.orange
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  leave['leaveType'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              if (leave['attachmentUrl'] != null)
                                TextButton.icon(
                                  onPressed: () => _openAttachment(
                                    leave['attachmentUrl'] as String,
                                  ),
                                  icon: const Icon(Icons.insert_drive_file),
                                  label: Text(
                                    leave['attachmentName'] ??
                                        leave['attachment'] ??
                                        'View attachment',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Applied on ${leave['appliedDate'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // load leave balances from user doc; initialize defaults to 1 if not present
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data['leaveBalances'] is Map) {
        final Map balances = data['leaveBalances'];
        if (mounted) {
          setState(() {
            // Reset negative balances to default (1)
            final annualBalance = (balances['Annual'] as int?) ?? 1;
            final compassionateBalance =
                (balances['Compassionate'] as int?) ?? 1;
            leaveBalances['Annual'] = annualBalance < 0 ? 1 : annualBalance;
            leaveBalances['Compassionate'] = compassionateBalance < 0
                ? 1
                : compassionateBalance;
          });
        }
        // Persist corrected balances if any were negative
        final annualBalance = (balances['Annual'] as int?) ?? 1;
        final compassionateBalance = (balances['Compassionate'] as int?) ?? 1;
        if (annualBalance < 0 || compassionateBalance < 0) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'leaveBalances': {
                  'Annual': annualBalance < 0 ? 1 : annualBalance,
                  'Compassionate': compassionateBalance < 0
                      ? 1
                      : compassionateBalance,
                },
              }, SetOptions(merge: true));
        }
      } else {
        // Initialize default balances if not present
        if (mounted) {
          setState(() {
            leaveBalances = {'Annual': 1, 'Compassionate': 1};
          });
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'leaveBalances': {'Annual': 1, 'Compassionate': 1},
        }, SetOptions(merge: true));
      }
    } else {
      // Create user doc with default balances
      if (mounted) {
        setState(() {
          leaveBalances = {'Annual': 1, 'Compassionate': 1};
        });
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'leaveBalances': {'Annual': 1, 'Compassionate': 1},
      });
    }

    // Real-time listener for balance updates
    _balanceSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          if (mounted) {
            final balances = (doc.data()?['leaveBalances'] as Map?) ?? {};
            setState(() {
              leaveBalances = {
                'Annual': (balances['Annual'] as int?) ?? 1,
                'Compassionate': (balances['Compassionate'] as int?) ?? 1,
              };
            });
          }
        });

    // subscribe to leaveRequests collection for this user
    _leaveSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('leaveRequests')
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              leaveHistory = snapshot.docs.map((d) {
                final m = d.data();
                final startDateStr = m['startDate'] as String?;
                final endDateStr = m['endDate'] as String?;
                DateTime? startDate, endDate;
                if (startDateStr != null) {
                  try {
                    startDate = DateTime.parse(startDateStr);
                  } catch (e) {
                    startDate = null;
                  }
                }
                if (endDateStr != null) {
                  try {
                    endDate = DateTime.parse(endDateStr);
                  } catch (e) {
                    endDate = null;
                  }
                }
                String formatApplied(String raw) {
                  if (raw.isEmpty) return '';
                  try {
                    final dt = DateTime.parse(raw);
                    return _formatDate(dt);
                  } catch (_) {
                    return raw.split('T').first;
                  }
                }

                return {
                  'dateRange': (startDate != null && endDate != null)
                      ? '${_formatDate(startDate)} - ${_formatDate(endDate)}'
                      : '${startDateStr ?? ''} - ${endDateStr ?? ''}',
                  'days': (startDate != null && endDate != null)
                      ? '${endDate.difference(startDate).inDays + 1} day(s)'
                      : '',
                  'leaveType': m['leaveType'] ?? '',
                  'status': m['status'] ?? '',
                  'appliedDate': formatApplied(m['appliedDate'] ?? ''),
                  'attachmentUrl': m['attachmentUrl'],
                  'attachmentName':
                      m['attachmentName'] ??
                      (m['attachmentUrl'] != null
                          ? (m['attachmentUrl'] as String).split('/').last
                          : null),
                };
              }).toList();
            });
          }
        });
  }

  @override
  void dispose() {
    _leaveSub?.cancel();
    _balanceSub?.cancel();
    super.dispose();
  }

  Future<void> _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open attachment')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment')),
        );
      }
    }
  }
}
