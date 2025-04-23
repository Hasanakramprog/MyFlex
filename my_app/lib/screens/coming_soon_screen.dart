import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Coming Soon'),
      ),
      body: Center(
        child: Text(
          'Coming Soon content goes here!',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
