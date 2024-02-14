import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pero/utils/app_images.dart';
import 'home_bloc.dart';

// region HomeScreen
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}
// endregion

class _HomeScreenState extends State<HomeScreen> {
  // region Bloc
  late HomeBloc homeBloc;

  // endregion

  // region Init
  @override
  void initState() {
    homeBloc = HomeBloc(context);
    homeBloc.init();
    super.initState();
  }

  // endregion

  // region dispose
  @override
  void dispose() {
    homeBloc.dispose();
    super.dispose();
  }

  // endregion

  // region build
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:false,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: userDetails(),
            actions: [
              CupertinoButton(child: const Icon(Icons.exit_to_app, color: Colors.black), onPressed: () => homeBloc.exit()),
            ],
          ),
          body: body()),
    );
  }

  // endregion

  // region body
  Widget body() {
    return Stack(
      children: [
        Center(child: SvgPicture.asset(AppImages.homeBackground)),
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.only(right: 100, top: 100),
            child: CupertinoButton(
              child: const Text("Drawing", style: TextStyle(color: Colors.white, fontSize: 18)),
              onPressed: () => homeBloc.openPainting(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.only(left: 130, top: 100),
            child: CupertinoButton(
              child: const Text("Chatting", style: TextStyle(color: Colors.white, fontSize: 18)),
              onPressed: () => homeBloc.openChatting(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.only(bottom: 150),
            child: CupertinoButton(
              child: const Text(
                "Location",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              onPressed: () => homeBloc.openLocation(),
            ),
          ),
        ),
      ],
    );
  }

  // endregion

  // region userDetails
  Widget userDetails() {
    return StreamBuilder<bool>(
        stream: homeBloc.userDetailsCtrl.stream,
        builder: (context, snapshot) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
            child: Center(
                child: Text(
              "Room No. ${homeBloc.userRoom}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 20, letterSpacing: 1),
            )),
          );
        });
  }

  // endregion

  // region RoomType
  Widget roomType(String title, onTap, Icon icon) {
    return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            icon,
            CupertinoButton(child: Text(title, style: const TextStyle(color: Colors.black, fontSize: 18)), onPressed: () => onTap()),
          ],
        ));
  }

// endregion
}
