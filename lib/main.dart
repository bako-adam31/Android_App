import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling Firebase
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SharqiApp());
}

class SharqiApp extends StatelessWidget {
  const SharqiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharqi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // The StreamBuilder listens for login/logout events automatically
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If we have user data, they are logged in.
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // Otherwise, show the Welcome screen.
          return const WelcomeScreen();
        },
      ),
    );
  }
}