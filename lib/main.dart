import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:media_kit/media_kit.dart';
import 'screens/login_page.dart';
import 'screens/verification_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await GoogleSignIn.instance.initialize();
  }

  try {
    await LoginPage.preloadVideo();
  } catch (e, stack) {
    debugPrint('Failed to preload video: $e');
    debugPrint(stack.toString());
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DateBlue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0039A6),
          primary: const Color(0xFF0039A6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0039A6),
          foregroundColor: Colors.white,
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return VerificationPage(user: snapshot.data!);
          }
          return const LoginPage();
        },
      ),
    );
  }
}
