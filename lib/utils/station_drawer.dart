import 'package:ff_main/ui/about.dart';
import 'package:ff_main/ui/station/station_profile.dart';
import 'package:flutter/material.dart';

class StationDrawer extends StatelessWidget {
  const StationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[100],
              ),
              child: const Text(
                'Application',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24.0,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StationProfile()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const About()),
                );
              },
            ),
          ],
        ),
      );
  }
}