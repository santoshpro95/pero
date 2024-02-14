import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pero/model/users_response.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:pero/services/cache_storage/cache_storage_service.dart';
import 'package:pero/services/cache_storage/storage_keys.dart';
import 'package:pero/utils/app_constants.dart';
import 'package:pero/utils/common_widgets.dart';
import 'custom_painter.dart';

class PaintingBloc {
  // region Common Variables
  BuildContext context;
  String userRoom = "";
  String userName = "";
  late IO.Socket socket;
  int penColor = Colors.black.value;
  List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.pinkAccent,
    Colors.grey,
    Colors.green,
    Colors.brown,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.teal,
    Colors.purpleAccent
  ];

  List<UserDataResponse> points = [];
  late CustomPainterController paintController;
  CacheStorageService cacheStorageService = CacheStorageService();

  // endregion

  // region Controller
  final connectCtrl = StreamController<bool>.broadcast();
  final drawingStageCtrl = ValueNotifier("");
  final userDetailsCtrl = StreamController<bool>.broadcast();
  final colorCtrl = StreamController<bool>.broadcast();

  // endregion

  // region | Constructor |
  PaintingBloc(this.context);

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
    socket.on("getDraw", (data) => getDraw(data));

    // get socket connection
    socket.on("getColor", (data) => getColor(data));

    // setup Draw
    setupDraw();
  }

  // endregion

  // region getColor
  void getColor(colorData) {
    // get userDetails
    var data = UserDataResponse.fromJson(colorData);

    // check room
    if (data.room != userRoom) return;

    // set color
    paintController.drawColor = Color(data.color!);
  }

  // endregion

  // region sendSampleDraw
  void sendSampleDraw() {
    // add draw data
    paintController.startData = const Offset(2.3, 3.4);
    paintController.updateData = const Offset(3.3, 4.4);

    // send end data
    sendData("end");
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

  // region setupDraw
  void setupDraw() {
    paintController = CustomPainterController(startPaintListener, updatePaintListener, endPaintListener);
    paintController.thickness = 5.0;
    paintController.backgroundColor = Colors.white;
    paintController.eraseMode = false;
    paintController.drawColor = Color(penColor);

    // send sampleDraw
    // this is basically used for warm up system to make start draw for both user
    sendSampleDraw();
  }

  // endregion

  // region startPaintListener
  void startPaintListener() {
    drawingStageCtrl.value = "";
    sendData("start");
  }

  // endregion

  // region updatePaintListener
  void updatePaintListener() {
    sendData("update");
  }

  // endregion

  // region endPaintListener
  void endPaintListener() {
    sendData("end");
  }

  // endregion

  // region send data
  void sendData(String state) {
    if (paintController.updateData.dx == 0) return;
    if (paintController.startData.dx == 0) return;

    // prepare message
    UserDataResponse userDataResponse = UserDataResponse();
    userDataResponse.userName = userName;
    userDataResponse.updatedTime = DateTime.now().millisecondsSinceEpoch;
    userDataResponse.room = userRoom;
    userDataResponse.xPoint =
        state == "start" ? double.parse(paintController.startData.dx.toString()) : double.parse(paintController.updateData.dx.toString());
    userDataResponse.yPoint =
        state == "start" ? double.parse(paintController.startData.dy.toString()) : double.parse(paintController.updateData.dy.toString());
    userDataResponse.drawState = state;

    // generate userInfo
    var userInfo = userDataResponse.toJson();
    socket.emit("draw", userInfo);
  }

  // endregion

  // region getDraw
  void getDraw(messageData) {
    try {
      // get userDetails
      var data = UserDataResponse.fromJson(messageData);

      // check room
      if (data.room != userRoom) return;

      // get points
      if (data.xPoint == 0) return;
      var offsets = Offset(data.xPoint!.toDouble(), data.yPoint!.toDouble());

      // hide name
      drawingStageCtrl.value = "";

      // clear data
      if (data.drawState == "clear") {
        paintController.clear();
      }

      // undo
      if (data.drawState == "undo") {
        drawingStageCtrl.value = "${data.userName} removing now";
        paintController.undo();
        Future.delayed(const Duration(seconds: 1), () {
          drawingStageCtrl.value = "";
        });
      }

      // start points
      if (data.drawState == "start") {
        drawingStageCtrl.value = "${data.userName} drawing now";
        paintController.pathHistory.add(offsets);
        paintController.refreshPaint();
      }

      // end offset
      if (data.drawState == "end") {
        paintController.pathHistory.endCurrent();
        paintController.refreshPaint();
        drawingStageCtrl.value = "";
        paintController.drawColor = Color(penColor);
      }

      // update offset
      if (data.drawState == "update") {
        paintController.pathHistory.updateCurrent(offsets);
        paintController.refreshPaint();

        // show drawing person name
        if (data.userName == userName) {
          drawingStageCtrl.value = "";
        } else {
          drawingStageCtrl.value = "${data.userName} drawing now";
        }
      }
    } catch (exception) {
      print(exception.toString());
    }
  }

  // endregion

  // region clear
  void clear() {
    paintController.clear();
    sendData("clear");
  }

  // endregion

  // region undo
  void undo() {
    paintController.undo();
    sendData("undo");
  }

  // endregion

  // region colorSelection
  void colorSelection(int color) {
    // prepare message
    UserDataResponse userDataResponse = UserDataResponse();
    userDataResponse.userName = userName;
    userDataResponse.updatedTime = DateTime.now().millisecondsSinceEpoch;
    userDataResponse.room = userRoom;
    userDataResponse.color = color;

    // generate userInfo
    var userInfo = userDataResponse.toJson();
    socket.emit("color", userInfo);

    // change color
    penColor = color;
    paintController.drawColor = Color(penColor);
    if (!colorCtrl.isClosed) colorCtrl.sink.add(true);
  }

  // endregion

  // region dispose
  void dispose() {
    socket.disconnect();
    socket.dispose();
    drawingStageCtrl.dispose();
    connectCtrl.close();
  }
// endregion

}
