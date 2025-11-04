/*import 'package:cscore/dashboard.dart';
import 'package:cscore/forum.dart';
import 'package:cscore/learning.dart';
import 'package:cscore/quiz.dart';
import 'package:cscore/user_profile.dart';*/
import 'package:flutter/material.dart';

class AiChatBot extends StatefulWidget {
  const AiChatBot({super.key});

  @override
  State<AiChatBot> createState() => _AiChatBotState();
}

class _AiChatBotState extends State<AiChatBot> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI ChatBox'),),
    );
  }
}
