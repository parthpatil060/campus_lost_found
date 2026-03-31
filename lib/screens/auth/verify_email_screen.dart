import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _isChecking = false;
  bool _resendCooldown = false;
  int _cooldownSeconds = 30;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Auto check every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerified();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (verified) {
      _timer?.cancel();
      final role = auth.currentUser?.role ?? 'user';
      switch (role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case 'verifier':
          Navigator.pushReplacementNamed(context, '/verifier');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/user');
      }
    }
  }

  Future<void> _resendEmail() async {
    final auth = context.read<AuthProvider>();
    await auth.resendVerificationEmail();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Verification email sent!'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));

    setState(() => _resendCooldown = true);
    _cooldownSeconds = 30;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _resendCooldown = false;
          t.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: const Center(
                  child: Text('📧', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text(
                      '1. Check your Outlook inbox at @gst.sies.edu.in',
                      style: TextStyle(fontSize: 13, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '2. Click the verification link in the email',
                      style: TextStyle(fontSize: 13, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '3. Return to the app — you\'ll be logged in automatically',
                      style: TextStyle(fontSize: 13, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: _isChecking ? 'Checking...' : 'I\'ve Verified — Continue',
                onPressed: _checkVerification,
                isLoading: _isChecking,
              ),
              const SizedBox(height: 14),
              AppButton(
                text: _resendCooldown
                    ? 'Resend in $_cooldownSeconds s'
                    : 'Resend Verification Email',
                onPressed: _resendCooldown ? null : _resendEmail,
                isOutlined: true,
              ),
              const SizedBox(height: 20),
              Text(
                'Checking automatically every 5 seconds...',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
