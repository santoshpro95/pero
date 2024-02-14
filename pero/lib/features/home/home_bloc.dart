import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:location/location.dart';
import 'package:pero/features/chatting/chatting_screen.dart';
import 'package:pero/features/location/location_screen.dart';
import 'package:pero/features/painting/painting_screen.dart';
import 'package:pero/features/youtube/youtube_screen.dart';
import 'package:pero/model/users_response.dart';
import 'package:pero/services/cache_storage/cache_storage_service.dart';
import 'package:pero/services/cache_storage/storage_keys.dart';
import 'package:pero/utils/app_constants.dart';
import 'package:pero/utils/app_images.dart';
import 'package:pero/utils/common_methods.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart' as locator;

class HomeBloc {
  // region Common Variables
  BuildContext context;
  String userName = "";
  String userRoom = "";

  // endregion

  // region Service
  CacheStorageService cacheStorageService = CacheStorageService();

  // endregion

  // region Controller
  final userDetailsCtrl = StreamController<bool>.broadcast();

  // endregion

  // region | Constructor |
  HomeBloc(this.context);

  // endregion

  // region Init
  void init() async {
    // userDetails
    getUserDetails();
  }

  // endregion

  // regin getUserDetails
  void getUserDetails() async {
    try {
      userName = await cacheStorageService.getString(StorageKeys.UserNameKey);
      userRoom = await cacheStorageService.getString(StorageKeys.UserRoomKey);
    } catch (exception) {
      print(exception.toString());
    } finally {
      if (!userDetailsCtrl.isClosed) userDetailsCtrl.sink.add(true);
    }
  }

  // endregion

  // region openChatting
  void openChatting() {
    var screen = const ChattingScreen();
    var route = CommonMethods.createRouteRTL(screen);
    Navigator.push(context, route);
  }

  // endregion

  // region openPainting
  void openPainting() {
    var screen = const PaintingScreen();
    var route = CommonMethods.createRouteRTL(screen);
    Navigator.push(context, route);
  }

  // endregion

  // region openYoutube
  void openYoutube() {
    var screen = const YoutubeScreen();
    var route = CommonMethods.createRouteRTL(screen);
    Navigator.push(context, route);
  }

  // endregion

  // region openLocation
  void openLocation() async {
    var permission = await locator.Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse) {
      openLocationScreen();
    }
  }

  // endregion

  // region openLocationScreen
  void openLocationScreen() {
    var screen = const LocationScreen();
    var route = CommonMethods.createRouteRTL(screen);
    Navigator.push(context, route);
  }

  // endregion

  // region exit
  void exit() async {
    // exit home screen
    Navigator.pop(context);

    // remove data
    await cacheStorageService.removeItem(StorageKeys.UserNameKey);
    await cacheStorageService.removeItem(StorageKeys.UserRoomKey);
  }

  // endregion

  // region dispose
  void dispose() {}
// endregion

}
