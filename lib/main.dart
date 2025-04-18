import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_firebase/firebase_options.dart';
import 'package:logging/logging.dart';

import 'auth_page.dart';

void main() async {
  _setupLogging();

  WidgetsFlutterBinding.ensureInitialized();

  Object? initError;

  try {
    final firebaseApp = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    log("Firebase App: $firebaseApp");
  } catch (error) {
    initError = error;
    log("Firebase Init Error => ${error.runtimeType}: $error");
  }

  runApp(AuthApp(initError: initError));
}

// ignore: must_be_immutable
class AuthApp extends StatelessWidget {
  AuthApp({super.key, required this.initError});

  static const _exitTimeoutInMillis = 2500;

  final Object? initError;

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  DateTime _timePrevExitPressed = DateTime.now().subtract(const Duration(milliseconds: _exitTimeoutInMillis));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      title: 'Firebase Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Demo App'),
        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, __) => _onPopInvokedWithResult(),
          child: initError == null ? const AuthPage() : _errorPage(),
        ),
      ),
    );
  }

  void _onPopInvokedWithResult() {
    final timeLastExitPressed = DateTime.now();
    final diff = timeLastExitPressed.difference(_timePrevExitPressed);
    final canExit = diff.inMilliseconds <= _exitTimeoutInMillis;
    _timePrevExitPressed = timeLastExitPressed;

    log("diff = ${diff.inMilliseconds}, canExit = $canExit");

    if (canExit) {
      SystemNavigator.pop();
    }

    const snackBar = SnackBar(
      content: Text("Press back again to Exit"),
      duration: Duration(milliseconds: _exitTimeoutInMillis),
    );

    _messengerKey.currentState?.showSnackBar(snackBar);
  }

  Widget _errorPage() {
    final strings = [initError.runtimeType.toString()];
    if (initError is FirebaseException) {
      final firebaseError = initError as FirebaseException;
      strings.add("code: ${firebaseError.code}");
      strings.add("message: ${firebaseError.message}");
    } else {
      strings.add(initError.toString());
    }
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: strings.map((e) => Text(e)).toList(),
      ),
    );
  }
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) {
    log('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}
