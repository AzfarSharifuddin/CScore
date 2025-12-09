import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for getting the editor's UID

import 'package:cscore/QuizModule/Models/student_attempt_row.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'package:cscore/QuizModule/Services/quiz_service.dart';

// NOTE: Ensure your project structure allows imports of QuestionModel if it's not
// nested within QuizModel (assuming it is for this code).

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

// CONVERTED TO STATEFULWIDGET
class ViewAttemptDetailsPage extends StatefulWidget {
  final StudentAttemptRow attemptRow;

  const ViewAttemptDetailsPage({super.key, required this.attemptRow});

  @override
  State<ViewAttemptDetailsPage> createState() => _ViewAttemptDetailsPageState();
}

class _ViewAttemptDetailsPageState extends State<ViewAttemptDetailsPage> {
  // --- STATE MANAGEMENT FOR EDITING ---
  final TextEditingController _feedbackController = TextEditingController();
  // Flag to control the edit/save button visibility and text field state
  bool _isEditing = false; 
  // Flag to show the loading indicator during Firestore save
  bool _isSaving = false;
  // Holds the specific audit document ID for the subjective question currently being viewed/edited
  String? _currentAuditDocId; 
  // Holds the specific question ID for the objective question currently being viewed/edited
  String? _currentQuestionId; 

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // --- DATA FETCHING ---

  Future<Map<String, dynamic>?> _fetchAttemptData() async {
    final progressRef = FirebaseFirestore.instance
        .collection('progress')
        .doc(widget.attemptRow.userId)
        .collection('quizProgress')
        .doc(widget.attemptRow.quizId);

    final snapshot = await progressRef.get();
    return snapshot.data();
  }

  Future<QuizModel> _fetchQuiz() async {
    final quiz = await QuizService().fetchQuizById(widget.attemptRow.quizId);

    if (quiz == null) {
      throw Exception("Quiz with ID ${widget.attemptRow.quizId} not found.");
    }
    return quiz;
  }
  
  // --- SAVE LOGIC FOR SUBJECTIVE QUESTIONS ---

  Future<void> _saveEditedSubjectiveFeedback() async {
    if (_currentAuditDocId == null || _feedbackController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    
    try {
        await FirebaseFirestore.instance
            .collection('ai_generated_content')
            .doc(_currentAuditDocId!)
            .update({
                'ai_output_ms': _feedbackController.text.trim(),
                'editor_modified_on': FieldValue.serverTimestamp(),
                'editor_user_id': FirebaseAuth.instance.currentUser?.uid,
            });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subjective feedback saved successfully!')),
        );

        // Turn off editing mode and force UI to rebuild with the new content
        setState(() {
            _isEditing = false;
            _isSaving = false;
            // No need to clear controller, it holds the saved text
        });

    } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save subjective feedback: $e')),
        );
        setState(() => _isSaving = false);
    }
}

  // --- SAVE LOGIC FOR OBJECTIVE QUESTIONS (Cache Update) ---

  Future<void> _saveEditedObjectiveFeedback() async {
    // Note: _currentQuestionId holds the question ID when editing an objective question
    if (_currentQuestionId == null || _feedbackController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    
    try {
        // Targets the single cache document using the Question ID
        await FirebaseFirestore.instance
            .collection('ai_generated_content')
            .doc(_currentQuestionId!) 
            .update({
                'ai_output_ms': _feedbackController.text.trim(),
                'editor_modified_on': FieldValue.serverTimestamp(),
                'editor_user_id': FirebaseAuth.instance.currentUser?.uid,
            });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Objective explanation cache updated successfully!')),
        );

        // Turn off editing mode and force UI to rebuild
        setState(() {
            _isEditing = false;
            _isSaving = false;
            // No need to clear controller, it holds the saved text
        });

    } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save objective explanation: $e')),
        );
        setState(() => _isSaving = false);
    }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Attempt by ${widget.attemptRow.userName}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: mainColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([_fetchAttemptData(), _fetchQuiz()]).then((results) {
          final attemptData = results[0] as Map<String, dynamic>?;
          final quizModel = results[1] as QuizModel;

          if (attemptData == null) {
            throw Exception("Attempt data not found.");
          }

          return {
            'quiz': quizModel,
            'answers': attemptData['answers'] as List<dynamic>? ?? [],
          };
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: mainColor));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Error loading details: ${snapshot.error}"));
          }

          final quiz = snapshot.data!['quiz'] as QuizModel;
          final userAnswers = snapshot.data!['answers'] as List<dynamic>;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quiz.questions.length,
            itemBuilder: (context, index) {
              final question = quiz.questions[index];
              final userAnswer = userAnswers.length > index ? userAnswers[index] : null;

              return _buildQuestionCard(index, question, userAnswer, widget.attemptRow.userId);
            },
          );
        },
      ),
    );
  }

  // --- QUESTION CARD BUILDER ---
  Widget _buildQuestionCard(
      int index, QuestionModel question, dynamic userAnswer, String userId) {
    final isObjective = question.type == "objective";
    final isCorrect = isObjective
        ? (userAnswer is int && userAnswer == question.answer)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${index + 1}: (${isObjective ? "Objective" : "Subjective"})",
              style: const TextStyle(fontWeight: FontWeight.w600, color: mainColor),
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Divider(height: 25),
            
            if (isObjective)
              _buildObjectiveAnswer(question, userAnswer as int?, isCorrect),
            if (!isObjective)
              _buildSubjectiveAnswer(question, userAnswer as String?, userId),
          ],
        ),
      ),
    );
  }
  
  // --- OBJECTIVE ANSWER BUILDER (NOW EDITABLE) ---
  Widget _buildObjectiveAnswer(
      QuestionModel question, int? selectedIndex, bool? isCorrect) {
    String selectedText = selectedIndex != null && selectedIndex < (question.options?.length ?? 0)
        ? question.options![selectedIndex]
        : "No answer selected";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          label: "Selected Answer:",
          value: selectedText,
          color: isCorrect == true ? Colors.green.shade700 : Colors.red.shade700,
          icon: isCorrect == true ? Icons.check_circle : Icons.cancel,
        ),
        
        // Fetch AI Explanation from cache
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('ai_generated_content').doc(question.id).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading AI explanation...");
            }
            
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final rawExplanation = data?['ai_output_ms'] as String? ?? "No AI explanation found in cache.";
            
            String feedbackPrefix = isCorrect == true ? "✅ Betul! " : "❌ Salah. ";
            String currentFeedback = feedbackPrefix + rawExplanation;

            // --- EDITING STATE MANAGEMENT FOR OBJECTIVE ---
            // If we are not currently editing, set the text controller and the question ID
            if (!_isEditing) {
                _feedbackController.text = rawExplanation;
                _currentQuestionId = question.id; // Store ID for save function
            }
            
            Widget feedbackWidget = _isEditing && _currentQuestionId == question.id
                ? _buildEditableFeedback() // Show editable field for this question
                : _buildFeedbackBox(message: currentFeedback, isCorrect: isCorrect); // Show read-only box
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                feedbackWidget,
                const SizedBox(height: 10),

                // 5. Edit/Save Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isEditing)
                      TextButton(
                        onPressed: () {
                          // Enter edit mode for this specific question
                          _feedbackController.text = rawExplanation; 
                          setState(() {
                            _isEditing = true;
                            _currentQuestionId = question.id;
                            _currentAuditDocId = null; // Clear subjective ID
                          });
                        },
                        child: const Text("Edit AI Explanation"),
                      ),
                    if (_isEditing && _currentQuestionId == question.id) ...[
                      TextButton(
                        onPressed: () {
                          setState(() => _isEditing = false); // Cancel edit
                        },
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveEditedObjectiveFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Save Cache"),
                      ),
                    ]
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- SUBJECTIVE ANSWER BUILDER (WITH EDIT LOGIC) ---
  Widget _buildSubjectiveAnswer(
      QuestionModel question, String? userAnswer, String userId) {
    return FutureBuilder<QuerySnapshot>(
      // Fetch the specific AI subjective grade audit
      future: FirebaseFirestore.instance.collection('ai_generated_content')
          .where('content_type', isEqualTo: 'SUBJECTIVE_GRADE')
          .where('related_question_id', isEqualTo: question.id)
          .where('related_user_id', isEqualTo: userId)
          .orderBy('generated_on', descending: true)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading student answer and AI grade...");
        }
        
        final doc = snapshot.data?.docs.firstOrNull;
        final gradeData = doc?.data() as Map<String, dynamic>?;
        
        final gradeMessage = gradeData?['ai_output_ms'] as String? ?? "No AI grade available for this attempt.";
        final isGradedCorrect = gradeData?['grade_correct'] as bool?;

        // Store the audit document ID for saving later
        final auditDocId = doc?.id; 

        // --- EDITING STATE MANAGEMENT FOR SUBJECTIVE ---
        // If we are not currently editing, set the text controller and the audit ID
        if (!_isEditing) {
            _feedbackController.text = gradeMessage;
            _currentAuditDocId = auditDocId; // Store ID for save function
        }

        // Handle case where document is not found (cannot edit)
        bool canEdit = auditDocId != null;
        
        Widget feedbackWidget = _isEditing && _currentAuditDocId == auditDocId
            ? _buildEditableFeedback() 
            : _buildFeedbackBox(message: gradeMessage, isCorrect: isGradedCorrect);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              label: "Student Answer:",
              value: userAnswer ?? "No answer submitted.",
              color: mainColor,
              icon: Icons.edit_note,
              isAnswer: true,
            ),
            const SizedBox(height: 10),
            
            // Display Logic: Editable field vs Read-only Box
            feedbackWidget,

            // Edit/Save Button Row
            if (canEdit)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isEditing)
                    TextButton(
                      onPressed: () {
                        // Enter edit mode for this specific question
                        _feedbackController.text = gradeMessage;
                        setState(() {
                          _isEditing = true;
                          _currentAuditDocId = auditDocId;
                          _currentQuestionId = null; // Clear objective ID
                        });
                      },
                      child: const Text("Edit AI Feedback"),
                    ),
                  if (_isEditing && _currentAuditDocId == auditDocId) ...[
                    TextButton(
                      onPressed: () {
                        setState(() => _isEditing = false); // Cancel edit
                      },
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveEditedSubjectiveFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Save Changes"),
                    ),
                  ]
                ],
              ),
          ],
        );
      },
    );
  }
  
  // --- UI Helper for Editable Field (Shared) ---
  Widget _buildEditableFeedback() {
    return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
            border: Border.all(color: mainColor, width: 2),
            borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
            controller: _feedbackController,
            maxLines: 8,
            decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Enter your corrected feedback...",
            ),
            style: const TextStyle(fontSize: 15),
        ),
    );
  }


  // --- Consolidated Feedback Box Logic (Shared) ---
  Widget _buildFeedbackBox({
    required String message,
    required bool? isCorrect,
  }) {
    Color boxColor = isCorrect == true
              ? Colors.green.withOpacity(0.15)
              : (isCorrect == false ? Colors.orange.withOpacity(0.15) : Colors.grey.shade50);
    Color borderColor = isCorrect == true ? Colors.green : (isCorrect == false ? Colors.orange : mainColor);
    
    // NOTE: For Objective answers, we need to strip the prefix before displaying if the user is editing,
    // but when displaying read-only, we should include the prefix.
    
    TextStyle textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isCorrect == true ? Colors.green[900] : (isCorrect == false ? Colors.orange[900] : Colors.black87),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message, 
        style: textStyle,
      ),
    );
  }
  
  // --- Detail Row Helper (Shared) ---
  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool isAnswer = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isAnswer ? color.withOpacity(0.08) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: isAnswer ? Colors.black87 : color,
            ),
          ),
        ),
      ],
    );
  }
}