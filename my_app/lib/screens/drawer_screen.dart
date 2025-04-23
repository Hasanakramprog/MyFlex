import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  void _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.movie, size: 48, color: Colors.white),
                SizedBox(height: 10),
                Text('MYFLIX', style: TextStyle(color: Colors.white, fontSize: 24)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Colors.white),
            title: Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.info, color: Colors.white),
            title: Text('About', style: TextStyle(color: Colors.white)),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'MYFLIX',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.movie),
                children: [
                  Text('A personalized video streaming app built with Flutter.')
                ],
              );
            },
          ),
          Divider(color: Colors.white54),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Follow Us', style: TextStyle(color: Colors.white70)),
          ),
          ListTile(
            leading: Icon(Icons.link, color: Colors.white),
            title: Text('Instagram', style: TextStyle(color: Colors.white)),
            onTap: () => _launchURL('https://instagram.com/yourprofile'),
          ),
          ListTile(
            leading: Icon(Icons.link, color: Colors.white),
            title: Text('YouTube', style: TextStyle(color: Colors.white)),
            onTap: () => _launchURL('https://youtube.com/yourchannel'),
          ),
        ],
      ),
    );
  }
}
