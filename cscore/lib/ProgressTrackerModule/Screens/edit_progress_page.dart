// edit_progress_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/ProgressTrackerModule/Model/progress_record.dart';
import 'package:cscore/ProgressTrackerModule/Services/progress_service.dart';

class EditProgressPage extends StatefulWidget {
  final ProgressRecord record;

  const EditProgressPage({super.key, required this.record});

  @override
  State<EditProgressPage> createState() => _EditProgressPageState();
}

class _EditProgressPageState extends State<EditProgressPage> {
  final ProgressService _progressService = ProgressService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _activityNameController;
  late final TextEditingController _scoreController;
  late String _selectedStatus;
  bool _isSaving = false;

  // Decide learning vs activity:
  // We treat a record as "learning" when status looks like a learning-status value.
  bool get isLearningProgress {
    final s = (widget.record.status ?? '').toString().toLowerCase();
    return s.contains('progress') || s.contains('done') || s.contains('completed') || s.contains('not started');
  }

  @override
  void initState() {
    super.initState();

    // Safely initialize controllers and status (handle possible nulls)
    _activityNameController =
        TextEditingController(text: widget.record.activityName ?? '');
    // If score may be null, fallback to '0'. Otherwise toString() is fine.
    _scoreController =
        TextEditingController(text: (widget.record.score ?? 0.0).toString());
    final rawStatus = (widget.record.status ?? '').toString().trim();
    _selectedStatus = rawStatus.isNotEmpty ? rawStatus : 'In Progress';
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return Colors.green.shade600;
      case 'in progress':
        return Colors.orange.shade600;
      case 'not started':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _updateProgress() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final updated = ProgressRecord(
        id: widget.record.id,
        // activityName remains unchanged for learning progress (read-only),
        activityName: isLearningProgress
            ? widget.record.activityName ?? ''
            : _activityNameController.text.trim(),
        completedAt: DateTime.now(),
        score: isLearningProgress
            ? (widget.record.score ?? 0.0)
            : double.tryParse(_scoreController.text.trim()) ?? 0.0,
        status: isLearningProgress ? _selectedStatus : (widget.record.status ?? ''),
      );

      await _progressService.updateProgress(user.uid, updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F7),
        title: const Text(
          'Edit Progress',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLearningProgress ? 'Edit Learning Progress' : 'Edit Activity Progress',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Activity name (read-only for learning progress)
                TextFormField(
                  controller: _activityNameController,
                  enabled: !isLearningProgress,
                  decoration: InputDecoration(
                    labelText: 'Activity Name',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isLearningProgress ? Colors.grey.shade200 : Colors.white,
                  ),
                  validator: (val) {
                    if (!isLearningProgress && (val == null || val.trim().isEmpty)) {
                      return 'Activity name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Status dropdown for learning, score input for activity
                if (isLearningProgress) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'Not Started', child: Text('Not Started')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Current Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(_selectedStatus).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _selectedStatus,
                          style: TextStyle(
                            color: _statusColor(_selectedStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextFormField(
                    controller: _scoreController,
                    decoration: InputDecoration(
                      labelText: 'Score',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Score is required';
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed < 0 || parsed > 100) {
                        return 'Score must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                ],

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateProgress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
