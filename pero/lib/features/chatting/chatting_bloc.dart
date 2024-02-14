import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:pero/model/users_response.dart';
import 'package:pero/services/cache_storage/cache_storage_service.dart';
import 'package:pero/services/cache_storage/storage_keys.dart';
import 'package:pero/utils/app_constants.dart';
import 'package:pero/utils/common_widgets.dart';

// region ChatState
enum ChatState { Empty, Success, Failed }
// endregion

class ChattingBloc {
  // region Common Variables
  BuildContext context;
  String userRoom = "";
  String userName = "";
  late IO.Socket socket;
  final player = AudioPlayer();
  List<UserDataResponse> messages = [];
  CacheStorageService cacheStorageService = CacheStorageService();
  ScrollController controller = ScrollController();

  // endregion

  // region Text Controller
  final messageTextCtrl = TextEditingController();

  // endregion

  // region Controller
  final chatMessageCtrl = StreamController<ChatState>.broadcast();
  final connectCtrl = StreamController<bool>.broadcast();
  final userDetailsCtrl = StreamController<bool>.broadcast();

  // endregion

  // region | Constructor |
  ChattingBloc(this.context);

  // endregion

  // region init
  void init() {
    // getUserDetails
    getUserDetails();

    // initialise connect
    socket = IO.io(AppConstants.socketServerURL, IO.OptionBuilder().setTransports(['websocket']).build());

    // on connect
    socket.onConnect((_) => connectCtrl.sink.add(true));

    // on disconnect
    socket.onDisconnect((_) => connectCtrl.sink.add(false));

    // get socket connection
    socket.on("getMessage", (data) => getMessages(data));
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

  // region getMessages
  void getMessages(messageData) {
    try {
      // get userDetails
      var data = UserDataResponse.fromJson(messageData);

      // check room
      if (data.room != userRoom) return;

      // playSound
      playSound();

      // get Message
      messages.add(data);

      // scroll to bottom
      if (controller.hasClients) {
        controller.animateTo(controller.position.maxScrollExtent, duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
      }

      // set state
      if (messages.isEmpty) {
        if (!chatMessageCtrl.isClosed) chatMessageCtrl.sink.add(ChatState.Empty);
      } else {
        if (!chatMessageCtrl.isClosed) chatMessageCtrl.sink.add(ChatState.Success);
      }
    } catch (exception) {
      if (!chatMessageCtrl.isClosed) chatMessageCtrl.sink.add(ChatState.Failed);
    }
  }

  // endregion

  // region send Message
  void sendMessage() {
    // check validation
    if (messageTextCtrl.text.isEmpty) return;

    // prepare message
    UserDataResponse userDataResponse = UserDataResponse();
    userDataResponse.userName = userName;
    userDataResponse.updatedTime = DateTime.now().millisecondsSinceEpoch;
    userDataResponse.room = userRoom;
    userDataResponse.message = messageTextCtrl.text;

    // generate userInfo
    var userInfo = userDataResponse.toJson();
    socket.emit("chat", userInfo);

    // clear message
    messageTextCtrl.clear();

    // add message
    messages.add(userDataResponse);

    // scroll to bottom
    if (controller.hasClients) {
      controller.animateTo(controller.position.maxScrollExtent, duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
    }

    // set state
    if (messages.isEmpty) {
      if (!chatMessageCtrl.isClosed) chatMessageCtrl.sink.add(ChatState.Empty);
    } else {
      if (!chatMessageCtrl.isClosed) chatMessageCtrl.sink.add(ChatState.Success);
    }
  }

  // endregion

  // region play sound
  void playSound() async {
    try {
      await player.setAsset(AppConstants.appAlertSound);
      player.play();
    } catch (exception) {
      print(exception);
    }
  }

  // endregion

  // region dispose
  void dispose() {
    player.dispose();
    socket.disconnect();
    socket.dispose();
  }
// endregion
}
