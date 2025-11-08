import 'package:cscore/DashboardModule/Screens/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/DashboardModule/Screens/teacher_dashboard.dart';
import 'package:cscore/DashboardModule/Screens/student_dashboard.dart';
import 'registration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ NEW LOGIN FUNCTION (FULL VERSION)
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1) Firebase Auth Sign In
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2) Get user document
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        setState(() => _isLoading = false);

        _showError("No user profile found. Contact admin.");
        return;
      }

      final data = doc.data()!;
      final status = (data["status"] ?? "Pending") as String;
      final role = (data["role"] ?? "Student") as String;

      // 3) Status Check
      if (status == "Pending") {
        await _auth.signOut();
        setState(() => _isLoading = false);
        _showError("Your account is still waiting for admin approval.");
        return;
      }

      if (status == "Suspended") {
        await _auth.signOut();
        setState(() => _isLoading = false);
        _showError("Your account has been suspended.");
        return;
      }

      // ✅ 4) ROUTE BY ROLE
      Widget nextPage;
      if (role.toLowerCase() == "student") {
        nextPage = const StudentDashboard();
      } else if (role.toLowerCase() == "teacher") {
        nextPage = const TeacherDashboard();
      } else if (role.toLowerCase() == "admin") {
        nextPage = const AdminDashboard(); // Admin dashboard
      } else {
        nextPage = const RegisterPage();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Welcome $role!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      if (e.code == 'user-not-found') {
        _showError("No user found with that email.");
      } else if (e.code == 'wrong-password') {
        _showError("Incorrect password.");
      } else {
        _showError("Login failed: ${e.message}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Unexpected error: $e");
    }
  }

  // ✅ Error Snackbar Function
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 10),
              const Text(
                'CScore+',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 30),

              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        } else if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Login button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
              const SizedBox(height: 20),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'Register here',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//victus