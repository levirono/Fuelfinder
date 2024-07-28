import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/signup_page.dart';
import 'package:ff_main/utils/carousel_item.dart';
import 'package:ff_main/services/password_reset.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController(initialPage: 0);

  String _email = '';
  String _password = '';
  bool _showPassword = false;
  bool _showLoginFields = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page!.round() + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FUELFINDER',
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
                SizedBox(
                  height: 300.0,
                  child: PageView(
                    controller: _pageController,
                    children: const [
                      CarouselItem(
                          imagePath: 'assets/images/welcome1.png',
                          title: 'FUELFINDER ',
                          subtitle:
                              'always have a view of fuel stations to refill your car, save your time.'),
                      CarouselItem(
                          imagePath: 'assets/images/landing1.jpg',
                          title: 'COMPREHENSIVE MAP VIEW',
                          subtitle:
                              'You can open map view to see the stations on the map'),
                      CarouselItem(
                          imagePath: 'assets/images/welcome3.png',
                          title: 'EFFICIENCY TIPS',
                          subtitle:
                              'You get fuel efficiency tips that will help you save your fuel and time.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                if (!_showLoginFields)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showLoginFields = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 30.0),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (_showLoginFields) ...[
                  const Text(
                    'Please login to continue',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 30.0,
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
                                prefixIcon: const Icon(
                                    Icons.email, color: Colors.green),
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
                                return null;
                              },
                              onSaved: (newValue) => _email = newValue!,
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 10.0),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(
                                    Icons.lock, color: Colors.green),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.green),
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
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 20.0),
                              ),
                              obscureText: !_showPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password.';
                                }
                                return null;
                              },
                              onSaved: (newValue) => _password = newValue!,
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 20.0),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
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
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordPage()),
                                );
                              },
                              child: const Text(
                                'Forgot password',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            TextButton(
                              onPressed: _isLoading ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const SignupPage()),
                                );
                              },
                              child: const Text(
                                'Create an Account',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      try {
        User? user = await _authService.loginWithEmailVerificationCheck(_email, _password);
        if (user != null) {
          if (user.emailVerified) {
            Fluttertoast.showToast(
              msg: "Login successful!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0
            );
            
          } else {
            _showEmailNotVerifiedDialog();
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        Color backgroundColor;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = "No user found with this email.";
            backgroundColor = Colors.orange;
            break;
          case 'wrong-password':
            errorMessage = "Incorrect password. Please try again.";
            backgroundColor = Colors.red;
            break;
          case 'invalid-email':
            errorMessage = "Invalid email address.";
            backgroundColor = Colors.purple;
            break;
          case 'user-disabled':
            errorMessage = "This account has been disabled.";
            backgroundColor = Colors.grey;
            break;
          default:
            errorMessage = e.message ?? "Login failed!";
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

  void _showEmailNotVerifiedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Not Verified'),
          content: const Text('Please check your email for a verification link. You need to verify your email before logging in.'),
          backgroundColor: Colors.green[100],
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK',
              style: TextStyle(
                color: Colors.green
                )
              ),
            ),
          ],
        );
      },
    );
  }
}