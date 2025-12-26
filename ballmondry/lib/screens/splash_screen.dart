import 'package:flutter/material.dart';
import 'dart:async';
import 'auth/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<Alignment> _logoAlignment;
  late Animation<double> _logoScale;
  
  late AnimationController _formController;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;
  
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    
    // Animation untuk logo bergerak dari tengah ke atas
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAlignment = AlignmentTween(
      begin: Alignment.center,
      end: const Alignment(0, -0.554),
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _logoScale = Tween<double>(
      begin: 1.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Animation untuk form login
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeIn,
    ));

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation setelah 2 detik
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _logoController.forward();
        
        // Form muncul dengan delay 300ms setelah logo mulai bergerak
        Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _showForm = true);
            _formController.forward();
          }
        });
        
        // Navigate ke login page setelah animasi selesai
        Timer(const Duration(milliseconds: 1800), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LoginPage(),
                transitionDuration: const Duration(milliseconds: 600),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Stack(
        children: [
          // Logo yang bergerak dari tengah ke atas
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Align(
                alignment: _logoAlignment.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_laundry_service,
                          size: 60,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "BallMonDry",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Form login yang muncul bersamaan
          if (_showForm)
            SlideTransition(
              position: _formSlide,
              child: FadeTransition(
                opacity: _formOpacity,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const SizedBox(height: 147),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: "Username",
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(height: 15),
                              const TextField(
                                enabled: false,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: Icon(Icons.visibility_off),
                                ),
                              ),
                              const SizedBox(height: 25),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text("MASUK"),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 35),
                        const Text(
                          "Belum punya akun? Daftar disini",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
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
