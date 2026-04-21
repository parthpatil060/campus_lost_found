import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  // Signup controllers
  final _signupNameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _signupConfirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    _signupConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _loginEmailCtrl.text,
      password: _loginPasswordCtrl.text,
    );
    if (!mounted) return;
    if (success && auth.currentUser != null) {
      _navigateByRole(auth.currentUser!.role);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage!),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ));
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      name: _signupNameCtrl.text.trim(),
      email: _signupEmailCtrl.text.trim(),
      password: _signupPasswordCtrl.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushNamed(
        context,
        '/verify-email',
        arguments: _signupEmailCtrl.text.trim(),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage!),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ));
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        Navigator.pushReplacementNamed(context, '/admin');
        break;
      case AppConstants.roleVerifier:
        Navigator.pushReplacementNamed(context, '/verifier');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/user');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final isCompact = size.width < 380 || size.height < 760;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: size.height,
            width: size.width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8EAFF),
                  Color(0xFFF8F9FE),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),
          // Top Abstract Shape
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 24,
                0,
                isCompact ? 16 : 24,
                24 + viewInsets,
              ),
              child: Column(
                children: [
                  SizedBox(height: isCompact ? 24 : 40),
                  // Logo & Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: const Text('🔍', style: TextStyle(fontSize: 24)),
                      ),
                      SizedBox(width: isCompact ? 10 : 14),
                      Flexible(
                        child: Text(
                          'CampusRetrieve',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 22 : 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 28 : 48),
                  
                  // Form Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: AppTheme.glassDecoration(opacity: 0.6, radius: BorderRadius.circular(32)),
                        child: Column(
                          children: [
                            // Tab Bar
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F4FF),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                labelColor: AppTheme.primary,
                                unselectedLabelColor: AppTheme.textSecondary,
                                dividerColor: Colors.transparent,
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                tabs: const [
                                  Tab(text: 'LOGIN'),
                                  Tab(text: 'SIGNUP'),
                                ],
                              ),
                            ),

                            AnimatedBuilder(
                              animation: _tabController,
                              builder: (context, _) => AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: _tabController.index == 0
                                    ? _buildLoginForm(auth, isCompact)
                                    : _buildSignupForm(auth, isCompact),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 24 : 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(AuthProvider auth, bool isCompact) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to continue tracking your items.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            SizedBox(height: isCompact ? 24 : 32),
            AppTextField(
              hint: 'College Email',
              controller: _loginEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_rounded,
              validator: (v) => (v == null || v.isEmpty) ? 'Email is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              hint: 'Password',
              controller: _loginPasswordCtrl,
              isPassword: true,
              prefixIcon: Icons.lock_person_outlined,
              validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
            SizedBox(height: isCompact ? 24 : 40),
            AppButton(
              text: 'Sign In',
              onPressed: _handleLogin,
              isLoading: auth.isLoading,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm(AuthProvider auth, bool isCompact) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join Us',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create an account to start reporting.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            SizedBox(height: isCompact ? 20 : 24),
            AppTextField(
              hint: 'Full Name',
              controller: _signupNameCtrl,
              prefixIcon: Icons.person_add_disabled_outlined,
              validator: (v) => (v == null || v.length < 2) ? 'Enter valid name' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              hint: 'abc24@gst.sies.edu.in',
              controller: _signupEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_rounded,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email required';
                if (!v.trim().toLowerCase().endsWith('@gst.sies.edu.in')) return 'College email only';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              hint: 'Secure Password',
              controller: _signupPasswordCtrl,
              isPassword: true,
              prefixIcon: Icons.lock_open_rounded,
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              hint: 'Confirm Password',
              controller: _signupConfirmCtrl,
              isPassword: true,
              prefixIcon: Icons.verified_user_outlined,
              validator: (v) => (v != _signupPasswordCtrl.text) ? 'Mismatch' : null,
            ),
            SizedBox(height: isCompact ? 24 : 36),
            AppButton(
              text: 'Create Account',
              onPressed: _handleSignup,
              isLoading: auth.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
