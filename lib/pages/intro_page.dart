import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:swap/pages/login_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
void initState() {
  super.initState();

  Future.delayed(const Duration(seconds: 5), () {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginPage(), 
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3FF), Color(0xFFE5DAF5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/SWAP_logo_nobg.png',
                  height: 160,
                ),
                const SizedBox(height: 20),
                Text(
                  "SWAP",
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: const Color(0xFF4D2C6F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "The Intelligence Behind Your Lifestyle",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: const Color(0xFF904CD5),
                  ),
                ),
                const SizedBox(height: 40),
                const SpinKitSpinningLines(
                  color: Color(0xFF4D2C6F),
                  size: 60.0,
                  duration: Duration(milliseconds: 2000),
                ),
                const SizedBox(height: 16),
                Text(
                  "Loading your style...",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
