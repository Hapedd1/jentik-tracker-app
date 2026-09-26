import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Widget halamanSelanjutnya; // 🔥 Menerima titipan dari main.dart

  const SplashScreen({super.key, required this.halamanSelanjutnya});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryGreen = const Color(0xFF1D8B41);
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Mengatur durasi animasi logo muncul (1.5 detik)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Memulai animasi logo
    _animationController.forward();

    // 🔥 Menahan layar selama 3 detik, lalu lompat otomatis ke halaman titipan 🔥
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => widget.halamanSelanjutnya),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // CENTER: LOGO & ANIMASI TEXT
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.water_drop, size: 100, color: primaryGreen),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Jentik Tracker',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Pantau Jentik, Cegah DBD',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM: LOADING INDICATOR MINIMALIS
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryGreen.withOpacity(0.6),
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
