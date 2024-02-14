import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:pero/model/users_response.dart';
import 'package:pero/services/cache_storage/cache_storage_service.dart';
import 'package:pero/services/cache_storage/storage_keys.dart';
import 'package:pero/utils/app_constants.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class YoutubeBloc {
  // region Common Variables
  BuildContext context;
  YoutubePlayerController? youtubePlayerController;
  String userRoom = "";
  String userName = "";
  late IO.Socket socket;
  List<UserDataResponse> playData = [];
  CacheStorageService cacheStorageService = CacheStorageService();

  // endregion

  // region Text Controller
  final videoUrlTextCtrl = TextEditingController(text: "https://www.youtube.com/watch?v=WAzNxZ-w5hg&ab_channel=SaidTheRain");

  // endregion

  // region Controller
  final videoCtrl = StreamController<bool>.broadcast();
  final connectCtrl = StreamController<bool>.broadcast();
  final userDetailsCtrl = StreamController<bool>.broadcast();

  // endregion

  // region | Constructor |
  YoutubeBloc(this.context);

  // endregion

  // region Init
  void init() {
    // getUserDetails
    getUserDetails();

    // initialise connect
    socket = IO.io(AppConstants.socketServerURL, IO.OptionBuilder().setTransports(['websocket']).build());

    // on connect
    socket.onConnect((_) {
      if (!connectCtrl.isClosed) connectCtrl.sink.add(true);
    });

    // on disconnect
    socket.onDisconnect((_) {
      if (!connectCtrl.isClosed) connectCtrl.sink.add(false);
    });

    // get socket connection
    socket.on("getPlay", (data) => getMedia(data));
  }

  // endregion

  // region player Listener
  void playerListener() {
    youtubePlayerController?.addListener(() {
      //sendPlayerData();

      var pos = youtubePlayerController?.flags.endAt;
      print(pos);
    });
  }

  // endregion

  // region sendPlayerData
  void sendPlayerData() {
    // get player position
    var position = youtubePlayerController?.value.position.inSeconds;

    // prepare message
    UserDataResponse userDataResponse = UserDataResponse();
    userDataResponse.userName = userName;
    userDataResponse.updatedTime = DateTime.now().millisecondsSinceEpoch;
    userDataResponse.room = userRoom;
    userDataResponse.playerUrl = videoUrlTextCtrl.text;
    userDataResponse.playerDuration = position;

    // generate userInfo
    var userInfo = userDataResponse.toJson();
    socket.emit("play", userInfo);
  }

  // endregion

  // region getMedia
  void getMedia(payerData) {
    try {
      // get userDetails
      var data = UserDataResponse.fromJson(payerData);

      // check room
      if (data.room != userRoom) return;

      // create controller
      if (youtubePlayerController == null) {
        videoUrlTextCtrl.text = data.playerUrl!;
        playVideo();
      }

      // // get position
      // var position = data.playerDuration;
      //
      // // set player position
      //   var playingPosition = youtubePlayerController?.value.position.inSeconds;
      //   if (playingPosition != position) {
      //     print("playing position $playingPosition position $position");
      //   //  youtubePlayerController?.seekTo(Duration(milliseconds: position ?? 0));
      //   }
    } catch (exception) {
      print(exception.toString());
    }
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

  // region playVideo
  void playVideo() {
    // check validation
    if (videoUrlTextCtrl.text.isEmpty) return;

    // get video ID
    String? videoId = YoutubePlayer.convertUrlToId(videoUrlTextCtrl.text);

    // create Play controller
    youtubePlayerController = YoutubePlayerController(initialVideoId: videoId!, flags: const YoutubePlayerFlags(autoPlay: true, mute: false));

    // show video
    if (!videoCtrl.isClosed) videoCtrl.sink.add(true);

    // sendPlayerData
    sendPlayerData();
  }

  // endregion

  // region On End
  void onEnd() {}

  // endregion

  // region dispose
  void dispose() {
    youtubePlayerController?.dispose();
    connectCtrl.close();
    videoCtrl.close();
    userDetailsCtrl.close();
    socket.disconnect();
    socket.dispose();
  }
// endregion

}
