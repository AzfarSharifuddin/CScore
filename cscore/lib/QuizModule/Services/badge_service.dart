import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BadgeService {
  static Future<void> createBadgeForQuiz(
      String quizId, String quizTitle, File? badgeFile) async {
    
    // Default fallback badge
    String iconUrl =
        "https://firebasestorage.googleapis.com/v0/b/YOUR_DEFAULT_BADGE.png";

    // Upload badge if teacher selected one
    if (badgeFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("badge/$quizId.png");  // CORRECT FOLDER

      await storageRef.putFile(badgeFile);
      iconUrl = await storageRef.getDownloadURL();
    }

    // Write award metadata into Firestore
    await FirebaseFirestore.instance.collection("award").doc(quizId).set({
      "title": "$quizTitle Badge",
      "description": "Awarded for completing $quizTitle",
      "criteria": "Score ≥ 50%",
      "quizId": quizId,
      "iconUrl": iconUrl,
    });
  }
}
