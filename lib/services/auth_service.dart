import 'package:firebase_auth/firebase_auth.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up with Email, Password, and Username
  Future<User?> signUp(String email, String password, String username) async {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    await user?.updateDisplayName(username);

    final token = await user?.getIdToken();
    print('FIREBASE TOKEN (signup): $token');

    return user;
  }

  // Log In
  Future<User?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.message}");
      return null;
    }
  }

  // Log Out
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Check current user state
  User? get currentUser => _auth.currentUser;
}