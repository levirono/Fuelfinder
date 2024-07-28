import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> register(String email, String password, String role) async {
    try {
      if (!EmailValidator.validate(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is not valid.',
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        await user.sendEmailVerification();

        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'role': role,
          'emailVerified': false,
        });

        await _auth.signOut();

        return user;
      }
    } on FirebaseAuthException catch (e) {
      print(e.message);
      rethrow;
    } catch (e) {
      print(e);
      rethrow;
    }
    return null;
  }

  Future<User?> loginWithEmailVerificationCheck(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        if (!user.emailVerified) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email before logging in.',
          );
        }
        return user;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Stream<User?> get currentUser {
    return _auth.authStateChanges().map((user) => user);
  }

  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<String?> getUserRole() async {
    User? user = await getCurrentUser();
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      return userDoc['role'] as String?;
    }
    return null;
  }

  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }
}
