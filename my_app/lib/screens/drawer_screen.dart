// drawer_screen.dart
import 'package:flutter/material.dart';
import 'package:my_app/auth_service.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final AuthService _authService = AuthService();
  String _displayName = '';
  String _email = '';
  String _photoURL = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final userInfo = await _authService.getUserInfo();
      setState(() {
        _displayName = userInfo['displayName'] ?? '';
        _email = userInfo['email'] ?? '';
        _photoURL = userInfo['photoURL'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user info: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          // User profile header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            accountName: Text(
              _isLoading ? 'Loading...' : _displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(_isLoading ? '' : _email),
            currentAccountPicture: _isLoading
                ? const CircularProgressIndicator(color: Colors.red)
                : CircleAvatar(
                    backgroundColor: Colors.grey,
                    backgroundImage: _photoURL.isNotEmpty
                        ? CachedNetworkImageProvider(_photoURL)
                        : null,
                    child: _photoURL.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
          ),
          
          // Menu items
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: const Text('Watch History', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Navigate to history screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.white),
            title: const Text('My List', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Navigate to favorites screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white),
            title: const Text('Downloads', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Navigate to downloads screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings screen
            },
          ),
          
          const Spacer(),
          
          // Sign out button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}