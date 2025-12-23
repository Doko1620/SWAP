import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swap/components/textfield.dart';
import 'package:swap/components/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap/components/toast.dart';

class SignUpPage extends StatefulWidget {
 const SignUpPage({super.key});

 @override
 State<SignUpPage> createState() => _SignUpPageState();
}



class _SignUpPageState extends State<SignUpPage> {

 @override
 void initState() {
   super.initState(); 
   WidgetsBinding.instance.addPostFrameCallback((_) {
     ToastHelper.init(context); 
   });
 }

 final _formKey = GlobalKey<FormState>();
 final _fullNameController = TextEditingController();
 final _usernameController = TextEditingController();
 final _emailController = TextEditingController();
 final _passwordController = TextEditingController();
 final _confirmPasswordController = TextEditingController();


 bool _termsAccepted = false;
 bool _obscurePassword = true;
 bool _showPasswordRequirements = false;

 bool hasUpper = false;
 bool hasLower = false;
 bool hasNumber = false;
 bool hasSymbol = false;
 bool hasLength = false;

 @override
 void dispose() {
   _fullNameController.dispose();
   _usernameController.dispose();
   _emailController.dispose();
   _passwordController.dispose();
   _confirmPasswordController.dispose();
   super.dispose();
 }

 void _checkPassword(String password) {
   setState(() {
     hasUpper = password.contains(RegExp(r'[A-Z]'));
     hasLower = password.contains(RegExp(r'[a-z]'));
     hasNumber = password.contains(RegExp(r'[0-9]'));
     hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
     hasLength = password.length >= 8;
   });
 }

 bool get _isPasswordValid =>
     hasUpper && hasLower && hasNumber && hasSymbol && hasLength;

 bool get _doPasswordsMatch =>
     _passwordController.text == _confirmPasswordController.text;

 bool get _isEmailValid {
   final email = _emailController.text;
   final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
   return emailRegex.hasMatch(email);
 }

 bool get _isFormValid =>
     _fullNameController.text.isNotEmpty &&
     _usernameController.text.isNotEmpty &&
     _emailController.text.isNotEmpty &&
     _isEmailValid &&
     _passwordController.text.isNotEmpty &&
     _confirmPasswordController.text.isNotEmpty &&
     _isPasswordValid &&
     _termsAccepted &&
     _doPasswordsMatch;

 @override
 Widget build(BuildContext context) {
   final Color primaryPurple = const Color.fromARGB(255, 77, 44, 111);
   final Color secondaryPurple = const Color.fromARGB(255, 144, 76, 213);

   return Scaffold(
     backgroundColor: Colors.white70,
     body: Container(
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
           child: Form(
             key: _formKey,
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
                   "Create Account",
                   style: GoogleFonts.cormorantGaramond(
                     fontSize: 38,
                     fontWeight: FontWeight.bold,
                     color: primaryPurple,
                   ),
                 ),
                 const SizedBox(height: 8),
 
                 Text(
                   "Sign up to start your style journey",
                   style: GoogleFonts.poppins(
                     fontSize: 16,
                     color: secondaryPurple,
                   ),
                   textAlign: TextAlign.center,
                 ),
                 const SizedBox(height: 40),
 
                 CustomTextField(
                   label: "Full Name",
                   controller: _fullNameController,
                   primaryColor: primaryPurple,
                   secondaryColor: secondaryPurple,
                   isPassword: false,
                   onChanged: (_) => setState(() {}), 
                 ),
                 const SizedBox(height: 20),
 
                 CustomTextField(
                   label: "User Name",
                   controller: _usernameController,
                   primaryColor: primaryPurple,
                   secondaryColor: secondaryPurple,
                   isPassword: false,
                   onChanged: (_) => setState(() {}), 
                 ),
                 const SizedBox(height: 20),
 
                 TextField(
                   controller: _emailController,
                   onChanged: (_) => setState(() {}), 
                   decoration: InputDecoration(
                     labelText: "Email",
                     labelStyle: GoogleFonts.poppins(color: primaryPurple),
                     errorText: _emailController.text.isNotEmpty && !_isEmailValid
                         ? "Enter a valid email"
                         : null,
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(14),
                     ),
                   ),
                 ),
                 const SizedBox(height: 20),
 
                 TextField(
                   controller: _passwordController,
                   obscureText: _obscurePassword,
                   onTap: () {
                     setState(() {
                       _showPasswordRequirements = true;
                     });
                   },
                   onChanged: _checkPassword,
                   decoration: InputDecoration(
                     labelText: "Password",
                     labelStyle: GoogleFonts.poppins(color: primaryPurple),
                     suffixIcon: IconButton(
                       icon: Icon(
                         _obscurePassword
                             ? Icons.visibility_off
                             : Icons.visibility,
                         color: primaryPurple,
                       ),
                       onPressed: () {
                         setState(() {
                           _obscurePassword = !_obscurePassword;
                         });
                       },
                     ),
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(14),
                     ),
                   ),
                 ),
 
                 if (_showPasswordRequirements) ...[
                   const SizedBox(height: 10),
                   _buildRequirement("At least 8 characters", hasLength),
                   _buildRequirement("1 uppercase letter", hasUpper),
                   _buildRequirement("1 lowercase letter", hasLower),
                   _buildRequirement("1 number", hasNumber),
                   _buildRequirement("1 symbol", hasSymbol),
                 ],
                 const SizedBox(height: 20),
 
                 TextField(
                   controller: _confirmPasswordController,
                   obscureText: true,
                   decoration: InputDecoration(
                     labelText: "Confirm Password",
                     labelStyle: GoogleFonts.poppins(color: primaryPurple),
                     errorText: _confirmPasswordController.text.isNotEmpty &&
                             !_doPasswordsMatch
                         ? "Passwords do not match"
                         : null,
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(14),
                     ),
                   ),
                   onChanged: (_) => setState(() {}), 
                 ),
                 const SizedBox(height: 20),
 
                 Row(
                   children: [
                     Checkbox(
                       value: _termsAccepted,
                       activeColor: secondaryPurple,
                       onChanged: (value) {
                         setState(() {
                           _termsAccepted = value ?? false;
                         });
                       },
                     ),
                     Expanded(
                       child: Text(
                         "I agree to the Terms & Conditions",
                         style: GoogleFonts.poppins(
                           fontSize: 14,
                           color: primaryPurple,
                         ),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 20),
 
                 SizedBox(
                   width: double.infinity,
                   height: 50,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor:
                           _isFormValid ? primaryPurple : Colors.grey,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(14),
                       ),
                     ),
                     onPressed: _isFormValid ? _signup : null,
                     child: Text(
                       "Sign Up",
                       style: GoogleFonts.poppins(
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                         color: Colors.white,
                       ),
                     ),
                   ),
                 ),
                 const SizedBox(height: 25),
 
                 // Already have account? Login
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Text(
                       "Already have an account? ",
                       style: GoogleFonts.poppins(
                         fontSize: 14,
                         color: primaryPurple,
                       ),
                     ),
                     GestureDetector(
                       onTap: () {
                         Navigator.pushReplacementNamed(context, '/login');
                       },
                       child: Text(
                         "Login",
                         style: GoogleFonts.poppins(
                           fontSize: 14,
                           fontWeight: FontWeight.w600,
                           color: secondaryPurple,
                         ),
                       ),
                     ),
                   ],
                 ),
               ],
             ),
           ),
         ),
       ),
     ),
   );
 }

 Widget _buildRequirement(String text, bool fulfilled) {
   return Row(
     children: [
       Icon(
         fulfilled ? Icons.check_circle : Icons.cancel,
         size: 18,
         color: fulfilled ? Colors.green : Colors.red,
       ),
       const SizedBox(width: 8),
       Text(
         text,
         style: GoogleFonts.poppins(
           fontSize: 14,
           color: fulfilled ? Colors.green : Colors.red,
         ),
       ),
     ],
   );
 }

 _signup() async {
   try {
     UserCredential credential = await FirebaseAuth.instance
         .createUserWithEmailAndPassword(
       email: _emailController.text.trim(),
       password: _passwordController.text.trim(),
     );

     if (credential.user != null) {
       await addUserDetails(
         _fullNameController.text,
         _usernameController.text.trim(),
         _emailController.text.trim(),
         _passwordController.text.trim(),
       );

       ToastHelper.showToast(
           message: "User Registered",
           backgroundColor: primaryPurple.withValues(alpha: 0.5),
           icon: Icons.account_circle_rounded,);
       Navigator.pushReplacementNamed(context, '/login');
     }
   } on FirebaseAuthException catch (e) {
     if (e.code == 'email-already-in-use') {
       ToastHelper.showToast(
           message: "Email already registered",
           backgroundColor: Colors.red.withValues(alpha: 0.5),
           icon: Icons.error_outline_sharp,);
     }else{
       ToastHelper.showToast(
           message: "An error occured",
           backgroundColor: Colors.red.withValues(alpha: 0.5),
           icon: Icons.error_outline_sharp,);
     }
     return null;
   }
 }

 Future addUserDetails(String firstName, String userName, String email, String password) async{

   CollectionReference collRef = FirebaseFirestore.instance.collection('users');
   collRef.add({
     'Full Name': firstName,
     'User Name': userName,
     'Email': email,
     'Password': password, 
     'score': 0, 
   });

   log('Added to database');
 }
}