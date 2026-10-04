import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Keep the splash screen visible for 3 seconds.
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final firebaseUser = _auth.currentUser;

    // No Firebase login session on this device.
    if (firebaseUser == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    try {
      // Check whether this user is an approved/active family user.
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();

        if (mounted) {
          context.go('/login');
        }
        return;
      }

      final data = userDoc.data();

      if (data == null || data['active'] != true) {
        await _auth.signOut();

        if (mounted) {
          context.go('/login');
        }
        return;
      }

      // Approved user — go directly to dashboard.
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      // If the user/permission check fails, require login again.
      await _auth.signOut();

      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/splash.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.gold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}