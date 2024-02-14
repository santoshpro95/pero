import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pero/model/users_response.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:pero/services/cache_storage/cache_storage_service.dart';
import 'package:pero/services/cache_storage/storage_keys.dart';
import 'package:pero/utils/app_constants.dart';
import 'package:pero/utils/app_images.dart';
import 'package:pero/utils/common_methods.dart';
import 'package:geolocator/geolocator.dart' as locator;

class LocationBloc {
  // region Common Variables
  BuildContext context;
  List<UserDataResponse> users = [];
  late Position currentLocation;
  late IO.Socket socket;
  var userName = "Loading...";
  var userRoom = "";
  late Timer timer;

  // endregion

  // region Services
  CacheStorageService cacheStorageService = CacheStorageService();
  Location location = Location();

  // endregion

  // region Google Map
  Completer<GoogleMapController> controller = Completer();
  static const indiaMap = LatLng(22.3434534, 77.45345);
  CameraPosition initialCameraPosition = const CameraPosition(target: indiaMap);
  GoogleMapController? googleMapController;

  // endregion

  // region marker
  Set<Marker> markers = HashSet<Marker>();
  List<LatLng> allPoints = [];
  Uint8List? markerIcon;

  // endregion

  // region Controllers
  final mapLoadingCtrl = StreamController<bool>.broadcast();
  final connectCtrl = StreamController<bool>.broadcast();
  final userDetailsCtrl = StreamController<bool>.broadcast();

  // endregion

  // region | Constructor |
  LocationBloc(this.context);

  // endregion

  // region init
  void init() async {
    // get current location
    currentLocation = await locator.Geolocator.getCurrentPosition();

    // initialise Map Controller
    googleMapController = await controller.future;

    // getUserDetails
    getUserDetails();

    // enable background location
    location.enableBackgroundMode(enable: true);

    // listen location
    location.onLocationChanged.listen((LocationData location) {
      sendLocationData(location.latitude!, location.longitude!);
    });

    // connectAndListen
    connectAndListen();

    // zoom to current location
    await googleMapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(currentLocation.latitude, currentLocation.longitude), 21));

    // clear data in every 2 minutes
    timer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      // get current location
      currentLocation = await locator.Geolocator.getCurrentPosition();

      // get bound
      var allPoints = users.map((e) => LatLng(e.lat ?? 0, e.lng ?? 0)).toList();
      var visibleBound = CommonMethods.getBoundsFromLatLngList(allPoints);

      // refresh map
      if (!mapLoadingCtrl.isClosed) {
        // zoom to visible bound
        if (googleMapController == null) return;
        await googleMapController?.animateCamera(CameraUpdate.newLatLngBounds(visibleBound, 100));

        // refresh map
        mapLoadingCtrl.sink.add(true);
      }
    });
  }

  // endregion

  // region send Location Data
  void sendLocationData(double lat, double lng) {
    UserDataResponse userDataResponse = UserDataResponse();
    userDataResponse.userName = userName;
    userDataResponse.lat = lat;
    userDataResponse.lng = lng;
    userDataResponse.updatedTime = DateTime.now().millisecondsSinceEpoch;
    userDataResponse.room = userRoom;

    // generate userInfo
    var userInfo = userDataResponse.toJson();
    socket.emit("event", userInfo);
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

  // region onDeniedLocationPermission
  void onDeniedLocationPermission() {
    // open setting
    //openAppSettings();
  }

  // endregion

  // region connectAndListen
  void connectAndListen() {
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

    // get data
    socket.on("getData", (data) => getUpdatedUsers(data));

    // send current location
    sendLocationData(currentLocation.latitude, currentLocation.longitude);

    // get usersData
    getUsersData();
  }

  // endregion

  // region getUpdatedUsers
  void getUpdatedUsers(userData) async {
    // get userDetails
    var data = UserDataResponse.fromJson(userData);

    // check room
    if (data.room != userRoom) return;

    // check if name already exist
    var user = users.firstWhere((element) => element.userName == data.userName, orElse: () => UserDataResponse());
    if (user.userName == null) {
      // add new user
      users.add(data);
    } else {
      // replace data
      var getIndex = users.indexWhere((element) => element.userName == data.userName);

      // update data
      users[getIndex].updatedTime = data.updatedTime;
      users[getIndex].lat = data.lat;
      users[getIndex].lng = data.lng;
    }

    // get usersData
    getUsersData();
  }

  // endregion

  // region getUsersData
  void getUsersData() async {
    try {
      // generate custom marker
      markerIcon = await CommonMethods.getBytesFromAsset(AppImages.marker, 100);

      // add markers
      addMarkers(users);
    } catch (exception) {
      CommonMethods.showMessage(context, exception.toString());
    }
  }

  // endregion

  // region onTapUser
  void onTapUser(UserDataResponse users) async {
    // zoom to coordinator
    await googleMapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(users.lat ?? 0, users.lng ?? 0), 21));

    // get marker id
    MarkerId markerId = MarkerId('${users.lat ?? 0}' '${users.lng ?? 0}');

    // open info window
    await googleMapController?.showMarkerInfoWindow(markerId);
  }

  // endregion

  // region addMarkers
  void addMarkers(List<UserDataResponse> users) async {
    if (users.isEmpty) return;

    // clear all markers
    markers.clear();

    // generate map markers
    for (var user in users) {
      var marker = getMarker(users: user);
      markers.add(marker);
    }

    // refresh map
    if (!mapLoadingCtrl.isClosed) mapLoadingCtrl.sink.add(true);
  }

  // endregion

  // region GetMarker
  Marker getMarker({required UserDataResponse users}) {
    // get marker Id
    MarkerId markerId = MarkerId('${users.lat ?? 0}' '${users.lng ?? 0}');

    // get position
    var position = LatLng(users.lat ?? 0, users.lng ?? 0);

    // return marker
    return Marker(
        draggable: false,
        consumeTapEvents: false,
        icon: BitmapDescriptor.fromBytes(markerIcon!),
        visible: true,
        infoWindow: infoWindow(users),
        anchor: const Offset(0.5, 0.5),
        markerId: markerId,
        position: position);
  }

  // endregion

  // region info Window
  InfoWindow infoWindow(UserDataResponse users) {
    var name = users.userName == userName ? "Me" : users.userName;
    return InfoWindow(title: name, onTap: () {});
  }

  // endregion

  // region get User Info
  String getUserInfo(UserDataResponse userDataResponse) {
    var name = userDataResponse.userName == userName ? "Me" : userDataResponse.userName;
    var distance = userDataResponse.userName == userName
        ? "Current location"
        : CommonMethods.getDistanceFromLatLon(currentLocation.latitude, currentLocation.longitude, userDataResponse.lat!, userDataResponse.lng!);
    var time = CommonMethods.getDuration(userDataResponse.updatedTime ?? 0);
    return "$name\n$distance\n($time)";
  }

  // endregion

  // region dispose
  void dispose() {
    mapLoadingCtrl.close();
    connectCtrl.close();
    socket.disconnect();
    socket.dispose();
    connectCtrl.close();
  }
// endregion
}
