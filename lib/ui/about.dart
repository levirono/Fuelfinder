import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Fuel Finder'),
        backgroundColor: Colors.green[100],
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Fuel Finder',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Fuel Finder is a product created by Genixl, a company dedicated to providing innovative solutions in the field of mobility and energy.',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Our Mission',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 10.0),
            const Text(
              'To enhance your driving experience by ensuring convenient access to reliable fuel stations across the region.',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              children: [
                const Icon(Icons.email, color: Colors.green),
                const SizedBox(width: 10.0),
                TextButton(
                  onPressed: () {
                    launch('mailto:support@fuelfinder@gmail.com');
                  },
                  child: const Text(
                    'support@fuelfinder@gmail.com',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            TextButton(
              onPressed: () {
                // Open Genixl's website in a browser
                launch('https://genixl.vercel.app');
              },
              child: const Text(
                'Visit Genixl',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
