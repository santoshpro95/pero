import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pero/features/chatting/chatting_bloc.dart';
import 'package:pero/model/users_response.dart';

// region ChattingScreen
class ChattingScreen extends StatefulWidget {
  const ChattingScreen({Key? key}) : super(key: key);

  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}
// endregion

class _ChattingScreenState extends State<ChattingScreen> {
  // region bloc
  late ChattingBloc chattingBloc;

  // endregion

  // region init
  @override
  void initState() {
    chattingBloc = ChattingBloc(context);
    chattingBloc.init();
    super.initState();
  }

  // endregion

  // region dispose
  @override
  void dispose() {
    chattingBloc.dispose();
    super.dispose();
  }

  // endregion

  // region Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: StreamBuilder<bool>(
              stream: chattingBloc.userDetailsCtrl.stream,
              builder: (context, snapshot) {
                return Text("Chat on Room No - ${chattingBloc.userRoom}");
              })),
      body: body(),
    );
  }

  // endregion

  // region body
  Widget body() {
    return Column(
      children: [connection(), messageList(), sendMessage()],
    );
  }

  // endregion

  // region connection
  Widget connection() {
    return StreamBuilder<bool>(
        stream: chattingBloc.connectCtrl.stream,
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

  // region messageList
  Widget messageList() {
    return Expanded(
      child: StreamBuilder<ChatState>(
          stream: chattingBloc.chatMessageCtrl.stream,
          initialData: ChatState.Empty,
          builder: (context, snapshot) {
            // empty
            if (ChatState.Empty == snapshot.data!) {
              return const Center(child: Text("No Result", style: TextStyle(color: Colors.grey)));
            }

            // Failed
            if (ChatState.Failed == snapshot.data!) {
              return const Center(child: Text("Something went wrong!, Try Again", style: TextStyle(color: Colors.red)));
            }

            // success
            return ListView.builder(
                controller: chattingBloc.controller,
                padding: const EdgeInsets.only(bottom: 50, left: 20, right: 20, top: 20),
                itemBuilder: (context, index) => messageItem(chattingBloc.messages[index]),
                itemCount: chattingBloc.messages.length);
          }),
    );
  }

  // endregion

  // region messageItem
  Widget messageItem(UserDataResponse userDataResponse) {
    if (userDataResponse.userName != chattingBloc.userName) return myMessageItem(userDataResponse);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.black),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              child: Text("${userDataResponse.message}", style: TextStyle(color: Colors.white))),
        ),
      ],
    );
  }

  // endregion

  // region myMessageItem
  Widget myMessageItem(UserDataResponse userDataResponse) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${userDataResponse.userName} • ', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              TextSpan(
                text: '${userDataResponse.message}',
                style: const TextStyle(color: Colors.black, fontSize: 15),
              ),
            ],
          ),
        ));
  }

  // endregion

  // region sendMessage
  Widget sendMessage() {
    return Container(
      margin: const EdgeInsets.only(left: 10, right:10, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              maxLines: 3,
              controller: chattingBloc.messageTextCtrl,
              minLines: 1,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                  hintText: "Enter message",
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2))),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.black),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => chattingBloc.sendMessage(),
              child: const Icon(Icons.send_outlined, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
// endregion
}
