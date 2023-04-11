import 'package:denah_test/locationtracking.dart';
import 'package:denah_test/models/mapobject.dart';
import 'package:flutter/material.dart';

void navigateTo(BuildContext context, Widget build){
  Navigator.push(context, 
    MaterialPageRoute(builder: (context) => build)
  );
}

void navigateBack(BuildContext context){
  Navigator.pop(context);
}

MapObject? findUser(List<MapObject> listNodes){
  for(var x in listNodes){
    if(x.id == "0"){
      return x;
    }
  }
  return null;
}

findNodeByName(String name, List<dynamic> listNode, int type){
  // 0-> nodeObjects, 1-> nodeListPath
  if(type == 0){
    for(var x in listNode){
      if(x.id == name){
        return x;
      }
    }
  } else if(type == 1){
    for(var x in listNode){
      if(x.name == name){
        return x;
      }
    }
  }
}

String splitStringBuilding(String text){
  var split1 = text.split("-");
  var split2 = split1[0].split("");

  return split2.last;
}

String splitStringLevel(String text){
  var split1 = text.split("-");
  var split2 = split1[0].split("");

  if(split2.length == 2){
    return split2.first;
  } else {
    return split2[0] + split2[1];
  }
}

void showPlaceDialog(BuildContext context, MapObject obj, bool status) async {
  var tempSplit = obj.tooltip.message.split("");
  var moreInfo = "";

  if(obj.level == "1"){
    moreInfo = "${tempSplit[0]} building - ${obj.level}st floor";
  } else if(obj.level == "2"){
    moreInfo = "${tempSplit[0]} building - ${obj.level}nd floor";
  } else if(obj.level == "3"){
    moreInfo = "${tempSplit[0]} building - ${obj.level}rd floor";
  } else {
    moreInfo = "${tempSplit[0]} building - ${obj.level}th floor";
  }
  
  return showDialog<void>(
    context: context,
    // barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog( 
        title: const Text('Place info'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(obj.tooltip.message),
              Text(moreInfo),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: status ? const Text("Cancel") : const Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          status ? TextButton(
            child: const Text('Navigate'),
            onPressed: () {
              Navigator.of(context,rootNavigator: true).popUntil(ModalRoute.withName('/'));
              navigateTo(context, LocationTracking(end: obj.id));
            },
          ) : const SizedBox(),
        ],
      );
    },
  );
}

String timeNow(){
  int timestamp = DateTime.now().millisecondsSinceEpoch;
  DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);

  String time = "";

  if(tsdate.hour.toString().length == 1){
    time += "0${tsdate.hour.toString()}";
  } else {
    time += tsdate.hour.toString();
  }
  if(tsdate.minute.toString().length == 1){
    time += ":0${tsdate.minute.toString()}";
  } else {
    time += ":${tsdate.minute.toString()}";
  }

  return time;
}

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}