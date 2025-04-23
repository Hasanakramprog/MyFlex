// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Current user getter
  User? get currentUser => _auth.currentUser;
  
  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
            final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in with the credential
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Save user info to shared preferences for offline access
      await _saveUserInfo(userCredential.user);
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // Clear saved user info
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_display_name');
      await prefs.remove('user_email');
      await prefs.remove('user_photo_url');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
  
  // Save user info to SharedPreferences
  Future<void> _saveUserInfo(User? user) async {
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_display_name', user.displayName ?? '');
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_photo_url', user.photoURL ?? '');
      await prefs.setString('user_id', user.uid); // Add user ID
    }
  }
  
  // Get user info from SharedPreferences
  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'displayName': prefs.getString('user_display_name') ?? '',
      'email': prefs.getString('user_email') ?? '',
      'photoURL': prefs.getString('user_photo_url') ?? '',
      'userId': prefs.getString('user_id') ?? '', // Add user ID
    };
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

}