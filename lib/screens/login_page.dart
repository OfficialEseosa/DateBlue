import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideoPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _videoController != null) {
      if (!_videoController!.value.isPlaying) {
        _videoController!.play();
      }
    } else if (state == AppLifecycleState.paused && _videoController != null) {
      _videoController!.pause();
    }
  }

  Future<void> _initVideoPlayer() async {
    _videoController = VideoPlayerController.asset('assets/videos/login_bg.mp4');
    
    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(0.0);
      await _videoController!.play();
      
      if (mounted) {
        setState(() {
          _videoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        
        final UserCredential userCredential = 
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
        
        if (userCredential.user != null) {
          debugPrint('Signed in to Firebase: ${userCredential.user!.email}');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VerificationPage(user: userCredential.user!),
              ),
            );
          }
        }
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        if (googleUser == null) return;

        final GoogleSignInClientAuthorization? authorization = 
            await googleUser.authorizationClient.authorizationForScopes(['email']);
        
        if (authorization == null) {
          throw Exception('Failed to get authorization tokens');
        }

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: googleUser.authentication.idToken,
        );

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null) {
          debugPrint('Signed in to Firebase: ${userCredential.user!.email}');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VerificationPage(user: userCredential.user!),
              ),
            );
          }
        }
      }
    } catch (error) {
      debugPrint('Error signing in: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error signing in. Please try again later.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 0: Static poster (first frame) - ALWAYS visible as background
          // This prevents black flash - video just plays on top of it
          SizedBox.expand(
            child: Image.asset(
              'assets/images/login_bg_poster.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Layer 1: Video (plays on top of poster when ready)
          if (_videoInitialized && _videoController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),

          // Overlay to make text/buttons readable
          Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      children: const [
                        TextSpan(
                          text: 'Date',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Blue',
                          style: TextStyle(color: Color(0xFF0039A6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Find your perfect match',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                      ),
                      label: const Text(
                        'Login with Google',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
