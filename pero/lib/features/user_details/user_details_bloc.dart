import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pero/features/home/home_screen.dart';
import 'package:pero/services/cache_storage/cache_storage_service.dart';
import 'package:pero/services/cache_storage/storage_keys.dart';
import 'package:pero/utils/common_methods.dart';

class UserDetailsBloc {
  // region Common Variables
  BuildContext context;
  CacheStorageService cacheStorageService = CacheStorageService();

  // endregion

  // region Text Controller
  final roomNumberCtrl = TextEditingController();
  final nameTextCtrl = TextEditingController();

  // endregion

  // region Controller
  final validCtrl = StreamController<bool>.broadcast();
  final checkCtrl = ValueNotifier(true);
  // endregion

  // region | Constructor |
  UserDetailsBloc(this.context);

  // endregion

  // region Init
  void init() {
    checkUser();
  }

  // endregion

  // region checkUser
  void checkUser() async {
    // check if exist
    var isExist = await cacheStorageService.containsKey(StorageKeys.UserNameKey);

    // if not exist return
    if (!isExist) return;

    // open Home Screen
    openHomeScreen();
  }

  // endregion

  // region submit
  void submit() async {
    // check validation
    if (roomNumberCtrl.text.isEmpty) return;
    if (nameTextCtrl.text.isEmpty) return;

    // save user name and room
    await cacheStorageService.saveString(StorageKeys.UserNameKey, nameTextCtrl.text);
    await cacheStorageService.saveString(StorageKeys.UserRoomKey, roomNumberCtrl.text);

    // clear field
    roomNumberCtrl.clear();
    nameTextCtrl.clear();

    // open Home Screen
    openHomeScreen();
  }

  // endregion

  // region onCheck
  void onCheck(bool value){
    checkCtrl.value = value;
    onChangeText();
  }
  // endregion

  // region onChangeRoom
  void onChangeText(){
    var isValid = nameTextCtrl.text.isNotEmpty && roomNumberCtrl.text.isNotEmpty && checkCtrl.value;
    if(!validCtrl.isClosed) validCtrl.sink.add(isValid);
  }
  // endregion

  // region openHomeScreen
  void openHomeScreen() {
    var homeScreen = const HomeScreen();
    var route = CommonMethods.createRouteRTL(homeScreen);
    Navigator.push(context, route);
  }

  // endregion

  // region dispose
  void dispose() {
    nameTextCtrl.dispose();
  }
// endregion
}
