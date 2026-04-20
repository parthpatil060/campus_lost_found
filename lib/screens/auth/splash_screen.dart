import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.status == AuthStatus.initial) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    if (authProvider.status == AuthStatus.authenticated &&
        authProvider.currentUser != null) {
      _navigateByRole(authProvider.currentUser!.role);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image (SIES splash) ──────────────────────────
          Image.asset(
            'assets/images/splashscreens.png',
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
          ),

          // ── Dark overlay so text stays readable ──────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),

          // ── Animated content ─────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: SafeArea(
                child: Column(
                  children: [
                    // Push content to vertical center (above the hands)
                    SizedBox(height: size.height * 0.28),

                    // Logo box
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🔍',
                          style: TextStyle(fontSize: 50),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App title
                    const Text(
                      'CampusRetrieve',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // College name — matches SIES brown accent
                    Text(
                      'SIES Graduate School of Technology',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFD4956A), // SIES brand brown
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Loading indicator near bottom (above the hands area)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),

                    SizedBox(height: size.height * 0.32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}