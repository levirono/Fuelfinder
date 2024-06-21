// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:ff_main/services/login_page.dart';
import 'package:ff_main/services/auth.dart';

class SignupPage extends StatefulWidget {
    const SignupPage({super.key});

  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _role = 'user';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _passwordsMatch = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.green[100],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green[200]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'Please sign up to get started',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20.0),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  color: Colors.grey[300],
                  elevation: 8.0,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: const Icon(Icons.email, color: Colors.green),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email.';
                              }
                              return null;
                            },
                            onSaved: (newValue) => _email = newValue!,
                          ),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock, color: Colors.green),
                              suffixIcon: IconButton(
                                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                            ),
                            obscureText: !_showPassword,
                            onChanged: (value) {
                              setState(() {
                                _password = value;
                                _passwordsMatch = _confirmPassword == _password;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password.';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters long.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Confirm your password',
                              prefixIcon: const Icon(Icons.lock, color: Colors.green),
                              suffixIcon: IconButton(
                                icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    _showConfirmPassword = !_showConfirmPassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                            ),
                            obscureText: !_showConfirmPassword,
                            onChanged: (value) {
                              setState(() {
                                _confirmPassword = value;
                                _passwordsMatch = _confirmPassword == _password;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password.';
                              }
                              if (!_passwordsMatch) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  value: 'user',
                                  groupValue: _role,
                                  title: const Text('Driver'),
                                  secondary: const Icon(Icons.directions_car, color: Colors.green),
                                  onChanged: (value) {
                                    setState(() {
                                      _role = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  value: 'station',
                                  groupValue: _role,
                                  title: const Text('Station'),
                                  secondary: const Icon(Icons.local_gas_station, color: Colors.green),
                                  onChanged: (value) {
                                    setState(() {
                                      _role = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                            ),
                            child: const Text('Sign Up',
                            style: TextStyle(
                              color:Colors.white,
                            ),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            },
                            child: const Text(
                              'Already have an account? Login',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    final BuildContext contextBeforeAsync = context;
    final result = await _authService.register(_email, _password, _role);

    if (!mounted) return;

    if (result != null) {
      _showRegistrationSuccessDialog(contextBeforeAsync);
    } else {
      ScaffoldMessenger.of(contextBeforeAsync).showSnackBar(
        const SnackBar(
          content: Text('Registration failed!'),
        ),
      );
    }
  }
}

  Future<void> _showRegistrationSuccessDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Account Created Successfully'),
        content: const Text('Your account has been created successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('Proceed to Login'),
          ),
        ],
      );
    },
  );
}
}