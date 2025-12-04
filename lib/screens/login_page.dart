import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audio_session/audio_session.dart';
import 'verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.ambient,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.movie,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    ));

    _controller = VideoPlayerController.asset('assets/videos/login_bg.mp4');
    await _controller!.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _controller!.setLooping(true);
      _controller!.setVolume(0.0);
      _controller!.play();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return; // User canceled the sign-in

      // 2. Obtain the auth details (ID Token)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Obtain the authz details (Access Token)
      final GoogleSignInClientAuthorization googleAuthz =
          await googleUser.authorizationClient.authorizeScopes(['email']);

      // 4. Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuthz.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase with the credential
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
          // Background Video
          if (_isInitialized && _controller != null)
            Transform.scale(
              scale: 1.1,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            )
          else
            Container(
              color: Theme.of(context).colorScheme.primary,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Overlay to make text/buttons readable
          Container(
            color: Colors.black.withOpacity(0.3),
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
