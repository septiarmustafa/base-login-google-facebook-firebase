import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google/app/modules/home/controllers/home_controller.dart';

import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  DashboardView({Key? key}) : super(key: key);

  final homeC = Get.put(HomeController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DashboardView'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Signed in ${homeC.currentUser!.displayName}',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
