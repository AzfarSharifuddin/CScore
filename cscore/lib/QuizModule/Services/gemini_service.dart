// lib/QuizModule/Services/gemini_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// GeminiService: A Singleton class using the REST API for subjective quiz evaluation.
class GeminiService {
  // 1. Singleton setup
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() {
    return _instance;
  }
  
  // FIX 1: Initialize Dio with explicit timeouts for stability 
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15), 
    receiveTimeout: const Duration(seconds: 15), 
  ));

  GeminiService._internal();

  // --- Service State ---
  String? _apiKey;
  bool _isInitialized = false; 
  bool get isInitialized => _isInitialized;

  static const String _remoteConfigKey = 'CScore_Ai'; 
  
  static const String _apiEndpoint = 
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";


  /// 🚀 Initializes the service by fetching the API key securely.
  Future<void> init() async {
    if (_isInitialized) return; 

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate(); 
      _apiKey = remoteConfig.getString(_remoteConfigKey);

      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception("Gemini API Key '$_remoteConfigKey' not found in Remote Config.");
      }
      
      _isInitialized = true;
      print("✅ GeminiService (Direct HTTP/Dio) initialized successfully.");
      
    } catch (e) {
      _isInitialized = false; 
      _apiKey = null;
      print("❌ Failed to initialize GeminiService: $e");
    }
  }

  /// 🧠 Evaluates a subjective answer or generates an MCQ explanation using the Gemini REST API.
  Future<Map<String, dynamic>> evaluateSubjective({
    required String question,
    required String studentAnswer,
    required String expectedAnswer,
  }) async {
    if (!_isInitialized || _apiKey == null) {
        return {
            "correct": false,
            "message": "❌ Penggred AI tidak bersedia. Permulaan perkhidmatan gagal.",
        };
    }
    
    // Use jsonEncode() on dynamic strings to prevent JSON payload corruption.
    final safeQuestion = jsonEncode(question);
    final safeExpectedAnswer = jsonEncode(expectedAnswer);
    final safeStudentAnswer = jsonEncode(studentAnswer);
      
    // ⭐ PROMPT BAHASA MELAYU: Semua output mesti dalam Bahasa Melayu.
    final prompt = '''
      Anda adalah seorang pakar penggred kuiz dan tutor yang berkhidmat dalam Bahasa Melayu. Tugas anda ditentukan oleh medan 'Expected Answer/Rubric'. Semua output, termasuk kandungan 'message' dan sebarang gred, MESTI dalam Bahasa Melayu.
      
      Your response MUST be a single, raw JSON object. Do not include any text, markdown, or commentary outside of the JSON object.
      
      The JSON object must have two required keys: 
      1. 'correct' (boolean: true if the student answer is conceptually acceptable, false otherwise)
      2. 'message' (string: A detailed, professional text that fulfills the task defined in the 'Expected Answer/Rubric' section. The message should primarily be an educational explanation if the task is to generate a reason, or a grade/explanation if the task is to compare answers. If grading is requested, it MUST start with "✅ Betul" or "❌ Salah".)

      ---
      Question: $safeQuestion
      Student Answer: $safeStudentAnswer
      Expected Answer/Rubric: $safeExpectedAnswer
      ---
    ''';
    
    // 1. Construct the API payload
    final payload = {
      "contents": [{"parts": [{"text": prompt}]}],
    };
    
    try {
      // 2. Send the POST request using Dio
      final response = await _dio.post(
        "$_apiEndpoint?key=$_apiKey",
        data: payload,
      );

      if (response.statusCode != 200) {
        String apiErrorDetail = response.data.toString(); 
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: "API returned status ${response.statusCode}: $apiErrorDetail",
        );
      }
      
      // 3. Process the response body
      final responseData = response.data;
      String? textResponse = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      
      if (textResponse == null || textResponse.isEmpty) {
         throw Exception("Received null or empty text from the Gemini model.");
      }
      
      // FIX 3: Robustly clean the response by removing surrounding Markdown fences
      String cleanedResponse = textResponse.trim();
      
      final regex = RegExp(r'^\s*```(json)?\s*|\s*```\s*$', multiLine: true);
      cleanedResponse = cleanedResponse.replaceAll(regex, '').trim();

      // 4. Decode the cleaned JSON output
      final jsonResponse = jsonDecode(cleanedResponse);
      
      return {
        "correct": jsonResponse["correct"] ?? false,
        "message": jsonResponse["message"] ?? "Penilaian AI selesai.",
      };
      
    } on DioException catch (e) {
      String errorMessage = "Ralat Rangkaian: ${e.response?.statusCode ?? 'Tamat Masa/Sambungan'}";
      
      print("Gemini Evaluation Dio Error: $errorMessage");
      
      return {
        "correct": false,
        "message": "❌ Penilaian AI Gagal: $errorMessage",
      };
    } catch (e) {
      print("Gemini Evaluation Runtime Error: $e");
      return {
        "correct": false,
        "message": "❌ Penilaian AI Gagal: Tidak dapat memproses respons. ($e)",
      };
    }
  }
}