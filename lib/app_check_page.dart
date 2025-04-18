import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const loadingStatus = "Loading...";

class AppCheckPage extends StatefulWidget {
  const AppCheckPage({super.key});

  @override
  State<StatefulWidget> createState() => _TestState();
}

class DataModel {
  final String data;
  final String status;

  const DataModel({required this.status, required this.data});

  factory DataModel.loading() => const DataModel(status: loadingStatus, data: "");

  DataModel copyWithLoading() => DataModel(status: loadingStatus, data: data);
}

class _TestState extends State<AppCheckPage> {
  DataModel? dataModel;

  @override
  void initState() async {
    super.initState();
    try {
      await FirebaseAppCheck.instance.activate();
      await FirebaseAuth.instance.signInAnonymously();
      log("Signed in with temporary account.");
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case "operation-not-allowed":
          log("Anonymous auth hasn't been enabled for this project.");
          break;
        default:
          log("Unknown error: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayStatusWidget = _displayStatusWidget(context);
    final imageWidget = _imageWidget();
    final dataReadWidget = _dataReadWidget(context);

    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [displayStatusWidget, imageWidget, dataReadWidget],
      ),
    );
  }

  Widget _displayStatusWidget(BuildContext context) {
    final text = dataModel == null ? "no data" : "data: ${dataModel?.data}\nstatus: ${dataModel?.status}";

    return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent, width: 2.0),
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        ),
        child: Padding(padding: const EdgeInsets.all(8.0), child: Text(text)));
  }

  Widget _dataReadWidget(BuildContext context) {
    if (dataModel?.status == loadingStatus) {
      return const Text(loadingStatus);
    } else {
      return MaterialButton(
        onPressed: _onReadData,
        child: const Text("Read Data"),
      );
    }
  }

  FutureOr<void> _onReadData() async {
    setState(() => dataModel = DataModel.loading());

    late final DataModel newDataModel;

    try {
      log("FirebaseFirestore.instance.collection('system_data') => start");
      final collection = FirebaseFirestore.instance.collection('system_data');
      log("collection = $collection");
      log("collection.doc(\"test_data\").get() => start");
      final DocumentSnapshot doc = await collection.doc("test_data").get();
      log("doc = $doc");
      newDataModel = DataModel(status: "success", data: doc["data"]);
    } catch (error) {
      log("error: $error");
      newDataModel = DataModel(status: "error: $error", data: "");
    }

    setState(() => dataModel = newDataModel);
  }

  String _randomImagePath() => "https://i.pravatar.cc/${200 + math.Random().nextInt(100)}";

  Widget _imageWidget() {
    const avatarSize = 150.0;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Image.network(_randomImagePath(), width: avatarSize, height: avatarSize),
    );
  }
}
