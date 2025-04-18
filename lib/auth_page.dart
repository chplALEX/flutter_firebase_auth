import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<StatefulWidget> createState() => _TestState();
}

class _TestState extends State<AuthPage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final _facebookAuth = FacebookAuth.instance;

  String? idToken;

  OAuthCredential? _credential;

  UserCredential? _userCredential;

  @override
  Widget build(BuildContext context) {
    final authWidget = _authWidget(context);
    final googleWidget = _googleWidget(context);
    final facebookWidget = _facebookWidget(context);
    final appleWidget = _appleWidget(context);
    final anonymousWidget = _anonymousWidget(context);
    final logoutWidget = _logoutWidget(context);

    final widgets = [authWidget, googleWidget, facebookWidget, appleWidget, anonymousWidget, logoutWidget];

    return SingleChildScrollView(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widgets.length,
        itemBuilder: (context, index) => widgets[index],
        separatorBuilder: (context, index) => const Divider(),
      ),
    );
  }

  Widget _authWidget(BuildContext context) {
    final widget = StreamBuilder<User?>(
      initialData: null,
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        late final String text;
        late final TextAlign textAlign;

        if (snapshot.hasData) {
          final user = snapshot.data;

          user?.getIdToken().then((value) => idToken = "${value?.substring(0, 40)}...");

          late final String? email;

          try {
            email = user?.providerData.single.email;
          } catch (e) {
            email = null;
            log("get user?.providerData.single.email => error: $e");
          }

          text = "display name: ${user?.displayName}\n"
              "email: $email\n"
              "uid: ${user?.uid}\n"
              "tenantId: ${user?.tenantId}\n"
              "refreshToken: ${user?.refreshToken}\n"
              "idToken = $idToken}";
          textAlign = TextAlign.start;
        } else {
          text = "no authenticated user";
          textAlign = TextAlign.center ;
        }

        return Padding(padding: const EdgeInsets.all(8.0), child: Text(text, textAlign: textAlign));
      },
    );

    return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent, width: 2.0),
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        ),
        child: widget);
  }

  Widget _googleWidget(BuildContext context) {
    const text = Text("Google");
    final widget = MaterialButton(
      onPressed: _onGoogleAuth,
      child: text,
    );

    return widget;
  }

  Widget _facebookWidget(BuildContext context) {
    const text = Text("Facebook");
    final widget = MaterialButton(
      onPressed: _onFacebookAuth,
      child: text,
    );

    return widget;
  }

  Widget _appleWidget(BuildContext context) {
    const text = Text("Apple");
    final widget = MaterialButton(
      onPressed: _onAppleAuth,
      child: text,
    );

    return widget;
  }

  Widget _anonymousWidget(BuildContext context) {
    const text = Text("Anonymous Firebase SingIn");
    final widget = MaterialButton(
      onPressed: _onAnonymousPush,
      child: text,
    );

    return widget;
  }

  Widget _logoutWidget(BuildContext context) {
    const text = Text("logout");
    final widget = MaterialButton(
      onPressed: _onLogout,
      child: text,
    );

    return widget;
  }

  FutureOr<void> _onGoogleAuth() async {
    try {
      // *** Google side
      final googleSignInAccount = await _googleSignIn.signIn();
      final googleSignInAuthentication = await googleSignInAccount?.authentication;
      final accessToken = googleSignInAuthentication?.accessToken;
      final idToken = googleSignInAuthentication?.idToken;
      if (accessToken == null && idToken == null) {
        return;
      }
      _credential = GoogleAuthProvider.credential(accessToken: accessToken, idToken: idToken);
      // *** Firebase side
      _userCredential = await _firebaseAuth.signInWithCredential(_credential!);
      log("_onGoogleAuth() => Success => _userCredential = $_userCredential");
    } catch (e, s) {
      log("Google authentication error => $e");
      log("Google authentication error stack =>\n$s");
    }
  }

  FutureOr<void> _onFacebookAuth() async {
    final LoginResult result = await _facebookAuth.login(permissions: const ['email', 'public_profile']);
    log('Facebook auth result status => ${result.status}');

    if (result.status == LoginStatus.success) {
      log('result.accessToken => ${result.accessToken}');
    } else {
      log("result.message => ${result.message}");
      return;
    }

    _credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);

    // *** Firebase side
    try {
      _userCredential = await _firebaseAuth.signInWithCredential(_credential!);
    } catch (e, s) {
      log("Firebase authentication error => $e");
      log("Firebase authentication error stack =>\n$s");
    }
  }

  void _onAppleAuth() {}

  FutureOr<void> _onAnonymousPush() async {
    // *** Firebase side
    try {
      log("_firebaseAuth.signInAnonymously() => start");
      _userCredential = await _firebaseAuth.signInAnonymously();
      _credential = null;
      log("Anonymous Firebase authentication success: "
          "if anonymous = ${_userCredential?.user?.isAnonymous}, "
          "uid = ${_userCredential?.user?.uid}");
    } catch (e) {
      log("Anonymous Firebase authentication error: $e");
    }
  }

  FutureOr<void> _onLogout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await _facebookAuth.logOut();
  }
}
