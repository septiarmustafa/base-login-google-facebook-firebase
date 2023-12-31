import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  Widget buildBody() {
    final GoogleSignInAccount? user = controller.currentUser;
    log(user.toString());
    if (user != null) {
      // return DashboardView();
      return Obx(
        () => controller.isLoading.isTrue
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ListTile(
                    leading: GoogleUserCircleAvatar(
                      identity: user,
                    ),
                    title: Text(user.displayName ?? ''),
                    subtitle: Text(user.email),
                  ),
                  const Text('Signed in successfully.'),
                  if (controller.isAuthorized.value) ...<Widget>[
                    // The user has Authorized all required scopes
                    Text(controller.contactText.value),
                    ElevatedButton(
                      child: const Text('REFRESH'),
                      onPressed: () => controller.handleGetContact(user),
                    ),
                  ],
                  if (!controller.isAuthorized.value) ...<Widget>[
                    const Text(
                        'Additional permissions needed to read your contacts.'),
                    ElevatedButton(
                      onPressed: () async =>
                          await controller.handleAuthorizeScopes(),
                      child: const Text('REQUEST PERMISSIONS'),
                    ),
                  ],
                  ElevatedButton(
                    onPressed: () async => await controller.handleSignOut(),
                    child: const Text('SIGN OUT'),
                  ),
                ],
              ),
      );
    } else {
      return Obx(
        () => controller.isLoading.isTrue
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  const Text('You are not currently signed in.'),
                  ElevatedButton(
                      onPressed: () {
                        controller.handleSignIn();
                      },
                      child: const Text("login with Google")),
                  ElevatedButton(
                      onPressed: () {
                        // controller.handleSignIn();
                      },
                      child: const Text("login with Facebook"))
                ],
              ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeView'),
        centerTitle: true,
      ),
      body: Obx(() => controller.isLoading.isTrue
          ? const Center(child: CircularProgressIndicator())
          : ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: buildBody(),
            )),
    );
  }
}
