import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommonWidgets {
  // region alertDialog
  static void alertDialog(BuildContext context, String title) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text("Alert from $title"),
              actions: [CupertinoButton(child: const Text("Okay"), onPressed: () => Navigator.pop(context))],
            ));
  }

// endregion

}
