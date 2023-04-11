import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denah_test/crud/addnodelink.dart';
import 'package:denah_test/crud/editroom.dart';
import 'package:denah_test/functions/functions.dart';
import 'package:denah_test/models/mapobject.dart';
import 'package:denah_test/models/nodeinfo.dart';
import 'package:flutter/material.dart';

class NodeListPage extends StatefulWidget {
  final String value;
  const NodeListPage({ Key? key, required this.value }) : super(key: key);

  @override
  State<NodeListPage> createState() => _EditNodeState();
}

class _EditNodeState extends State<NodeListPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> nodeData = [];
  List<DropdownMenuItem<String>> floorList = [];

  String? selectedFloor;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getFloorDataFromFirebase();
    getNodeDataFromFirebase();
  }

  void getFloorDataFromFirebase() async {
    await db.collection("building_info").get().then((event) {
      var tempFloorCount = 0;
      for (var doc in event.docs) {
        if(doc.data()["name"].toString() == widget.value){
          tempFloorCount = int.parse(doc.data()["floors"]);
          break;
        }
      }
      for(int i = 1; i <= tempFloorCount; i++){
        if(i == 1){
          floorList.add(DropdownMenuItem(child: Text("${i}st floor"),value: i.toString()));
        } else if (i == 2){
          floorList.add(DropdownMenuItem(child: Text("${i}nd floor"),value: i.toString()));
        } else if (i == 3){
          floorList.add(DropdownMenuItem(child: Text("${i}rd floor"),value: i.toString()));
        } else {
          floorList.add(DropdownMenuItem(child: Text("${i}th floor"),value: i.toString()));
        }
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  void getNodeDataFromFirebase() async{
    await db.collection("map_node").doc(widget.value).collection("nodes").get().then((event) {
      for (var doc in event.docs) {
        nodeData.add(doc.data());
        nodeData.last['id'] = doc.id;
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  List<MapObject> get nodeObjects {    
    List<MapObject> temp =  nodeData
      .map((node) => MapObject(
          id: node['id'],
          angle: double.parse(node['angle'] ?? "0"),
          child: node['room'] ?? false ? const Icon(Icons.circle_sharp, size: 15,) : const Icon(Icons.circle_outlined, size: 12,),
          offset: Offset(double.parse(node['offset_x'] ?? "0"), double.parse(node['offset_y'] ?? "0")),
          size: const Size(10, 10),
          level: node['level'] ?? "0",
          tooltip: NodeInfo(message: node['tooltip'] ?? ""),
          status: node['status'] ?? true,
          room: node['room'] ?? false,
          path: node['path'] ?? false,
        )
      )
      .toList();

    temp.sort((a, b) {
      return b.room.toString().toLowerCase().compareTo(a.room.toString().toLowerCase());
    },);

    return temp;
  } 

  List<Widget> getNodeByLevel(String level){
    List<Widget> tempList = [];
    
    for(var x in nodeObjects){
      if(x.level.toString() == level){
        tempList.add(
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      x.id,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      x.offset.toString(),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Container(
                     margin: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      x.tooltip.message,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      x.status ? "STATUS : ACTIVE" : "STATUS : INACTIVE",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      x.room ? Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: TextButton(
                          child: const Text("EDIT NAME"),
                          onPressed: (){
                            navigateTo(context, EditRoomPage(building: widget.value, value: x,));
                          }
                        ),
                      ) : const SizedBox(),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: TextButton(
                          child: const Text("ADD LINK"),
                          onPressed: (){
                            navigateTo(context, AddNodeLinkPage(building: widget.value, value: x.id,));
                          }
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: TextButton(
                          child: const Text("EDIT STATUS"),
                          onPressed: (){
                            setState(() {
                              var temp = nodeObjects.where((element) => element.id == x.id).first.status;
                              if(temp) {
                                changeNodeStatus(x.id, false);
                                temp = false;
                              } else {
                                changeNodeStatus(x.id, true);
                                temp = true;
                              }
                              for(int i = 0; i < nodeObjects.length; i++){
                                if(nodeObjects[i].id == x.id){
                                  nodeObjects[i].status = temp;
                                }
                              }
                            });
                          }
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }
    }
    return tempList;
  }

  void changeNodeStatus(String id, bool val){
    final temp = <String, dynamic>{
      "status" : val,
    };

    db.collection("map_node").doc(widget.value).collection("nodes").doc(id).update(temp).then((_){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Status node successfully updated"),
        ));
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Node List")
      ),
      body: !_isLoading ? Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.all(15),
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              value: selectedFloor,
              onChanged: (String? newValue) {
                setState(() {
                  selectedFloor = newValue!;
                });
              },
              items: floorList,
            ),
          ),
          selectedFloor != null ? SizedBox(
            height: MediaQuery.of(context).size.height - 180,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: <Widget>[
                ...getNodeByLevel(floorList[int.parse(selectedFloor!)-1].value.toString()),
              ],
            ),
          ) : const Center(child: Text("No Data :("),),
        ],
      ) : const Center(child: CircularProgressIndicator(),),
    );
  }
}