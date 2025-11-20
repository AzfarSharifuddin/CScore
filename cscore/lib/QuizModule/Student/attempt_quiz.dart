// attempt_quiz.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cscore/QuizModule/Models/quiz_model.dart'; 
import 'score_quiz.dart';
import 'package:cscore/QuizModule/Services/gemini_service.dart';

// Assuming QuestionModel is available from the import.

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class AttemptQuizPage extends StatefulWidget {
  final QuizModel quiz;

  const AttemptQuizPage({super.key, required this.quiz});

  @override
  State<AttemptQuizPage> createState() => _AttemptQuizPageState();
}

class _AttemptQuizPageState extends State<AttemptQuizPage> {
  int currentQuestion = 0;
  int score = 0;
  List<dynamic> answers = [];

  bool showFeedback = false;
  bool isLocked = false;

  String? feedbackMessage;
  bool? feedbackCorrect;

  late Timer countdown;
  int remainingSeconds = 0;

  final TextEditingController _textController = TextEditingController();
  late VoidCallback _textListener;

  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    answers = List<dynamic>.filled(widget.quiz.questions.length, null);

    remainingSeconds = widget.quiz.duration * 60;
    startTimer();

    _textListener = () {
      if (mounted) setState(() {});
    };
    _textController.addListener(_textListener);

    initGemini();
  }
  
  Future<void> initGemini() async {
    try {
      await _geminiService.init();
    } catch (e) {
      debugPrint("❌ GeminiService init error: $e");
    }
  }

  @override
  void dispose() {
    countdown.cancel();
    _textController.removeListener(_textListener);
    _textController.dispose();
    super.dispose();
  }

  void startTimer() {
    countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (remainingSeconds <= 0) {
        // ⭐ FIX APPLIED HERE
        submitQuiz(autoSubmit: true); 
        timer.cancel();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  String formatTime(int sec) {
    int m = sec ~/ 60;
    int s = sec % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ------------------ OBJECTIVE ANSWER HANDLER (MCQ) ------------------
  Future<void> handleAnswerTap(int index) async {
    if (isLocked) return;

    final question = widget.quiz.questions[currentQuestion];
    final correctIndex = question.answer ?? -1;
    final isCorrect = index == correctIndex;

    // Safety checks (unchanged)
    if (question.options == null || correctIndex < 0 || correctIndex >= question.options!.length) {
      setState(() {
        showFeedback = true;
        feedbackCorrect = false;
        feedbackMessage = "❌ Ralat: Konfigurasi jawapan tiada untuk soalan ini.";
        isLocked = true;
      });
      return;
    }
    
    // ⭐ CRITICAL: Ensure Question ID exists
    final questionId = question.id;
    if (questionId == null || questionId.isEmpty) {
        debugPrint("❌ ERROR: Question ID is missing. Cannot use AI Caching.");
        return; 
    }

    final correctAnswerText = question.options![correctIndex];
    final selectedAnswerText = question.options![index];
    final allOptions = question.options!.join(', ');

    // 1. Lock the answer, set user choice, and show "Evaluating..." message
    setState(() {
        answers[currentQuestion] = index;
        isLocked = true;
        feedbackCorrect = isCorrect; 
        feedbackMessage = "Menilai Alasan AI..."; 
        showFeedback = true;
    });

    // 2. Increment score immediately
    if (isCorrect) score++;

    // ⭐ Caching Setup: Use the lowercase collection name
    final contentRef = FirebaseFirestore.instance.collection('ai_generated_content');
    final cacheDocId = questionId; // Use the unique question ID as the cache key
    
    // 3. Check for Cache Hit
    String? cachedExplanation;
    try {
      final docSnapshot = await contentRef.doc(cacheDocId).get();
        
      if (docSnapshot.exists && docSnapshot.data()?['content_type'] == 'QUIZ_EXPLANATION') {
        // Retrieve the stored Malay explanation
        cachedExplanation = docSnapshot.data()?['ai_output_ms'] as String?;
      }
    } catch (e) {
      debugPrint("❌ Error reading Firestore cache: $e");
    }

    // 4. If Cache HIT: Use stored data
    if (cachedExplanation != null) {
      String cleanAiMessage = cachedExplanation.replaceAll(RegExp(r'^\s*[✅❌].*?\s*'), '').trim();
      
      setState(() {
        if (isCorrect) {
            feedbackMessage = "✅ Betul! Penerangan: $cleanAiMessage (Dari Cache)";
        } else {
            feedbackMessage = "❌ Salah. Pilihan yang betul ialah **$correctAnswerText**. Penerangan: $cleanAiMessage (Dari Cache)";
        }
        feedbackCorrect = isCorrect;
      });

    } else {
      // 5. If Cache MISS: Call Gemini API
      try {
        final result = await _geminiService.evaluateSubjective(
            question: question.question,
            studentAnswer: "Pengguna memilih: $selectedAnswerText.",
            expectedAnswer: "Pilihan yang betul ialah '$correctAnswerText'. Pilihan jawapan lain adalah: $allOptions. Berikan penerangan terperinci dan pendidikan mengapa pilihan yang betul adalah jawapan terbaik. JANGAN berikan gred (betul/salah) dalam mesej respons.",
        );

        String detailedMessage = result['message'] ?? "Penjanaan alasan AI gagal.";
        String cleanAiMessage = detailedMessage.replaceAll(RegExp(r'^\s*[✅❌].*?\s*'), '').trim();

        // ⭐ Caching Write: Save the fresh AI output to Firestore
        try {
          await contentRef.doc(cacheDocId).set({
            'content_type': 'QUIZ_EXPLANATION',
            'related_question_id': questionId,
            'ai_output_ms': "Penerangan: $cleanAiMessage", // Save the clean explanation
            'generated_on': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint("❌ Error writing to Firestore cache: $e");
        }
        
        // 6. Update UI with the newly generated AI answer
        setState(() {
            if (isCorrect) {
                feedbackMessage = "✅ Betul! Penerangan: $cleanAiMessage";
            } else {
                feedbackMessage = "❌ Salah. Pilihan yang betul ialah **$correctAnswerText**. Penerangan: $cleanAiMessage";
            }
            feedbackCorrect = isCorrect;
        });

      } catch (e) {
        debugPrint("❌ Gemini API error during MCQ reason generation: $e");
        setState(() {
            feedbackMessage = "❌ Penjelasan AI Gagal: Tidak dapat mendapatkan alasan terperinci. Sila semak rangkaian.";
            feedbackCorrect = isCorrect;
        });
      }
    }
  }

  // ------------------ SUBJECTIVE HANDLER (AI Evaluation) ------------------
  Future<void> handleSubjectiveSubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _textController.text.trim();
    if (text.isEmpty || user == null) return;

    answers[currentQuestion] = text;
    setState(() => isLocked = true);

    String feedback = "Menilai...";
    
    // Display "Evaluating" message immediately
    setState(() {
      feedbackMessage = feedback;
      showFeedback = true;
      feedbackCorrect = null; // Neutral state
    });

    try {
      final question = widget.quiz.questions[currentQuestion];
      // ⭐ CRITICAL: Ensure Question ID exists for the audit trail
      final questionId = question.id;
      if (questionId == null || questionId.isEmpty) {
          debugPrint("❌ ERROR: Question ID is missing for subjective audit.");
          return; 
      }
      
      // AI Grading Call (unchanged)
      final result = await _geminiService.evaluateSubjective(
        question: question.question,
        studentAnswer: text,
        expectedAnswer: "Gred jawapan pelajar ini berdasarkan rubrik berikut: ${question.expectedAnswer ?? ""}. Berikan gred dan alasan terperinci.",
      );

      bool evaluationCorrect = result['correct'] ?? false;
      if (evaluationCorrect) score++;

      feedback = result['message'] ?? "Penilaian AI selesai.";
      
      // ⭐ Subjective Audit Write: Store unique grade for this attempt
      try {
          // Use .add() for an auto-generated ID for this unique audit record.
          await FirebaseFirestore.instance.collection('ai_generated_content').add({
            'content_type': 'SUBJECTIVE_GRADE',
            'related_question_id': questionId, // Store the Question ID
            'related_user_id': user.uid,
            'student_answer': text,
            'ai_output_ms': feedback, // Store the full grade message
            'grade_correct': evaluationCorrect,
            'generated_on': FieldValue.serverTimestamp(),
          });
      } catch (e) {
        debugPrint("❌ Error writing Subjective Audit to Firestore: $e");
      }


      setState(() {
        feedbackCorrect = evaluationCorrect;
        feedbackMessage = feedback;
        showFeedback = true;
      });
    } catch (e) {
      debugPrint("❌ Gemini API error: $e");
      setState(() {
        feedbackCorrect = false;
        feedbackMessage = "❌ Penilaian AI Gagal: Tidak dapat memproses jawapan. Cuba lagi nanti.";
        showFeedback = true;
      });
    }
  }

  // ------------------ NEXT QUESTION ------------------
  void nextQuestion() {
    if (!mounted) return;

    if (currentQuestion < widget.quiz.questions.length - 1) {
      setState(() {
        currentQuestion++;
        showFeedback = false;
        isLocked = false;
        feedbackMessage = null;
        feedbackCorrect = null;
        _textController.clear();
      });
    } else {
      submitQuiz();
    }
  }

  // ------------------ PROGRESS SAVING ------------------
  Future<void> updateProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final progressRef = FirebaseFirestore.instance
          .collection('progress')
          .doc(user.uid)
          .collection('quizProgress')
          .doc(widget.quiz.id);

      final snapshot = await progressRef.get();

      int oldHighest = 0;
      int attempts = 0;
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        oldHighest =
            (data['highestScore'] is num) ? (data['highestScore'] as num).toInt() : 0;
        attempts =
            (data['attemptCount'] is num) ? (data['attemptCount'] as num).toInt() : 0;
      }

      // Check max attempts
      if (widget.quiz.maxAttempts > 0 && attempts >= widget.quiz.maxAttempts) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tiada percubaan lagi untuk kuiz ini.")),
        );
        return;
      }

      await progressRef.set({
        'attemptCount': attempts + 1,
        'currentScore': score,
        'highestScore': score > oldHighest ? score : oldHighest,
        'totalScore': widget.quiz.questions.length,
        'attemptDate': FieldValue.serverTimestamp(),
        'answers': answers,
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint("❌ updateProgress error: $e\n$st");
    }
  }

  // ------------------ SUBMIT QUIZ ------------------
  // ⭐ FIX APPLIED HERE: Added the optional named parameter {bool autoSubmit = false}
  void submitQuiz({bool autoSubmit = false}) async {
    try {
      countdown.cancel();
    } catch (_) {}

    await updateProgress();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreQuizPage(
          quiz: widget.quiz,
          score: score,
          total: widget.quiz.questions.length,
        ),
      ),
    );
  }

  // ------------------ UI ------------------
  // ⭐ FIX: This 'build' method fulfills the abstract class State requirement.
  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[currentQuestion];
    final isObjective = question.type == "objective";

    return Scaffold(
      resizeToAvoidBottomInset: true, 
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( 
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeader(),
                const SizedBox(height: 20),
                Text(
                  question.question,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                if (isObjective) ...buildObjective(question),
                if (!isObjective) ...buildSubjective(),

                // ------------------ FEEDBACK BOX ------------------
                if (showFeedback && feedbackMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: feedbackCorrect == true
                          ? Colors.green.withOpacity(0.15)
                          : (feedbackCorrect == false ? Colors.orange.withOpacity(0.15) : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            feedbackCorrect == true ? Colors.green : (feedbackCorrect == false ? Colors.orange : Colors.grey),
                      ),
                    ),
                    child: buildFeedbackContent(feedbackMessage!, feedbackCorrect),
                  ),

                // ------------------ NEXT BUTTON ------------------
                if (showFeedback)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton(
                        onPressed: feedbackCorrect != null ? nextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: feedbackCorrect != null ? mainColor : Colors.grey,
                        ),
                        child: Text(
                          currentQuestion == widget.quiz.questions.length - 1
                              ? "Hantar Kuiz" // Terjemahan
                              : "Soalan Seterusnya", // Terjemahan
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 40), 

                LinearProgressIndicator(
                  value: (currentQuestion + 1) / widget.quiz.questions.length,
                  backgroundColor: Colors.grey[300],
                  color: mainColor,
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ⭐ UI Helper methods (Included to make the class compile)
  Widget buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.quiz.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: mainColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
          child: Text(
            formatTime(remainingSeconds),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
      ],
    );
  }

  List<Widget> buildObjective(QuestionModel question) {
    return List.generate(question.options!.length, (index) {
      final isSelected = answers[currentQuestion] == index;
      
      Color? bg;
      if (showFeedback) {
        if (question.answer == index) bg = Colors.green.withOpacity(0.25);
        else if (isSelected) bg = Colors.red.withOpacity(0.25);
      } else if (isSelected) {
        bg = mainColor.withOpacity(0.15);
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? mainColor : Colors.grey.withOpacity(0.4),
          ),
        ),
        child: RadioListTile<int>(
          title: Text(question.options![index]),
          value: index,
          groupValue: answers[currentQuestion],
          activeColor: mainColor,
          onChanged: isLocked ? null : (_) => handleAnswerTap(index),
        ),
      );
    });
  }

  List<Widget> buildSubjective() {
    return [
      const Text("Jawapan Anda:", style: TextStyle(fontWeight: FontWeight.w600)), // Terjemahan
      const SizedBox(height: 10),
      TextField(
        controller: _textController,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: "Taip jawapan anda...", // Terjemahan
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (v) => answers[currentQuestion] = v,
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _textController.text.isNotEmpty && !isLocked ? mainColor : Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _textController.text.isNotEmpty && !isLocked
              ? handleSubjectiveSubmit
              : null,
          child: const Text(
            "Hantar Jawapan", // Terjemahan
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ];
  }

  Widget buildFeedbackContent(String message, bool? isCorrect) {
    final textColor = isCorrect == true
        ? Colors.green[900]
        : (isCorrect == false ? Colors.orange[900] : mainColor);

    // Split the message into status and reasoning
    String status = "";
    String reasoning = message;

    // Semak awalan Bahasa Melayu
    if (message.startsWith("✅ Betul!")) {
      status = "✅ Betul!";
      reasoning = message.substring("✅ Betul!".length).trim();
    } else if (message.startsWith("❌ Salah.")) {
      status = "❌ Salah.";
      reasoning = message.substring("❌ Salah.".length).trim();
    } else if (message.startsWith("Menilai Alasan AI...")) {
      status = ""; 
      reasoning = message; 
    } else if (message.startsWith("❌ Penjelasan AI Gagal:")) {
      status = ""; 
      reasoning = message; 
    }


    // Cari penunjuk alasan yang mungkin (Penerangan:, Alasan:, atau Reasoning:)
    int reasoningIndex = reasoning.indexOf('Penerangan:');
    if (reasoningIndex == -1) {
      reasoningIndex = reasoning.indexOf('Alasan:');
    }
    if (reasoningIndex == -1) {
      reasoningIndex = reasoning.indexOf('Reasoning:');
    }

    if (reasoningIndex != -1) {
      String intro = reasoning.substring(0, reasoningIndex).trim();
      String reasonPrefix = reasoning.substring(reasoningIndex, reasoningIndex + 11).contains('Reasoning:') ? 'Reasoning:' : 'Penerangan:';

      String actualReason = reasoning.substring(reasoningIndex + reasonPrefix.length).trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Paparkan baris status
          if (status.isNotEmpty)
            Text(
              status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          if (status.isNotEmpty && intro.isNotEmpty) const SizedBox(height: 4),
          // Paparkan teks pengenalan sebelum "Penerangan:"
          if (intro.isNotEmpty)
            Text(
              intro,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
              ),
            ),
          if (intro.isNotEmpty || status.isNotEmpty) const SizedBox(height: 8),
          // Paparkan tajuk Penerangan dan kandungannya
          if (actualReason.isNotEmpty) ...[
            Text(
              "Penerangan:", 
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              actualReason,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
              ),
            ),
          ]
        ],
      );
    } else {
      // Jika penunjuk alasan tidak dijumpai, paparkan mesej secara langsung
      return Text(
        message,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      );
    }
  }
}