import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/login_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
              fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        backgroundColor: Colors.green[100],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[200]!],
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
                              hintText: 'example@example.com',
                              prefixIcon:
                                  const Icon(Icons.email, color: Colors.green),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 20.0),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email.';
                              }
                              final emailRegex = RegExp(
                                  r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                            onSaved: (newValue) => _email = newValue!,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter at least 8 characters',
                              prefixIcon:
                                  const Icon(Icons.lock, color: Colors.green),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _showPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.green),
                                onPressed: _isLoading
                                    ? null
                                    : () {
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
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 20.0),
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
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              prefixIcon:
                                  const Icon(Icons.lock, color: Colors.green),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.green),
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _showConfirmPassword =
                                              !_showConfirmPassword;
                                        });
                                      },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 20.0),
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
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters long.';
                              }
                              if (!_passwordsMatch) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('User'),
                                  value: 'user',
                                  groupValue: _role,
                                  activeColor: Colors.green,
                                  secondary: const Icon(Icons.directions_car,
                                      color: Colors.green),
                                  onChanged: _isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _role = value!;
                                          });
                                        },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Station'),
                                  value: 'station',
                                  groupValue: _role,
                                  activeColor: Colors.green,
                                  secondary: const Icon(Icons.local_gas_station,
                                      color: Colors.green),
                                  onChanged: _isLoading
                                      ? null
                                      : (value) {
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
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 30.0),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10.0),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()),
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
    setState(() {
      _isLoading = true;
    });
    final BuildContext contextBeforeAsync = context;
    try {
      final result = await _authService.register(_email, _password, _role);
      if (!mounted) return;
      if (result != null) {
        _showVerificationEmailSentDialog(contextBeforeAsync);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      Color backgroundColor;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered. Please use a different email.";
          backgroundColor = Colors.orange;
          break;
        case 'invalid-email':
          errorMessage = "The email address is not valid.";
          backgroundColor = Colors.purple;
          break;
        case 'weak-password':
          errorMessage = "The password is too weak. Please use a stronger password.";
          backgroundColor = Colors.red;
          break;
        case 'operation-not-allowed':
          errorMessage = "Registration is not enabled at this time. Please try again later.";
          backgroundColor = Colors.grey;
          break;
        default:
          errorMessage = e.message ?? "An error occurred during registration.";
          backgroundColor = Colors.red;
      }
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: backgroundColor,
        textColor: Colors.white,
        fontSize: 16.0
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An unexpected error occurred. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

Future<void> _showVerificationEmailSentDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Verify Your Email'),
        content: const Text(
            'A verification email has been sent to your email address. Please verify your email to complete the registration process.'),
        backgroundColor: Colors.green[100],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
      );
    },
  );
}

  // Future<void> _showVerificationEmailSentDialog(BuildContext context) async {
  //   return showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Verify Your Email'),
  //         content: const Text(
  //             'A verification email has been sent to your email address. Please verify your email to complete the registration process.'),
  //         backgroundColor: Colors.green[100],
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               Navigator.pushReplacement(
  //                 context,
  //                 MaterialPageRoute(builder: (context) => const LoginPage()),
  //               );
  //             },
  //             child: const Text('OK', style: TextStyle(color: Colors.green)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}