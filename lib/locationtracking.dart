import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denah_test/functions/functions.dart';
import 'package:denah_test/home.dart';
import 'package:denah_test/models/wifidata.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';

class LocationTracking extends StatefulWidget {
  final String end;
  const LocationTracking({ Key? key, required this.end}) : super(key: key);

  @override
  State<LocationTracking> createState() => _LocationTrackingState();
}

class _LocationTrackingState extends State<LocationTracking> {
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  StreamSubscription<Result<List<WiFiAccessPoint>, GetScannedResultsErrors>>? subscription;

  FirebaseFirestore db = FirebaseFirestore.instance;
  bool get isStreaming => subscription != null;

  List<WifiData> wifiList = [];
  List<Map<String, dynamic>> nodeData = [];
  List<double>? _magnetometerValues;
  List<String> possibleLocation = [];

  String foundLocation = "";

  bool _isLoading = true, _dataLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getWifiDataFromFirebase();
    getNodeDataFromFirebase("P");
  }

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 5), () {
      _scan();
    });

    _streamSubscriptions.add(
      magnetometerEvents.listen(
        (MagnetometerEvent event) {
          setState(() {
            _magnetometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
  }

  void getWifiDataFromFirebase() async{
    await db.collection("wifi_location").get().then((event) {
      for (var doc in event.docs) {
        wifiList.add(
          WifiData(
            ssid: doc.data()['ssid'] ?? "", 
            bssid: doc.data()['bssid'] ?? "",
            level: doc.data()['level'] ?? "",
            building: doc.data()['building'] ?? "",
            link: doc.data()['link'] ?? [],
          )
        );
      }

      setState(() {
        _dataLoading = false;
      });
    });
  }

  void getNodeDataFromFirebase(String building) async{
    await db.collection("map_node").doc(building).collection("nodes").get().then((event) {
      for (var doc in event.docs) {
        nodeData.add(doc.data());
        nodeData.last['id'] = doc.id;
      }
    });
  }

  void _scan() async {
    if(await WiFiScan.instance.hasCapability()){
      // can safely call scan related functionalities
      _startScan();
    } else {
      // fallback mechanism, like - show user that "scan" is not possible 
    }
  }

  void _startScan() async {
  // start full scan async-ly
    final error = await WiFiScan.instance.startScan(askPermissions: true);
    if (error != null) {
      switch(error) {
        // handle error for values of StartScanErrors
        case StartScanErrors.notSupported:
          print("Scan not supported");
          break;
        case StartScanErrors.noLocationPermissionRequired:
          print("Permission required");
          break;
        case StartScanErrors.noLocationPermissionDenied:
          print("Permission denied");
          break;
        case StartScanErrors.noLocationPermissionUpgradeAccuracy:
          print("Permission denied");
          break;
        case StartScanErrors.noLocationServiceDisabled:
          print("Location disabled");
          break;
        case StartScanErrors.failed:
          print("Scan failed");
          break;
      }
    } else {
      _getScannedResults();
    }
  }

   _getScannedResults() async {
    // get scanned results
    final result = await WiFiScan.instance.getScannedResults(askPermissions: true);

    if (result.hasError){
      // switch (error){
      //   // handle error for values of GetScannedResultErrors
      // }
    } else {
      final accessPoints = result.value;
      estimateWifiLocation(accessPoints!);
    }
  }

  bool checkRssiRadius(String source, String data){
    var sourceDouble = double.parse(source);
    var dataDouble = double.parse(data);

    //radius +5 -5
    if(sourceDouble <= (dataDouble + 10) && sourceDouble >= (dataDouble - 10)){
      return true;
    }

    return false;
  }

  bool checkDuplicate(String data){
    for(var x in possibleLocation){
      if(x == data){
        return true;
      }
    }

    return false;
  }

  Widget estimateWifiLocation(List<WiFiAccessPoint> aps){
    possibleLocation.clear();

    for(var ap in aps){
      for(var data in wifiList){
        if(data.bssid == ap.bssid){
          for(var x in data.link){
            //recheck
            if(checkRssiRadius(ap.level.toString(), x['rssi'].toString())){
              if(!checkDuplicate(x['node_id'].toString())){
                possibleLocation.add(x['node_id'].toString());
              }
            }
          }
        }
      }
    }
    
    //dummy ruang dosen
    // possibleLocation.add("3P-8R");
    // possibleLocation.add("3P-16P");
    // possibleLocation.add("3P-18P");

    //dummy ruang dosen lain
    // possibleLocation.add("3P-15R");
    // possibleLocation.add("3P-25P");
    // possibleLocation.add("3P-30P");
    // possibleLocation.add("3P-31P");

    if(possibleLocation.isEmpty){
      setState(() {
        _isLoading = false;
      });
    } else{
      // estimateGeomagLocation(possibleLocation);
      setState(() {
        _isLoading = false;
      });
    }

    return Container();
  }

  Widget estimateGeomagLocation(List<String> possibleLocation){
    final magnetometer = _magnetometerValues?.map((double v) => v.toStringAsFixed(1)).toList();

    double xTotal = pow(double.parse(magnetometer![0]), 2).toDouble();
    double yTotal = pow(double.parse(magnetometer[1]), 2).toDouble();
    double zTotal = pow(double.parse(magnetometer[2]), 2).toDouble();

    double totalMagneticValue = sqrt(xTotal + yTotal + zTotal);
    
    String possibleLevel = splitStringLevel(possibleLocation[0]);
    String possibleBuilding = splitStringBuilding(possibleLocation[0]);

    // getNodeDataFromFirebase(possibleBuilding, possibleLevel);

    for(var node in nodeData){
      // recheck
      if(double.parse(node['mag'].toString()) == totalMagneticValue){
        setState(() {
          _isLoading = false;
          foundLocation = node['id'].toString();
        });
      }
    }
    return Container();
  }

  String findRoomNameById(String id){
    for(var x in nodeData){
      if(x['id'] == id && x['room'] == true){
        return x['tooltip'];
      }
    }

    return id;
  }

  List<Widget> locationOptionWidget(){
    List<Widget> widgetList = [];

    for(var x in possibleLocation){
      widgetList.add(
        SimpleDialogOption(
          onPressed: () { 
            navigateTo(context, MyHomePage(value: splitStringBuilding(x), start: x, end: widget.end, mode: 1,));
          },
          child: Text(findRoomNameById(x)),
        )
      );
    }

    return widgetList;
  }

  @override
  void dispose() {
    super.dispose();
    
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracking location"),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : possibleLocation.isEmpty ? AlertDialog(
            title: const Text("Location not found in database"),
            actions: <Widget>[
              TextButton(
                child: const Text("Back"),
                onPressed: () {
                  navigateBack(context);
                },
              ),
            ],
          )
          // :  AlertDialog(
          //     title: const Text("Your location estimation"),
          //     content: SingleChildScrollView(
          //       child: ListBody(
          //         children: <Widget>[
          //           Text("Based on gathered data : $foundLocation"),
          //           Text("Building : P"),
          //           Text("Floor : 1"),
          //           Text("Path : true"),
          //         ],
          //       ),
          //     ),
          //     actions: <Widget>[
          //       TextButton(
          //         child: const Text("Navigate"),
          //         onPressed: () {
          //           navigateTo(context, MyHomePage(value: splitStringBuilding(foundLocation), start: foundLocation, end: widget.end, mode: 1,));
          //         },
          //       ),
          //     ],
          //   ),
            : SimpleDialog(
                title: const Text("Select your closest location"),
                children: <Widget>[
                  ...locationOptionWidget()
                ],
              )
    );
  }
}