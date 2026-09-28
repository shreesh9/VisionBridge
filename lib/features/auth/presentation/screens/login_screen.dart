/// VisionBridge — Login Screen
///
/// Unified login screen with Google Sign-In and Phone Verification (OTP).
/// Keeps the high-end premium styling, animations, and voice accessibility.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/firestore_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final credential = await _authService.signInWithGoogle();
      final user = credential.user;

      if (user == null) throw Exception('Google sign in returned no user.');

      await _handlePostAuthRouting(user);
    } catch (e) {
      _showError('Google Sign-In failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Start Phone verification flow (request OTP)
  Future<void> _handleSendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      _showError('Please enter a valid phone number including country code (e.g. +919876543210)');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.selectionClick();

    try {
      await _authService.verifyPhone(
        phoneNumber: phone,
        onCodeSent: (verId) {
          if (mounted) {
            setState(() {
              _verificationId = verId;
              _otpSent = true;
              _isLoading = false;
            });
            _showSuccess('Verification code sent to $phone');
          }
        },
        onFailed: (e) {
          _showError('Verification failed: ${e.message ?? e.toString()}');
          if (mounted) setState(() => _isLoading = false);
        },
        onAutoVerify: (credential) async {
          // Android auto-retrieval
          try {
            final authCred = await FirebaseAuth.instance.signInWithCredential(credential);
            if (authCred.user != null) {
              await _handlePostAuthRouting(authCred.user!);
            }
          } catch (e) {
            _showError('Auto-verification failed: $e');
          }
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      _showError('Verification error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Complete Phone verification flow (verify OTP)
  Future<void> _handleVerifyOTP() async {
    final code = _otpController.text.trim();
    if (code.isEmpty || code.length < 6) {
      _showError('Please enter the 6-digit verification code.');
      return;
    }

    if (_verificationId == null) {
      _showError('Session expired. Please request a new verification code.');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final credential = await _authService.signInWithOTP(
        verificationId: _verificationId!,
        smsCode: code,
      );
      final user = credential.user;

      if (user == null) throw Exception('Phone sign in returned no user.');

      await _handlePostAuthRouting(user);
    } catch (e) {
      _showError('Incorrect verification code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBypassLogin(UserRole role) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    // Short delay for feel
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Route straight to the requested dashboard
    if (role == UserRole.volunteer) {
      _showSuccess('Developer Mode: Logged in as Volunteer');
      context.go(AppRoutes.vHome);
    } else {
      _showSuccess('Developer Mode: Logged in as Blind User');
      context.go(AppRoutes.buHome);
    }
  }

  /// Handles checking Firestore profile and routing either to home screens or role selection
  Future<void> _handlePostAuthRouting(User user) async {
    if (!mounted) return;

    VBUser? vbUser;
    try {
      vbUser = await _firestoreService.getUser(user.uid).timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
    } catch (_) {
      // If Firestore is unavailable or database not created yet, proceed gracefully
      vbUser = null;
    }

    if (!mounted) return;

    if (vbUser == null) {
      // Brand new user or Firestore offline -> redirect to Role Selection Screen
      context.go(AppRoutes.selectRole);
    } else {
      // Existing user -> route based on their role
      if (vbUser.role == UserRole.volunteer) {
        context.go(AppRoutes.vHome);
      } else {
        context.go(AppRoutes.buHome);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? VBDarkColors.sos
            : VBLightColors.sos,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? VBDarkColors.success
            : VBLightColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final bgColor = isDark ? VBDarkColors.background : VBLightColors.background;
    final textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurface;
    final subtextColor =
        isDark ? VBDarkColors.onSurfaceVariant : VBLightColors.onSurfaceVariant;
    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;
    final surfaceColor = isDark ? VBDarkColors.surface : VBLightColors.surface;
    final outlineColor = isDark ? VBDarkColors.outline : VBLightColors.outline;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: VBSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: VBSpacing.xxxl),

              // Header
              Semantics(
                header: true,
                child: Text(
                  isHindi ? 'विज़नब्रिज में\nस्वागत है' : 'Welcome to\nVisionBridge',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
              ),
              const SizedBox(height: VBSpacing.sm),
              Text(
                isHindi
                    ? 'ऐप उपयोग शुरू करने के लिए Google खाते या सत्यापन कोड से साइन इन करें।'
                    : 'Sign in with your Google account or via verification code to start using the app.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: subtextColor,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: VBSpacing.xxxl),

              // Google Sign-In Option
              if (!_otpSent) ...[
                SizedBox(
                  width: double.infinity,
                  height: VBTouchTarget.primaryAction,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : surfaceColor,
                      foregroundColor: isDark ? Colors.black87 : textColor,
                      elevation: 1,
                      side: BorderSide(
                        color: isDark ? Colors.transparent : outlineColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VBRadius.md),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.g_mobiledata_rounded,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: VBSpacing.md),
                        Text(
                          isHindi ? 'Google से साइन इन करें' : 'Sign In with Google',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: VBSpacing.xl),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: outlineColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: VBSpacing.md),
                      child: Text(
                        isHindi ? 'या सत्यापन कोड से साइन इन करें' : 'or use verification code',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: subtextColor,
                            ),
                      ),
                    ),
                    Expanded(child: Divider(color: outlineColor)),
                  ],
                ),
                const SizedBox(height: VBSpacing.xl),
              ],

              // Phone Sign-In or OTP verification UI
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState:
                    _otpSent ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Column(
                  children: [
                    Semantics(
                      label: 'Phone number input field',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: isHindi ? 'फ़ोन नंबर' : 'Phone Number',
                          hintText: '+1 555-555-5555',
                          prefixIcon: const Icon(Icons.phone_iphone_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded),
                            onPressed: _isLoading ? null : _handleSendOTP,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: outlineColor),
                            borderRadius: BorderRadius.circular(VBRadius.md),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2),
                            borderRadius: BorderRadius.circular(VBRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: VBSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      height: VBTouchTarget.primaryAction,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleSendOTP,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(isHindi ? 'सत्यापन कोड भेजें' : 'Send Verification Code'),
                      ),
                    ),
                  ],
                ),
                secondChild: Column(
                  children: [
                    Semantics(
                      label: 'Verification code input field',
                      child: TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: isHindi ? 'सत्यापन कोड' : 'Verification Code',
                          hintText: isHindi ? '6 अंकों का कोड दर्ज करें' : 'Enter 6-digit code',
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: outlineColor),
                            borderRadius: BorderRadius.circular(VBRadius.md),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2),
                            borderRadius: BorderRadius.circular(VBRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: VBSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _otpSent = false;
                                      _otpController.clear();
                                    });
                                  },
                            child: Text(isHindi ? 'नंबर बदलें' : 'Change Number'),
                          ),
                        ),
                        const SizedBox(width: VBSpacing.md),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleVerifyOTP,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(isHindi ? 'कोड सत्यापित करें' : 'Verify Code'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VBSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
