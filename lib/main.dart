import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swap/components/storage_service.dart';
import 'package:swap/firebase_options.dart';
import 'package:swap/pages/home_page.dart';
import 'package:swap/pages/intro_page.dart';
import 'package:swap/pages/login_page.dart';
import 'package:swap/pages/outfitsug_page.dart';
import 'package:swap/pages/signup_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => StorageService(email: ''),
      child: const MyApp(),)
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SWAP',
      initialRoute: '/', 
      routes: {
        '/': (context) => const IntroPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/outfitsug': (context) => OutfitSuggestionPage(username: '', city: '', temperature: 0,),
      },
    );
  }
}
