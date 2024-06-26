import 'package:flutter/material.dart';
import 'package:ff_main/services/auth.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logout Confirmation'),
      backgroundColor: Colors.green[100],
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.red[400]),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _authService.logout();
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/login', 
              (Route<dynamic> route) => false,
            );
          },
          child: const Text(
            'Logout',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return LogoutConfirmationDialog();
      },
    );
  }
}
