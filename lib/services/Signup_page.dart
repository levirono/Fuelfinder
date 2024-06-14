import 'package:flutter/material.dart';
import 'package:ff_main/services/login_page.dart';
import 'package:ff_main/services/auth.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _role = 'user';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _passwordsMatch = true; // Initialize to true

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
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
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'Please sign up to get started',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.0),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 8.0,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email, color: Colors.green),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email.';
                              }
                              return null;
                            },
                            onSaved: (newValue) => _email = newValue!,
                          ),
                          SizedBox(height: 10.0),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icon(Icons.lock, color: Colors.green),
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
                              contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
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
                          SizedBox(height: 10.0),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Confirm your password',
                              prefixIcon: Icon(Icons.lock, color: Colors.green),
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
                              contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
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
                          SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  value: 'user',
                                  groupValue: _role,
                                  title: Text('Driver'),
                                  secondary: Icon(Icons.directions_car, color: Colors.green),
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
                                  title: Text('Station'),
                                  secondary: Icon(Icons.local_gas_station, color: Colors.green),
                                  onChanged: (value) {
                                    setState(() {
                                      _role = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.0),
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Match login page button color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                            ),
                            child: Text('Sign Up'),
                          ),
                          SizedBox(height: 10.0),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage
                              );
                            },
                            child: Text(
                              'Already have an account? Login',
                              style: TextStyle(
                                color: Colors.blue, // Use custom color for button text
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

  // Function to submit the form
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final result = await _authService.register(_email, _password, _role);
      if (result != null) {
        _showRegistrationSuccessDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed!'),
          ),
        );
      }
    }
  }

  // Function to show registration success dialog
  Future<void> _showRegistrationSuccessDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Account Created Successfully'),
          content: Text('Your account has been created successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Proceed to Login'),
            ),
          ],
        );
      },
    );
  }
}
