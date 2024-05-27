import 'package:flutter/material.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/signup_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
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
                  'Please login to continue',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 50.0,
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password.';
                              }
                              return null;
                            },
                            onSaved: (newValue) => _password = newValue!,
                          ),
                          SizedBox(height: 20.0),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                final result = await _authService.login(_email, _password);
                                if (result != null) {
                                  // Navigate to appropriate homepage based on role (handled in main.dart)
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Login failed!'),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.green, // Button color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                            ),
                            child: Text('Login'),
                          ),
                          SizedBox(height: 10.0),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SignupPage()), // Navigate to SignupPage
                              );
                            },
                            child: Text(
                              'Create an Account',
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
}
