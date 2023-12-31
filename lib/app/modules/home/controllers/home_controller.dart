import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'dart:convert' show json;

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

class HomeController extends GetxController {
  static const List<String> scopes = <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: scopes,
  );

  GoogleSignInAccount? currentUser;
  RxBool isAuthorized = false.obs; // has granted permissions?
  RxString contactText = ''.obs;
  RxBool isLoading = false.obs;
  RxString email = "".obs;

  @override
  void onInit() {
    super.onInit();
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      isAuthorized.value = account != null;
      if (kIsWeb && account != null) {
        isAuthorized.value = await _googleSignIn.canAccessScopes(scopes);
      }

      currentUser = account;
      isAuthorized.value = isAuthorized.value;

      if (isAuthorized.value) {
        unawaited(handleGetContact(account!));
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> handleGetContact(GoogleSignInAccount user) async {
    isLoading(true);
    contactText.value = 'Loading contact info...';
    final http.Response response = await http.get(
      Uri.parse('https://people.googleapis.com/v1/people/me/connections'
          '?requestMask.includeField=person.names'),
      headers: await user.authHeaders,
    );
    if (response.statusCode != 200) {
      contactText.value = 'People API gave a ${response.statusCode} '
          'response. Check logs for details.';
      log('People API ${response.statusCode} response: ${response.body}');
      return;
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final String? namedContact = _pickFirstNamedContact(data);
    if (namedContact != null) {
      contactText.value = 'I see you know $namedContact!';
    } else {
      contactText.value = 'No contacts to display.';
    }
    isLoading(false);
  }

  String? _pickFirstNamedContact(Map<String, dynamic> data) {
    isLoading(true);
    final List<dynamic>? connections = data['connections'] as List<dynamic>?;
    final Map<String, dynamic>? contact = connections?.firstWhere(
      (dynamic contact) => (contact as Map<Object?, dynamic>)['names'] != null,
      orElse: () => null,
    ) as Map<String, dynamic>?;
    if (contact != null) {
      final List<dynamic> names = contact['names'] as List<dynamic>;
      final Map<String, dynamic>? name = names.firstWhere(
        (dynamic name) =>
            (name as Map<Object?, dynamic>)['displayName'] != null,
        orElse: () => null,
      ) as Map<String, dynamic>?;
      if (name != null) {
        return name['displayName'] as String?;
      }
    }
    isLoading(false);
    return null;
  }

  Future<void> handleSignIn() async {
    isLoading(true);
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      log(error.toString());
    }
    isLoading(false);
  }

  Future<void> handleAuthorizeScopes() async {
    isLoading(true);
    final bool isAuthorize = await _googleSignIn.requestScopes(scopes);
    isAuthorized.value = isAuthorize;
    if (isAuthorize) {
      unawaited(handleGetContact(currentUser!));
    }
    isLoading(false);
  }

  Future<void> handleSignOut() async {
    isLoading(true);
    _googleSignIn.disconnect();
    isLoading(false);
  }

  Future<UserCredential> signInWithFacebook() async {
    isLoading(true);
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance
        .login(permissions: ['email', 'public_profile', 'user_birthday']);
    log("Login Result : $loginResult");

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);
    log("Facebook Auth Credential : $facebookAuthCredential");

    final userdata = await FacebookAuth.instance.getUserData();

    email.value = userdata["email"];

    isLoading(false);

    // Once signed in, return the UserCredential
    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  }
}
