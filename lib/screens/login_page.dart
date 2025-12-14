import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  // Static controller that persists across widget rebuilds
  static Player? _preloadedPlayer;
  static VideoController? _preloadedController;
  static bool _isPreloaded = false;

  // Preload video before navigating to login page
  // Note: Only preloads the Player. VideoController is created later
  // in the widget because it requires the Flutter rendering pipeline.
  static Future<void> preloadVideo() async {
    if (_isPreloaded) return;
    _preloadedPlayer = Player();
    // Don't create VideoController here - it requires the widget tree to be ready
    await _preloadedPlayer!.open(
      Media('asset:///assets/videos/login_bg.mp4'),
      play: false,
    );
    await _preloadedPlayer!.setPlaylistMode(PlaylistMode.loop);
    await _preloadedPlayer!.setVolume(0.0);
    _isPreloaded = true;
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Player? _player;
  VideoController? _videoController;
  bool _videoReady = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    if (LoginPage._isPreloaded && LoginPage._preloadedPlayer != null) {
      // Use the preloaded player
      _player = LoginPage._preloadedPlayer;
      
      // Create the VideoController if it doesn't exist yet
      if (LoginPage._preloadedController == null) {
        LoginPage._preloadedController = VideoController(_player!);
      }
      _videoController = LoginPage._preloadedController;
      
      // Check if already playing (returning from another screen)
      final isPlaying = _player!.state.playing;
      final hasWidth = _player!.state.width != null && _player!.state.width! > 0;
      
      if (isPlaying && hasWidth) {
        // Video is already playing, just mark as ready after a brief delay
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            _videoReady = true;
          });
        }
      } else {
        // Start playing
        _player!.play();
        
        // Wait for video to actually start playing (first frame ready)
        await _player!.stream.playing.firstWhere((playing) => playing);
        
        // Additional wait for the video to have width/height (fully decoded)
        await _player!.stream.width.firstWhere((w) => w != null && w > 0);
        
        // Small delay to ensure frames are rendered before fading poster
        await Future.delayed(const Duration(milliseconds: 150));
        
        if (mounted) {
          setState(() {
            _videoReady = true;
          });
        }
      }
    } else {
      // Fallback to loading if preload didn't happen
      _player = Player();
      _videoController = VideoController(_player!);
      await _player!.open(
        Media('asset:///assets/videos/login_bg.mp4'),
        play: false,
      );
      await _player!.setPlaylistMode(PlaylistMode.loop);
      await _player!.setVolume(0.0);
      
      // Start playing
      _player!.play();
      await _player!.stream.playing.firstWhere((playing) => playing);
      await _player!.stream.width.firstWhere((w) => w != null && w > 0);
      
      // Small delay to ensure frames are rendered before fading poster
      await Future.delayed(const Duration(milliseconds: 150));
      
      if (mounted) {
        setState(() {
          _videoReady = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Don't dispose the preloaded player
    if (_player != null && _player != LoginPage._preloadedPlayer) {
      _player?.dispose();
    }
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      // Check if we're on web or desktop (Windows, macOS, Linux)
      final bool useFirebasePopup = kIsWeb || 
          (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux));
      
      if (useFirebasePopup) {
        // Web and Desktop platforms: Use Firebase Auth popup directly
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Add scopes if needed
        googleProvider.addScope('email');
        
        // Sign in with popup
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
        // Mobile platforms (Android/iOS): Use google_sign_in package v7.x
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        if (googleUser == null) return; // User canceled the sign-in

        // Get authorization client and request tokens
        final GoogleSignInClientAuthorization? authorization = 
            await googleUser.authorizationClient.authorizationForScopes(['email']);
        
        if (authorization == null) {
          throw Exception('Failed to get authorization tokens');
        }

        // Create a new credential using the access token
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: googleUser.authentication.idToken,
        );

        // Sign in to Firebase with the credential
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
          // Layer 1: Video (always present, renders behind poster)
          if (_videoController != null)
            SizedBox.expand(
              child: Video(
                controller: _videoController!,
                fit: BoxFit.cover,
              ),
            ),
          
          // Layer 2: Poster image (fades OUT when video is ready)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _videoReady ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: SizedBox.expand(
                child: Image.asset(
                  'assets/images/login_bg_poster.jpg',
                  fit: BoxFit.cover,
                ),
              ),
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
