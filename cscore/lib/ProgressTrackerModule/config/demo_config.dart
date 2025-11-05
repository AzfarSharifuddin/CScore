import 'package:firebase_auth/firebase_auth.dart';

const bool USE_FIREBASE_MOCK_USER = true;
const String DEMO_USER_ID = 'student123';


String getCurrentUserId() {
  if (USE_FIREBASE_MOCK_USER) return DEMO_USER_ID;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('No logged-in user');
  return user.uid;
}
