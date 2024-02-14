import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pero/features/location/location_bloc.dart';
import 'package:pero/model/users_response.dart';
import 'package:pero/utils/app_images.dart';
import 'package:pero/utils/common_methods.dart';

// region LocationScreen
class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}
// endregion

class _LocationScreenState extends State<LocationScreen> {
  // region Bloc
  late LocationBloc locationBloc;

  // endregion

  // region Init
  @override
  void initState() {
    locationBloc = LocationBloc(context);
    locationBloc.init();
    super.initState();
  }

  // endregion

  // region dispose
  @override
  void dispose() {
    locationBloc.dispose();
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
            stream: locationBloc.userDetailsCtrl.stream,
            builder: (context, snapshot) {
              return Text("Location on Room No - ${locationBloc.userRoom}");
            }),
      ),
      body: body(),
    );
  }

  // endregion

  // region body
  Widget body() {
    return Column(
      children: [connection(), googleMap(), users()],
    );
  }

  // endregion

  // region users
  Widget users() {
    return Container(
      color: Colors.black,
      height: 120,
      width: double.maxFinite,
      child: StreamBuilder<bool>(
          stream: locationBloc.mapLoadingCtrl.stream,
          builder: (context, snapshot) {
            return Center(
              child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => userItem(locationBloc.users[index]),
                  itemCount: locationBloc.users.length),
            );
          }),
    );
  }

  // endregion

  // region userItem
  Widget userItem(UserDataResponse userDataResponse) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 20),
      onPressed: () => locationBloc.onTapUser(userDataResponse),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Expanded(child: Image.asset(AppImages.marker, color: Colors.white, height: 40)),
            const SizedBox(height: 5),
            Text(locationBloc.getUserInfo(userDataResponse), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // endregion

  // region connection
  Widget connection() {
    return StreamBuilder<bool>(
        stream: locationBloc.connectCtrl.stream,
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

  // region Google Map
  Widget googleMap() {
    return Expanded(
      child: StreamBuilder<bool>(
          stream: locationBloc.mapLoadingCtrl.stream,
          builder: (context, snapshot) {
            return GoogleMap(
                zoomGesturesEnabled: true,
                mapType: MapType.normal,
                initialCameraPosition: locationBloc.initialCameraPosition,
                myLocationEnabled: true,
                compassEnabled: true,
                myLocationButtonEnabled: true,
                tiltGesturesEnabled: true,
                markers: locationBloc.markers,
                onMapCreated: (GoogleMapController controller) {
                  if (!locationBloc.controller.isCompleted) {
                    locationBloc.controller.complete(controller);
                  }
                });
          }),
    );
  }

// endregion
}
