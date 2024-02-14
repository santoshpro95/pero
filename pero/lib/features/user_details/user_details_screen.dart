import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pero/features/user_details/user_details_bloc.dart';

// region UserDetailsScreen
class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({Key? key}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}
// endregion

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  // region Bloc
  late UserDetailsBloc userDetailsBloc;

  // endregion

  // region Init
  @override
  void initState() {
    userDetailsBloc = UserDetailsBloc(context);
    userDetailsBloc.init();
    super.initState();
  }

  // endregion

  // region Dispose
  @override
  void dispose() {
    userDetailsBloc.dispose();
    super.dispose();
  }

  // endregion

  // region Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(backgroundColor: Colors.black, centerTitle: true, title: const Text("Welcome")), backgroundColor: Colors.white, body: body());
  }

  // endregion

  // region body
  Widget body() {
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          TextField(
              controller: userDetailsBloc.roomNumberCtrl,
              maxLength: 5,
              keyboardType: TextInputType.number,
              onChanged: (text) => userDetailsBloc.onChangeText(),
              decoration: const InputDecoration(
                hintText: "Enter Room No.",
                labelText: "Enter No.",
                counter: SizedBox(),
                labelStyle: TextStyle(color: Colors.black),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
              )),
          const SizedBox(height: 10),
          TextField(
              controller: userDetailsBloc.nameTextCtrl,
              maxLength: 8,
              onChanged: (text) => userDetailsBloc.onChangeText(),
              decoration: const InputDecoration(
                hintText: "Enter Nick Name",
                labelText: "Your Nick Name",
                counter: SizedBox(),
                labelStyle: TextStyle(color: Colors.black),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
              )),
          submit()
        ],
      ),
    );
  }

// endregion

// region submit
  Widget submit() {
    return StreamBuilder<bool>(
        stream: userDetailsBloc.validCtrl.stream,
        initialData: false,
        builder: (context, snapshot) {
          return CupertinoButton(
              onPressed: snapshot.data! ? () => userDetailsBloc.submit() : null,
              child: Container(
                  height: 45,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: snapshot.data! ? Colors.black : Colors.grey),
                  child: const Center(child: Text("Submit", style: TextStyle(color: Colors.white)))));
        });
  }
// endregion
}
