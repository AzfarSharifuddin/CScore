import 'package:cscore/ai_chatbox.dart';
import 'package:cscore/dashboard.dart';
import 'package:cscore/forum.dart';
import 'package:cscore/learning.dart';
import 'package:cscore/quiz.dart';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  initialRoute: '/',
  routes: {
    '/':(context) => Dashboard(),
    '/learning':(context) => Learning(),
    '/quiz':(context) => Quiz(),
    '/ai':(context) => AiChatBot(), 


  },
));



