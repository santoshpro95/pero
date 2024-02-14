import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pero/features/painting/custom_painter.dart';
import 'painting_bloc.dart';

// region PaintingScreen
class PaintingScreen extends StatefulWidget {
  const PaintingScreen({Key? key}) : super(key: key);

  @override
  State<PaintingScreen> createState() => _PaintingScreenState();
}
// endregion

class _PaintingScreenState extends State<PaintingScreen> {
  // region Bloc
  late PaintingBloc paintingBloc;

  // endregion

  // region Init
  @override
  void initState() {
    paintingBloc = PaintingBloc(context);
    paintingBloc.init();
    super.initState();
  }

  // endregion

  // region Dispose
  @override
  void dispose() {
    paintingBloc.dispose();
    super.dispose();
  }

  // endregion

  // region Build
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              foregroundColor: Colors.white,
              leading: CupertinoButton(onPressed: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: Colors.white)),
              backgroundColor: Colors.black,
              title: StreamBuilder<bool>(
                  stream: paintingBloc.userDetailsCtrl.stream,
                  builder: (context, snapshot) {
                    return Text("Draw on Room No - ${paintingBloc.userRoom}");
                  }),
              actions: [
                CupertinoButton(child: const Icon(Icons.undo, color: Colors.white), onPressed: () => paintingBloc.undo()),
              ],
            ),
            body: body()));
  }

  // endregion

  // region body
  Widget body() {
    return Stack(
      children: [
        Column(children: [connection(), color(), draw()]),
        currentDrawing()
      ],
    );
  }

  // endregion

  // region color
  Widget color() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          StreamBuilder<bool>(
              stream: paintingBloc.colorCtrl.stream,
              builder: (context, snapshot) {
                return Icon(Icons.edit, color: Color(paintingBloc.penColor));
              }),
          const SizedBox(width: 20),
          Expanded(child: colorSelection())
        ],
      ),
    );
  }

  // endregion

  // region Color Selection
  Widget colorSelection() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(width: 2, color: Colors.black)),
      child: SizedBox(
          height: 50,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: paintingBloc.colors.length,
              itemBuilder: (context, index) => CupertinoButton(
                  child: Icon(Icons.circle, color: paintingBloc.colors[index]),
                  onPressed: () => paintingBloc.colorSelection(paintingBloc.colors[index].value)))),
    );
  }

  // endregion

  // region currentDrawing
  Widget currentDrawing() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: ValueListenableBuilder<String>(
          valueListenable: paintingBloc.drawingStageCtrl,
          builder: (context, value, _) {
            if (value.isEmpty) return const SizedBox();
            return Center(
                child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w300)));
          }),
    );
  }

  // endregion

  // region draw
  Widget draw() {
    return Expanded(
        child: StreamBuilder<bool>(
            stream: paintingBloc.connectCtrl.stream,
            initialData: false,
            builder: (context, snapshot) {
              return Painter(paintingBloc.paintController);
            }));
  }

  // endregion

  // region connection
  Widget connection() {
    return StreamBuilder<bool>(
        stream: paintingBloc.connectCtrl.stream,
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

}
