import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swap/components/auth_service.dart';
import 'package:swap/components/textfield.dart';
import 'package:swap/components/toast.dart';
import 'package:swap/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  @override
  void initState() {
    super.initState(); 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastHelper.init(context); 
    });
  }

  final _auth = AuthService();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = const Color.fromARGB(255, 77, 44, 111);
    final Color secondaryPurple = const Color.fromARGB(255, 144, 76, 213);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3FF), Color(0xFFE5DAF5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/SWAP_logo_nobg.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
        
                Text(
                  "Welcome Back",
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(height: 8),
        
                Text(
                  "Sign in to continue your style journey",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: secondaryPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
        
                CustomTextField(
                  label: "Email",
                  controller: _email,
                  primaryColor: primaryPurple,
                  secondaryColor: secondaryPurple,
                  isPassword: false, 
                ),
                const SizedBox(height: 20),
        
                CustomTextField(
                  label: "Password",
                  controller: _password,
                  primaryColor: primaryPurple,
                  secondaryColor: secondaryPurple,
                  isPassword: true,
                ),
                const SizedBox(height: 12),
        
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.poppins(
                        color: secondaryPurple,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
        
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _login,
                    child: Text(
                      "Sign In",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
        
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(fontSize: 14, color: primaryPurple),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const SignUpPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: secondaryPurple,
                        ),
                      ),
                    )
        
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _login() async {
    try {
      
      final user = await _auth.loginUserWithEmailAndPassword(
        _email.text,
        _password.text,
      );

      if (user != null) {
        log("User logged in");
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {

      String message;

      if (e.code == 'invalid-credential' || e.code == 'invalid-email') {

        message = 'Invalid email or password';
        
      } else {
        message = 'An error occured';
      }

      ToastHelper.showToast(
              message: message,
              backgroundColor: Colors.red.withValues(alpha: 0.5),
              icon: Icons.error_outline_sharp,);

    } catch (e) {
      return null;
    }
  }
}
