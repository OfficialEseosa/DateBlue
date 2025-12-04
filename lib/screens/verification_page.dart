import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/verification_service.dart';
import '../widgets/pin_input.dart';
import '../widgets/gsu_email_input.dart';
import '../widgets/top_notification.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';
import 'home_page.dart';

class VerificationPage extends StatefulWidget {
  final User user;

  const VerificationPage({super.key, required this.user});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage>
    with TickerProviderStateMixin {
  final _verificationService = VerificationService();
  final _emailController = TextEditingController();
  final _pinControllers = List.generate(4, (_) => TextEditingController());
  final _pinFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  bool _isCheckingVerification = true;
  bool _emailSent = false;
  bool _showPinInput = false;
  bool _showDateBlue = false;
  bool _animationStarted = false;

  // Animation controllers
  late final AnimationController _welcomeController;
  late final AnimationController _welcomeFadeOutController;
  late final AnimationController _dateBlueController;
  late final AnimationController _slideUpController;
  late final AnimationController _formController;
  late final AnimationController _formSlideUpController;
  late final AnimationController _pinFadeController;

  // Animations
  late final Animation<double> _welcomeOpacity;
  late final Animation<double> _welcomeFadeOutOpacity;
  late final Animation<double> _dateBlueOpacity;
  late final Animation<double> _slideUpAnimation;
  late final Animation<double> _formOpacity;
  late final Animation<double> _formSlideUpAnimation;
  late final Animation<double> _pinFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkIfAlreadyVerified();
  }

  void _initAnimations() {
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _welcomeOpacity = _createFadeIn(_welcomeController);

    _welcomeFadeOutController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _welcomeFadeOutOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _welcomeFadeOutController, curve: Curves.easeOut),
    );

    _dateBlueController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _dateBlueOpacity = _createFadeIn(_dateBlueController);

    _slideUpController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideUpAnimation = _createSlide(_slideUpController);

    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _formOpacity = _createFadeIn(_formController);

    _formSlideUpController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _formSlideUpAnimation = _createSlide(_formSlideUpController);

    _pinFadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pinFadeAnimation = _createFadeIn(_pinFadeController);
  }

  Animation<double> _createFadeIn(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );
  }

  Animation<double> _createSlide(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimationSequence() {
    if (_animationStarted) return;
    _animationStarted = true;

    _welcomeController.forward();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _showDateBlue = true);
        _dateBlueController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _welcomeFadeOutController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _slideUpController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) _formController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var n in _pinFocusNodes) {
      n.dispose();
    }
    _welcomeController.dispose();
    _welcomeFadeOutController.dispose();
    _dateBlueController.dispose();
    _slideUpController.dispose();
    _formController.dispose();
    _formSlideUpController.dispose();
    _pinFadeController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAlreadyVerified() async {
    try {
      final isVerified = await _verificationService.isUserVerified(widget.user.uid);
      if (isVerified && mounted) {
        _navigateToHome();
        return;
      }
    } catch (e) {
      debugPrint('Error checking verification: $e');
    }

    if (mounted) {
      setState(() => _isCheckingVerification = false);
      Future.delayed(const Duration(milliseconds: 100), _startAnimationSequence);
    }
  }

  Future<void> _sendVerificationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showNotification('Please enter your GSU email', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gsuEmail = '$email@student.gsu.edu';
      
      // Check if this GSU email is already used by another verified user
      final isTaken = await _verificationService.isGsuEmailTaken(
        gsuEmail,
        widget.user.uid,
      );
      
      if (isTaken) {
        if (mounted) {
          _showNotification('This GSU email is already verified with another account.', isError: true);
          setState(() => _isLoading = false);
        }
        return;
      }
      
      await _verificationService.sendVerificationEmail(
        user: widget.user,
        campusId: email,
      );

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
        _showPinInputAfterDelay();
      }
    } catch (e) {
      debugPrint('Error sending verification: $e');
      if (mounted) {
        _showNotification('Error sending verification. Please try again.', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPinInputAfterDelay() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _formSlideUpController.forward();
        setState(() => _showPinInput = true);

        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _pinFadeController.forward();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _pinFocusNodes[0].requestFocus();
            });
          }
        });
      }
    });
  }

  void _onPinChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      _pinFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }

    if (_pinControllers.every((c) => c.text.length == 1)) {
      final pin = _pinControllers.map((c) => c.text).join();
      _verifyPin(pin);
    }
  }

  Future<void> _verifyPin(String pin) async {
    setState(() => _isLoading = true);

    try {
      await _verificationService.verifyPin(uid: widget.user.uid, pin: pin);
      if (mounted) _navigateToHome();
    } catch (e) {
      debugPrint('Error verifying pin: $e');
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        _showNotification(msg, isError: true);
        setState(() => _isLoading = false);
        _clearPinBoxes();
      }
    }
  }

  Future<void> _resendVerificationCode() async {
    setState(() => _isLoading = true);

    try {
      await _verificationService.resendVerificationCode(
        uid: widget.user.uid,
        campusId: _emailController.text.trim(),
      );
      _clearPinBoxes();
      if (mounted) {
        setState(() => _isLoading = false);
        _showNotification('New verification code sent!');
      }
    } catch (e) {
      debugPrint('Error resending code: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showNotification('Error sending code. Please try again.', isError: true);
      }
    }
  }

  void _enableEmailEdit() {
    setState(() {
      _emailSent = false;
      _showPinInput = false;
    });
    _formSlideUpController.reset();
    _pinFadeController.reset();
    _clearPinBoxes();
  }

  void _clearPinBoxes() {
    for (var c in _pinControllers) {
      c.clear();
    }
    _pinFocusNodes[0].requestFocus();
  }

  Future<void> _logout() async {
    await _verificationService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
    );
  }

  void _showNotification(String message, {bool isError = false}) {
    showTopNotification(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingVerification) {
      return const Scaffold(
        backgroundColor: AppColors.lightBlue,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Stack(
      children: [
        // Black background to prevent white flash during keyboard animation
        Container(color: Colors.black),
        // Main scaffold that resizes with keyboard (background + form move)
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              _buildBackground(),
              _buildAnimatedContent(),
            ],
          ),
        ),
        // Logout button - IGNORES keyboard, stays at absolute screen bottom
        if (!_showPinInput)
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: IgnorePointer(
              ignoring: false,
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: FadeTransition(
                  opacity: _formOpacity,
                  child: Center(child: _buildLogoutButton()),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/verification_bg.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.4)),
        ),
      ],
    );
  }

  Widget _buildAnimatedContent() {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _slideUpAnimation,
        _welcomeOpacity,
        _welcomeFadeOutOpacity,
        _dateBlueOpacity,
        _formOpacity,
        _formSlideUpAnimation,
        _pinFadeAnimation,
      ]),
      builder: (context, child) {
        final topPosition = screenHeight * (0.35 - (_slideUpAnimation.value * 0.27));

        return Stack(
          children: [
            _buildWelcomeText(topPosition),
            _buildForm(screenHeight),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeText(double topPosition) {
    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Opacity(
            opacity: _welcomeOpacity.value * _welcomeFadeOutOpacity.value,
            child: Text(
              'Welcome to',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 8 * _welcomeFadeOutOpacity.value),
          if (_showDateBlue)
            FadeTransition(
              opacity: _dateBlueOpacity,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 56,
                      ),
                  children: const [
                    TextSpan(text: 'Date', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'Blue', style: TextStyle(color: AppColors.gsuBlue)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(double screenHeight) {
    return Positioned(
      top: screenHeight * (0.25 - (_formSlideUpAnimation.value * 0.08)),
      left: 0,
      right: 0,
      bottom: 0,
      child: FadeTransition(
        opacity: _formOpacity,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFF97CAEB), Colors.white],
                  ).createShader(bounds),
                  child: Text(
                    '💙 GSU students only 💙',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                GsuEmailInput(
                  controller: _emailController,
                  enabled: !_emailSent,
                  showEditButton: _emailSent,
                  onEditPressed: _enableEmailEdit,
                  onSubmitted: _sendVerificationEmail,
                ),
                const SizedBox(height: 12),
                Text(
                  'This is for verification purposes only.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (!_showPinInput) _buildSendButton(),
                if (_showPinInput) _buildPinSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || _emailSent) ? null : _sendVerificationEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: _emailSent ? Colors.grey.shade400 : AppColors.gsuBlue,
          disabledBackgroundColor: _emailSent ? Colors.grey.shade400 : null,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                _emailSent ? 'Verification Email Sent!' : 'Send Verification Email',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildPinSection() {
    return FadeTransition(
      opacity: _pinFadeAnimation,
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            'Enter the 4-digit code sent to your email',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PinInput(
            controllers: _pinControllers,
            focusNodes: _pinFocusNodes,
            onChanged: _onPinChanged,
          ),
          const SizedBox(height: 24),
          if (_isLoading) const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : _resendVerificationCode,
            child: const Text(
              'Resend Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: 120,
      height: 40,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
