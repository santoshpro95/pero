import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pero/features/youtube/youtube_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// region YoutubeScreen
class YoutubeScreen extends StatefulWidget {
  const YoutubeScreen({Key? key}) : super(key: key);

  @override
  State<YoutubeScreen> createState() => _YoutubeScreenState();
}
// endregion

class _YoutubeScreenState extends State<YoutubeScreen> {
  // region Bloc
  late YoutubeBloc youtubeBloc;

  // endregion

  // region Init
  @override
  void initState() {
    youtubeBloc = YoutubeBloc(context);
    youtubeBloc.init();
    super.initState();
  }

  // endregion

  // region dispose
  @override
  void dispose() {
    youtubeBloc.dispose();
    super.dispose();
  }

  // endregion

  // region Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [connection(), userDetails(), urlField(), submitBtn(), youtubeView()],
      ),
    );
  }

  // endregion

  // region User Details
  Widget userDetails() {
    return StreamBuilder<bool>(
        stream: youtubeBloc.userDetailsCtrl.stream,
        builder: (context, snapshot) {
          return Container(
              color: Colors.black,
              child: Center(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("${youtubeBloc.userName} on Room No ${youtubeBloc.userRoom}", style: TextStyle(color: Colors.white)),
              )));
        });
  }

  // endregion

  // region connection
  Widget connection() {
    return StreamBuilder<bool>(
        stream: youtubeBloc.connectCtrl.stream,
        initialData: false,
        builder: (context, snapshot) {
          return Container(
            color: snapshot.data! ? Colors.green : Colors.red,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Center(
                  child: (snapshot.data!)
                      ? const Text("Connected", style: TextStyle(color: Colors.white))
                      : const Text("Disconnected", style: TextStyle(color: Colors.white))),
            ),
          );
        });
  }

  // endregion

  // region urlField
  Widget urlField() {
    return Row(
      children: [
        CupertinoButton(onPressed: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: Colors.black)),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(10),
            child:  TextField(
              controller: youtubeBloc.videoUrlTextCtrl,
              decoration: const InputDecoration(
                hintText: "Enter Youtube URL",
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // endregion

  // region submitBtn
  Widget submitBtn() {
    return CupertinoButton(
        child: const Text(
          "Play Video",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        onPressed: () => youtubeBloc.playVideo());
  }

  // endregion

  // region youtubeView
  Widget youtubeView() {
    return StreamBuilder<bool>(
        stream: youtubeBloc.videoCtrl.stream,
        initialData: false,
        builder: (context, snapshot) {
          if (!snapshot.data!) return const SizedBox();
          return YoutubePlayer(
              controller: youtubeBloc.youtubePlayerController!,
              showVideoProgressIndicator: true,
              onReady: () => youtubeBloc.playerListener(),
              onEnded: (data) => youtubeBloc.onEnd());
        });
  }
// endregion
}
