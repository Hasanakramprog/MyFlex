import 'package:flutter/material.dart';

class DownloadsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Downloads'),
      ),
      body: Center(
        child: Text(
          'Your downloaded videos will appear here.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
