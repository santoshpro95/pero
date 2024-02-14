class UserDataResponse {
  String? userName;
  double? lat;
  double? lng;
  int? updatedTime;
  String? room;
  String? message;
  num? xPoint;
  num? yPoint;
  String? drawState;
  int? playerDuration;
  String? playerUrl;
  int? color;
  UserDataResponse({this.userName, this.lat, this.lng, this.updatedTime, this.room, this.message, this.xPoint, this.yPoint, this.drawState, this.playerDuration, this.playerUrl, this.color});

  UserDataResponse.fromJson(Map<String, dynamic> json) {
    userName = json['userName'];
    lat = json['lat'];
    lng = json['lng'];
    updatedTime = json['updatedTime'];
    room = json['room'];
    message = json['message'];
    xPoint = json['xPoint'];
    yPoint = json['yPoint'];
    drawState = json['state'];
    playerDuration = json['playerDuration'];
    playerUrl = json['playerUrl'];
    color = json['color'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userName'] = this.userName;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['updatedTime'] = this.updatedTime;
    data['room'] = this.room;
    data['message'] = this.message;
    data['xPoint'] = this.xPoint;
    data['yPoint'] = this.yPoint;
    data['state'] = this.drawState;
    data['playerDuration'] = this.playerDuration;
    data['playerUrl'] = this.playerUrl;
    data['color'] = this.color;
    return data;
  }
}
