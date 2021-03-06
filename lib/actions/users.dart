import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:figstyle/screens/home/home.dart';
import 'package:figstyle/state/colors.dart';
import 'package:figstyle/state/user_state.dart';
import 'package:figstyle/utils/app_localstorage.dart';

Future<bool> checkEmailAvailability(String email) async {
  try {
    final callable = CloudFunctions(
      app: Firebase.app(),
      region: 'europe-west3',
    ).getHttpsCallable(
      functionName: 'users-checkEmailAvailability',
    );

    final resp = await callable.call({'email': email});
    final isOk = resp.data['isAvailable'] as bool;
    return isOk;
  } catch (error) {
    debugPrint(error.toString());
    return false;
  }
}

bool checkEmailFormat(String email) {
  return RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}")
      .hasMatch(email);
}

Future<bool> checkNameAvailability(String username) async {
  try {
    final callable = CloudFunctions(
      app: Firebase.app(),
      region: 'europe-west3',
    ).getHttpsCallable(
      functionName: 'users-checkNameAvailability',
    );

    final resp = await callable.call({'name': username});
    final isOk = resp.data['isAvailable'] as bool;
    return isOk;
  } catch (error) {
    debugPrint(error.toString());
    return false;
  }
}

bool checkUsernameFormat(String username) {
  final str = RegExp("[a-zA-Z0-9_]{3,}").stringMatch(username);
  return username == str;
}

void userSignOut({
  BuildContext context,
  bool autoNavigateAfter = true,
}) async {
  await appLocalStorage.clearUserAuthData();
  await FirebaseAuth.instance.signOut();
  userState.setUserDisconnected();
  userState.signOut();

  if (autoNavigateAfter) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => Home()),
    );
  }
}

Future userGetAndSetAvatarUrl(UserCredential authResult) async {
  final user = await FirebaseFirestore.instance
      .collection('users')
      .doc(authResult.user.uid)
      .get();

  final data = user.data;
  final avatarUrl = data()['urls']['image'];

  String imageName = avatarUrl.replaceFirst('local:', '');
  String path = 'assets/images/$imageName-${stateColors.iconExt}.png';

  userState.setAvatarUrl(path);
}
