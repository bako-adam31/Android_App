import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'screens/welcome_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  //initialized before calling Firebase
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SharqiApp());
}

class SharqiApp extends StatelessWidget {
  const SharqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharqi',
      theme: ThemeData(primarySwatch: Colors.blue),
      //login/logout events automatically
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If user data - login
          if (snapshot.hasData) {
            return const MainNavigation();
          }
          //if not - Welcome screen.
          return const WelcomeScreen();
        },
      ),
    );
  }
}
