import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CommonMethods {
  // region read Json File
  static Future<Map<String, dynamic>> getJsonFile(String filePath) async {
    var jsonStr = await rootBundle.loadString(filePath);
    return json.decode(jsonStr);
  }

// endregion

  // region get Short form
  static String getShortForm(String fullName) {
    if (fullName.isEmpty) return "NA";
    var name = fullName.split(" ");
    var shortName = "${name.first.substring(0, 1)}${name.last.substring(0, 1)}".toUpperCase();
    return shortName;
  }

  // endregion

  //#region Region - Route Right to Left
  static Route createRouteRTL(var screen) {
    return CupertinoPageRoute(builder: (_) => screen);
  }

  //#endregion

  // region getDistanceFromLatLon
  static String getDistanceFromLatLon(lat1, lon1, lat2, lon2) {
    var R = 6371; // Radius of the earth in km
    var dLat = deg2rad(lat2 - lat1); // deg2rad below
    var dLon = deg2rad(lon2 - lon1);
    var a = sin(dLat / 2) * sin(dLat / 2) + cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    var d = (R * c) * 1000; // Distance in meter
    if (d > 1000) return "${(d / 1000).toStringAsFixed(2)} km away";
    return "${d.toStringAsFixed(2)} m away";
  }

  // endregion

  // region deg2rad
  static double deg2rad(double deg) {
    return (deg * pi / 180.0);
  }

  // endregion

  // region showMessage
  static void showMessage(BuildContext context, String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

// endregion

  // region getBytesFromAsset
  static Future<Uint8List?> getBytesFromAsset(String path, int size) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetHeight: size, targetWidth: size);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))?.buffer.asUint8List();
  }

// endregion

  // region boundsFromLatLngList
  static LatLngBounds getBoundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

// endregion

  // region get Duration
  static String getDuration(int? millisecondsSinceEpoch) {
    if (millisecondsSinceEpoch == null) return "Not Detected";

    // get difference
    DateTime date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    var milliSecondsDifference = DateTime.now().difference(date).inMilliseconds;

    // get duration
    int seconds = milliSecondsDifference ~/ 1000;
    int minutes = ((milliSecondsDifference / (1000 * 60)) % 60).toInt();
    int hours = milliSecondsDifference ~/ (1000 * 60 * 60);
    int day = milliSecondsDifference ~/ (1000 * 60 * 60 * 24);

    // get time
    if (hours > 24) return "${day}d ago";
    if (hours > 1) return "${hours}h ago";
    if (seconds > 60) return "${minutes}m ago";
    if (seconds > 1) return "${seconds}s ago";
    return "now";
  }

// endregion
}
