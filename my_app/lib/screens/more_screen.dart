import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('More'),
      ),
      body: Center(
        child: Text(
          'More options go here.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
