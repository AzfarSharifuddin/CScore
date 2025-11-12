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
  late TextEditingController _scoreController;
  late String _selectedStatus;
  bool _isSaving = false;

  bool get isLearning => widget.record.type == 'learning';

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(text: widget.record.score.toString());
    final raw = (widget.record.status ?? '').trim();
    _selectedStatus = raw.isNotEmpty ? _capitalizeStatus(raw) : 'In Progress';
  }

  String _capitalizeStatus(String s) {
    final lower = s.toLowerCase();
    if (lower == 'done' || lower == 'completed') return 'Completed';
    if (lower == 'in progress') return 'In Progress';
    if (lower == 'not started') return 'Not Started';
    // default: keep title-case
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'not started':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _save() async {
    if (!isLearning) {
      // validate score
      final val = _scoreController.text.trim();
      if (val.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a score')));
        return;
      }
      final parsed = double.tryParse(val);
      if (parsed == null || parsed < 0 || parsed > 100) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Score must be a number between 0 and 100')));
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final updated = widget.record.copyWith(
      score: isLearning ? widget.record.score : double.tryParse(_scoreController.text) ?? widget.record.score,
      status: isLearning ? _selectedStatus : widget.record.status,
      type: widget.record.type, // preserve type
      completedAt: DateTime.now(),
    );

    try {
      await _progressService.updateProgress(user.uid, updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
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
        title: Text(isLearning ? 'Edit Learning Progress' : 'Edit Activity Progress', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.record.activityName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              if (isLearning) ...[
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Not Started', child: Text('Not Started')),
                  ],
                  onChanged: (v) => setState(() => _selectedStatus = v ?? 'In Progress'),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Current Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _statusColor(_selectedStatus).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text(_selectedStatus, style: TextStyle(color: _statusColor(_selectedStatus), fontWeight: FontWeight.w600)),
                  )
                ])
              ] else ...[
                TextField(controller: _scoreController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Score', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
