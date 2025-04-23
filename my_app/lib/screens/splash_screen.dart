import 'package:flutter/material.dart';
import 'package:my_app/auth_service.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Check authentication and navigate accordingly after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }
  
  Future<void> _checkAuthAndNavigate() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // User is logged in, navigate to home screen
        _navigateToHome();
      } else {
        // User is not logged in, navigate to login screen
        _navigateToLogin();
      }
    } catch (e) {
      print('Error checking authentication: $e');
      // Default to login screen on error
      _navigateToLogin();
    }
  }
  
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }
  
  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animation
            AnimatedTextKit(
              animatedTexts: [
                ColorizeAnimatedText(
                  'MYFLIX',
                  textStyle: const TextStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Monospace',
                  ),
                  colors: const [
                    Colors.red,
                    Colors.white,
                    Colors.redAccent,
                    Colors.black,
                  ],
                  speed: const Duration(milliseconds: 500),
                ),
              ],
              isRepeatingAnimation: true,
            ),
            
            const SizedBox(height: 40),
            
            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}