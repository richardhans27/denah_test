import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denah_test/functions/functions.dart';
import 'package:denah_test/functions/zoomcontainer.dart';
import 'package:denah_test/models/mapobject.dart';
import 'package:denah_test/models/node.dart';
import 'package:denah_test/models/nodeinfo.dart';
import 'package:denah_test/functions/shortestpath.dart';
import 'package:denah_test/models/userposition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_barometer_plugin/flutter_barometer.dart';


class MyHomePage extends StatefulWidget {
  final String value, start, end;
  final int mode;
  const MyHomePage({ Key? key, required this.value, this.start = "", this.end = "", this.mode = 0}) : super(key: key);
 
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final double GRAVITATIONAL_FORCE = 9.80665;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  CarouselController carouselController = CarouselController();
  int mode = 0;
  String start = "", end = "";

  BarometerValue _currentPressure = BarometerValue(0.0);
  double curAlt = 0;

  FirebaseFirestore db = FirebaseFirestore.instance;

  // sensors
  List<double>? _accelerometerValues;
  List<double>? _userAccelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;

  double totalAccelerationValue = 0.0;

  // Node objects
  List<Map<String, dynamic>> nodeData = [];
  List<Map<String, dynamic>> altitudeData = [];
  List<MapObject> nodeObjects = [];
  List<MapObject> nodeByLevel = [];
  List<MapObject> oldNodeObjects = [];
  List<Node> nodeListPath = [];
  List<Node> nodeListPathTemp = [];
  List<String> floorList = [];
  List<MapObject> pathResult = [];
  Iterable<Node> routeResult = [];

  //user related
  late MapObject? user;
  late UserPosition position;
  late double angle;
  late String level;

  String? selectedValue;
  int val = -1;
  int floorCount = 0;
  bool _hasPermissions = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    getFloorDataFromFirebase();
    getNodeDataFromFirebase();
    getAltitudeDataFromFirebase();
  }

  @override
  void initState(){
    super.initState();
    
    _fetchPermissionStatus();

    setState(() {
      mode = widget.mode;
      if(mode == 1){
        start = widget.start;
        end = widget.end;

        selectedValue = splitStringLevel(start);

        initializeSensors();
        initializeUser();

        curAlt = calculateAltitude();
      }
    });

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      setState(() {
        carouselController.jumpToPage(int.parse(selectedValue!) - 1);
      });
    });
  }

  void getFloorDataFromFirebase() async {
    await db.collection("building_info").get().then((event) {
      for (var doc in event.docs) {
        if(doc.data()["name"].toString() == widget.value){
          floorCount = int.parse(doc.data()["floors"]);
          break;
        }
      }

      for(int i = 1; i <= floorCount; i++){
        floorList.add(i.toString());
      }
      setState(() {
        if(mode != 1){
          selectedValue = floorList[0].toString();
        }
      });
    });
  }

  void getNodeDataFromFirebase() async{
    await db.collection("map_node").doc(widget.value).collection("nodes").get().then((event) {
      for (var doc in event.docs) {
        nodeData.add(doc.data());
        nodeData.last['id'] = doc.id;
      }
      assignNodeToGraph();
      assignNodeToMap();
    });
  }

  void getAltitudeDataFromFirebase() async{
    await db.collection("map_node").doc(widget.value).collection("altitude").get().then((event) {
      for (var doc in event.docs) {
        altitudeData.add(doc.data());
      }
    });
  }

  void initializeSensors(){
    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          setState(() {
            _gyroscopeValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          setState(() {
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      magnetometerEvents.listen(
        (MagnetometerEvent event) {
          setState(() {
            _magnetometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );

    FlutterBarometer.currentPressureEvent.listen((event) {
      setState(() {
        _currentPressure = event;
      });
    });
  }

  void initializeUser(){
    position = UserPosition(offsetX: 1, offsetY: 1);
    level = "1"; // dummy
    angle = 0;
    
    user = MapObject(
      id: "0",
      child: const Icon(Icons.arrow_upward, size: 25,),
      offset: Offset(position.offsetX, position.offsetY),
      size: const Size(20, 20),
      angle: angle,
      level: level,
      tooltip: NodeInfo(message: 'This is the user', status: true)
    );
  }

  void addDataToFirebase() {
    int pathCounter = 1, roomCounter = 1;
    List<MapObject> tempNodeObjects = [];
    
    tempNodeObjects = nodeByLevel.where((e) => !oldNodeObjects.contains(e)).toList();

    print(tempNodeObjects.length);

    tempNodeObjects.asMap().forEach((index, value) {
      final temp = <String, dynamic>{
        "angle": "0",
        "level": selectedValue.toString() == '' ? "0" :selectedValue.toString(),
        "offset_x": value.offset.dx.toString() == '' ? "0" : value.offset.dx.toString(),
        "offset_y": value.offset.dy.toString() == '' ? "0" : value.offset.dy.toString(),
        "path": val == 2 ? true : false,
        "room": val == 1 ? true : false,
        "tooltip": value.tooltip.message.toString(),
      };

      if(temp['path'] == true){
        db.collection("map_node").doc(widget.value).collection("nodes").doc("$selectedValue${widget.value}-${pathCounter}P").set(temp).then((doc){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Node successfully added"),
            ));
          },
        );
        pathCounter++;
      } else if(temp['room'] == true){
        db.collection("map_node").doc(widget.value).collection("nodes").doc("$selectedValue${widget.value}-${roomCounter}R").set(temp).then((doc){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Node successfully added"),
            ));
          }
        );
        roomCounter++;
      }
    });
  }

  void assignNodeToMap(){
    nodeObjects.clear();

    for(var x in nodeData){
      var temp = MapObject(
        id: x['id'],
        child: x['room'] ?? false ? const Icon(Icons.meeting_room_outlined, size: 15,) : const Icon(Icons.circle_outlined, size: 12,),
        offset: Offset(double.parse(x['offset_x'] ?? "0"), double.parse(x['offset_y'] ?? "0")),
        size: const Size(10, 10),
        angle: double.parse(x['angle'] ?? "0"),
        level: x['level'] ?? "0",
        tooltip: NodeInfo(message: x['tooltip'] ?? ""),
        status: x['status'] ?? true,
        room: x['room'] ?? false,
        path: x['path'] ?? false,
        stairs: x['stairs'] ?? false,
        lift: x['lift'] ?? false,
      );

      nodeObjects.add(temp);
      nodeObjects.last.tooltip.status = nodeObjects.last.tooltip.message != "" ? true : false;
    }

    // dummy start node
    if(mode == 1){
      calculatePath(start, end);
      user?.offset = findNodeByName(start, nodeObjects, 0).offset;
      user?.level = findNodeByName(start, nodeObjects, 0).level;
    }
    
    assignNodesByLevel();
  }

  void assignNodeToGraph(){
    nodeListPath.clear();

    for(var x in nodeData){
      var temp = "";
      if(x['stairs'] == true){
        temp = "stairs";
      } else if(x['lift'] == true){
        temp = "lift";
      } else if(x['room'] == true){
        temp = "room";
      } else {
        temp = "path";
      }

      nodeListPath.add(
        Node(name: x['id'], type: temp, neighbors: [])
      );

    }

    for(var x in nodeData){
      if(x['link'] != null){
        for(var y in nodeListPath){
          if(y.name == x['id'].toString()){
            // print(y.name);
            for(var z in x['link']){
              y.addNeighbor(findNodeByName(z, nodeListPath, 1));
            }
          }
        }
      }
    }

    nodeListPathTemp = nodeListPath;
  }

  void assignNodesByLevel(){
    nodeByLevel.clear();
    oldNodeObjects.clear();

    for(var node in nodeObjects){
      if(node.level == selectedValue){
        nodeByLevel.add(node);
        
        oldNodeObjects.add(node);
      }
    }

    if(mode == 1){
       //assign user to map
      if(user?.level == selectedValue){
        nodeByLevel.add(user!);
      }

      //if there's path calculated
      for(var x in pathResult){
        if(x.level == selectedValue){
          nodeByLevel.add(x);
        }
      } 
    }
  }

  void calculatePath(String start, String finish){
    // nodeListPath.clear();
    // for(var x in nodeListPathTemp){
    //   nodeListPath.add(x);
    // }

    Node startNode = findNodeByName(start, nodeListPath, 1);
    Node endNode = findNodeByName(finish, nodeListPath, 1);

    // print("${startNode.name} - ${startNode.visited}");
    // print(endNode.name);

    // routeResult = [];
    // print(routeResult.length);
    routeResult = ShortestPath(start: startNode, end: endNode).pathSearch();
    // print(routeResult.first.name);
    getPathNodes(routeResult);

    var temp = findNodeByName(finish, nodeObjects, 0);
    temp.child = temp.room ? const Icon(Icons.place, size: 25, color: Colors.red,) : const Icon(Icons.circle, size: 20, color: Colors.red,);
  }

  String estimateTime([String passed = ""]){
    int estimatedTime = 0;

    if(passed != ""){
      for(var i = 0; i < routeResult.length; i++){
        if(passed == routeResult.elementAt(i).name){
          routeResult.elementAt(i).name = "passed";
        }
      }
    }

    for(var x in routeResult){
      if(x.name != start){
        if(x.name != "passed"){
          if(x.type == "stairs"){
            estimatedTime += 8;
          } else if(x.type == "lift"){
            estimatedTime += 12;
          } else {
            estimatedTime += 5;
          }
        }
      }
      
    }
    
    String text = "";
    if(estimatedTime >= 60){
      int modTime = estimatedTime % 60;
      int divideTime = (estimatedTime - modTime) ~/ 60;

      text += "${divideTime}m ";
      if(modTime > 0){
        text += "${modTime}s";
      }
    } else {
      text += "${estimatedTime}s";
    }

    if(text != "0s" && passed != end){
      return text;
    } else{
      // _showDialog();
      return "Reached destination";
    }
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Routing complete'),
          content: Text('You have reached your destination -> $end'),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Navigator.of(context,rootNavigator: true).popUntil(ModalRoute.withName('/'));
              },
              child: Text('Back'))
          ],
        );
      },
    );
  }

  void getPathNodes(Iterable<Node> listNode) {
    pathResult.clear();

    for(int i = 0; i < listNode.length - 1; i++){
      MapObject start = findNodeByName(listNode.elementAt(i).name, nodeObjects, 0);
      MapObject end = findNodeByName(listNode.elementAt(i+1).name, nodeObjects, 0);

      if(start.stairs && end.stairs){
        var temp = MapObject(
          id: "1",
          child: const Icon(Icons.stairs_rounded, size: 20, color: Colors.blueAccent,),
          offset: start.offset,
          size: const Size(10, 10),
          angle: 0,
          level: start.level,
          tooltip: NodeInfo(message: '', status: false)
        );

        var temp1 = MapObject(
          id: "1",
          child: const Icon(Icons.stairs_rounded, size: 20, color: Colors.blueAccent,),
          offset: end.offset,
          size: const Size(10, 10),
          angle: 0,
          level: end.level,
          tooltip: NodeInfo(message: '', status: false)
        );

        pathResult.add(temp);
        pathResult.add(temp1);
        
      } else if(start.lift && end.lift){
        var temp = MapObject(
          id: "1",
          child: const Icon(Icons.elevator, size: 20, color: Colors.blueAccent,),
          offset: start.offset,
          size: const Size(10, 10),
          angle: 0,
          level: start.level,
          tooltip: NodeInfo(message: '', status: false)
        );

        var temp1 = MapObject(
          id: "1",
          child: const Icon(Icons.elevator, size: 20, color: Colors.blueAccent,),
          offset: end.offset,
          size: const Size(10, 10),
          angle: 0,
          level: end.level,
          tooltip: NodeInfo(message: '', status: false)
        );

        pathResult.add(temp);
        pathResult.add(temp1);
        
      }
      else {
        double diffX = end.offset.dx - start.offset.dx;
        double diffY = end.offset.dy - start.offset.dy;

        double tempMinX = diffX / 5;
        double tempMinY = diffY / 5;

        //startX, startY -> starting point
        double startX = start.offset.dx;
        double startY = start.offset.dy;

        //finish point
        double finX = end.offset.dx;
        double finY = end.offset.dy;

        for(int i = 0; i < 4; i++){  
          startX += tempMinX;
          startY += tempMinY;
          
          var temp = MapObject(
            id: "1",
            child: const Icon(Icons.circle, size: 8, color: Colors.blueAccent,),
            offset: Offset(startX, startY),
            size: const Size(10, 10),
            angle: 0,
            level: start.level,
            tooltip: NodeInfo(message: '', status: false)
          );
          pathResult.add(temp);
        }
      }
    }
  }


  void userMovement() async{
    // final accelerometer = _accelerometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    // final gyroscope = _gyroscopeValues?.map((double v) => v.toStringAsFixed(1)).toList();
    // final userAccelerometer = _userAccelerometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    // final magnetometer = _magnetometerValues?.map((double v) => v.toStringAsFixed(1)).toList();

    final CompassEvent tmp = await FlutterCompass.events!.first;

    // print(userAccelerometer);

    // double xTotal = pow(_userAccelerometerValues![0], 2).toDouble();
    double yTotal = pow(_userAccelerometerValues![1], 2).toDouble();
    double zTotal = pow(_userAccelerometerValues![2], 2).toDouble();
    totalAccelerationValue = sqrt(0 + yTotal + zTotal);

    // print(_currentPressure.hectpascal);

    setState(() {
      user?.angle = (tmp.heading! * (pi / 180));

      double newUserPosX = user!.offset.dx + calculateMovement(tmp.heading!, "x", totalAccelerationValue / 1200);
      double newUserPosY = user!.offset.dy + calculateMovement(tmp.heading!, "y", totalAccelerationValue / 1200);

      user?.offset = Offset(newUserPosX, newUserPosY);

      for(var x in nodeObjects){
        if(x.level == selectedValue){
          if(user!.offset.dx >= (x.offset.dx-0.04) && user!.offset.dx <= (x.offset.dx+0.04)){
            if(user!.offset.dy >= (x.offset.dy-0.04) && user!.offset.dy <= (x.offset.dy+0.04)){

              if(x.id != start){
                // print("inside ${x.id}");
                setState(() {
                  estimateTime(x.id);
                  // start = x.id;
                  // calculatePath(start, end);
                  // assignNodesByLevel();
                });

                // print("route result -> ${routeResult.first.name}");
              }
              break;
            }
          }
        }
      }

      // check altitude changes
      var currentAltitude = calculateAltitude();

      if(currentAltitude >= (curAlt - 2) && currentAltitude <= (curAlt + 2)){} 
      else{
        //level down
        if(currentAltitude.floorToDouble() <= (curAlt - 4) ){
          setState(() {
            curAlt = currentAltitude.floorToDouble();
            var curLevel = int.parse(selectedValue!) - 1;
            user?.level = curLevel.toString();
            selectedValue = curLevel.toString();
            carouselController.jumpToPage(curLevel - 1);
            assignNodesByLevel();
          });
        } 
        //level up
        else if(currentAltitude.floorToDouble() >= (curAlt + 4)){
          setState(() {
            curAlt = currentAltitude.floorToDouble();
            var curLevel = int.parse(selectedValue!) + 1;
            user?.level = curLevel.toString();
            selectedValue = curLevel.toString();
            carouselController.jumpToPage(curLevel - 1);
            assignNodesByLevel();
          });
        }
      }
      

      // for(var x in altitudeData){
      //   if(currentAltitude >= double.parse(x['min'].toString()) && 
      //     currentAltitude <= double.parse(x['max'].toString())){ // floor level change

      //     if(x['level'].toString() == selectedValue){
      //       break;
      //     } 
      //     else {
      //       setState(() {
      //         user?.level = x['level'].toString();
      //         selectedValue = x['level'].toString();
      //         carouselController.jumpToPage(int.parse(selectedValue!) - 1);
      //         assignNodesByLevel();
      //       });

      //       break;
      //     }
      //   }
      // }
      
    });
  }

  double calculateAltitude(){
    return double.parse((((pow((1013.25 / _currentPressure.hectpascal), (1 / 5.275)) - 1) * (28 + 273.15)) / 0.0065).toStringAsFixed(4));
  }

  double calculateMovement(double heading, String type, double temp){
    if(heading > 0 && heading < 80){
      if(type == "x"){
        return temp;
      } else {
        return temp * -1;
      }
    } else if(heading > 90 && heading < 170){
      if(type == "x"){
        return temp;
      } else {
        return temp;
      }
    } else if(heading > 180 && heading < 260){
      if(type == "x"){
        return temp * -1;
      } else {
        return temp;
      }
    } else if(heading > 270 && heading < 350){
      if(type == "x"){
        return temp * -1;
      } else {
        return temp * -1;
      }
    } 
    
    else if(heading >= 80 && heading <= 90){
      if(type == "x"){
        return temp;
      } else {
        return 0;
      }
    } else if(heading >= 170 && heading <= 180){
      if(type == "x"){
        return 0;
      } else {
        return temp;
      }
    } else if(heading >= 260 && heading <= 270){
      if(type == "x"){
        return temp * -1;
      } else {
        return 0;
      }
    } else if(heading >= 350 && heading <= 0){
      if(type == "x"){
        return 0;
      } else {
        return temp * -1;
      }
    }
    return 0;
  }

  List<Widget> getFloorWidgets(){
    List<Widget> temp = [];

    for(int i = 1; i <= floorCount; i++){
      String tempFloor = "${i}F";
      // if(i == 1){
      //   tempFloor = "${i}st floor";
      // } else if (i == 2){
      //   tempFloor = "${i}nd floor";
      // } else if (i == 3){
      //   tempFloor = "${i}rd floor";
      // } else {
      //   tempFloor = "${i}th floor";
      // }

      temp.add(
        Card(
          elevation: 4.0,
          margin: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(tempFloor, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold),),
            ),
          ),
        ),
      );
    }

    return temp;
  }

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => _hasPermissions = status == PermissionStatus.granted);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    if(mode == 1){
      for (final subscription in _streamSubscriptions) {
        subscription.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if(mode == 1){
      userMovement();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Building (${widget.value})"),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            height: 110,
            child: CarouselSlider(
              items: [
                ...getFloorWidgets(),
              ], 
              options: CarouselOptions(
                onPageChanged: (index, reason){
                  setState(() {
                    selectedValue = floorList[index];
                    assignNodesByLevel();
                  });
                },
                height: 180.0,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                enableInfiniteScroll: false,
                autoPlayCurve: Curves.fastOutSlowIn,
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                viewportFraction: 0.8,
              ),
              carouselController: carouselController,
            ),
          ),

          // Container(
          //   margin: const EdgeInsets.only(top: 10),
          //   child: ListTile(
          //     title: const Text("Room"),
          //     leading: Radio(
          //       value: 1,
          //       groupValue: val,
          //       onChanged: (value) {
          //         setState(() {
          //           val = int.parse(value.toString());
          //         });
          //       },
          //     ),
          //     contentPadding: const EdgeInsets.all(0),
          //   ),
          // ),
          // ListTile(
          //   title: const Text("Path"),
          //   leading: Radio(
          //     value: 2,
          //     groupValue: val,
          //     onChanged: (value) {
          //       setState(() {
          //         val = int.parse(value.toString());
          //       });
          //     },
          //   ),
          //   contentPadding: const EdgeInsets.all(0),
          // ),
          // Container(
          //   width: double.infinity,
          //   margin: const EdgeInsets.only(top: 10),
          //   child: ElevatedButton(
          //       onPressed: () {
          //         addDataToFirebase();
          //       },
          //       style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(20.0),
          //       ),),
          //       child: const Text("Add nodes - BETA")),
          // ),
          Expanded(
            child: Builder(builder: (context) {
              if (_hasPermissions) {
                var tempFloor = selectedValue ?? "0";
                return Stack(
                  children: [
                    tempFloor != "0" ? ZoomContainer(
                      zoomLevel: 3,
                      imageProvider: Image.asset("assets/${widget.value}/$tempFloor.png").image,
                      objects: nodeByLevel,
                      mode: mode == 1 ? "1" : "2",
                    ) : const SizedBox(),
                    mode == 1 ? DraggableScrollableSheet(
                      initialChildSize: 0.20,
                      minChildSize: 0.15,
                      expand: true,
                      builder: (BuildContext context, ScrollController scrollController) {
                        return SingleChildScrollView(
                          controller: scrollController,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Card(
                                  margin: const EdgeInsets.all(10),
                                  child: ListTile(
                                    title: Column(
                                      children: [
                                        Text(timeNow()),
                                        Text(estimateTime()),
                                        // Text(curAlt.toString()),
                                        // Text(calculateAltitude().toString()),
                                        estimateTime() == "Reached destination" ? ElevatedButton(
                                          onPressed: () {
                                            navigateBack(context);
                                          },
                                          child: const Text('Back')) : const SizedBox(),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ) : const SizedBox(),
                  ],
                );
              } else {
                return AlertDialog(
                  title: const Text("Location permission required"),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: const <Widget>[
                        Text("Location permission must be given in order to use this app."),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("Request"),
                      onPressed: () {
                        Permission.locationWhenInUse.request().then((ignored) {
                          _fetchPermissionStatus();
                        });
                      },
                    ),
                    TextButton(
                      child: const Text("Quit"),
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                    ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}