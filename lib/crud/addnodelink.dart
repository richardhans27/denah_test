import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denah_test/models/mapobject.dart';
import 'package:denah_test/models/nodeinfo.dart';
import 'package:flutter/material.dart';

class AddNodeLinkPage extends StatefulWidget {
  final String value, building;
  const AddNodeLinkPage({ Key? key, required this.building, required this.value}) : super(key: key);

  @override
  State<AddNodeLinkPage> createState() => _AddNodeLinkPageState();
}

class _AddNodeLinkPageState extends State<AddNodeLinkPage> {
  final _formKey = GlobalKey<FormState>();
  FirebaseFirestore db = FirebaseFirestore.instance;

  List<DropdownMenuItem<String>> floorList = [];
  List<DropdownMenuItem<String>> nodeList = [];
  List<Map<String, dynamic>> nodeData = [];
  List<String> selectedNodesId = [];

  String? selectedFloor;
  String? selectedNode;
  MapObject? currentNode;

  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getFloorDataFromFirebase();
    getNodeDataFromFirebase();
    getLinksDataFromFirebase();

  }

  void getFloorDataFromFirebase() async {
    await db.collection("building_info").get().then((event) {
      var tempFloorCount = 0;
      for (var doc in event.docs) {
        if(doc.data()["name"].toString() == widget.building){
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

  void getNodeDataFromFirebase() async {
    await db.collection("map_node").doc(widget.building).collection("nodes").get().then((event) {
      for (var doc in event.docs) {
        nodeData.add(doc.data());
        nodeData.last['id'] = doc.id;
      }

      setState(() {
        currentNode = findNodeByName(widget.value);
        _isLoading = false;
      });
    });
  }

  void getLinksDataFromFirebase() async {
    await db.collection("map_node").doc(widget.building.toString()).collection("nodes").doc(widget.value).get().then((event) {
      if(event.exists){
        if(event.data()!['link'] != null) {
          for(var x in event.data()!['link']){
            selectedNodesId.add(x.toString());
          }
        } else {
          selectedNodesId = [];
        }
      }

      setState(() {
        _isLoading = false;
      });
    });
  }

  MapObject? findNodeByName(String name){
    for(var node in nodeData){
      if(node['id'].toString() == name){
        var temp = MapObject(
          id: node['id'],
          angle: double.parse(node['angle']),
          child: node['room'] ? const Icon(Icons.circle_sharp, size: 15,) : const Icon(Icons.circle_outlined, size: 12,),
          offset: Offset(double.parse(node['offset_x']), double.parse(node['offset_y'])),
          size: const Size(10, 10),
          level: node['level'],
          tooltip: NodeInfo(message: node['tooltip'], status: node['tooltip'] != '' ? true : false),
          status: node['status'] ?? true,
        );

        return temp;
      }
    }
    return null;
  }

  void addNodeToSelection(){
    nodeList.clear();
    selectedNode = null;

    for(var x in nodeData){
      if(x['level'].toString() == selectedFloor.toString()){
        nodeList.add(DropdownMenuItem(child: Text("${x['id']} -- Offset(${double.parse(x['offset_x'].toString()).toStringAsFixed(2)},${double.parse(x['offset_y'].toString()).toStringAsFixed(2)})"), value: x['id'].toString()));
      }
    }

    nodeList.sort((a, b) {
      return a.value.toString().toLowerCase().compareTo(b.value.toString().toLowerCase());
    },);
  }

  void updateLinkToFirebase() async {
    final temp = <String, dynamic>{
      "link": selectedNodesId,
    };
    
    selectedFloor = null;
    selectedNode = null;

    db.collection("map_node").doc(widget.building.toString()).collection("nodes").doc(widget.value).update(temp).then((value) => {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Node links successfully updated"),
        ))
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Links to Node"),
      ),
      body: Form(
        key: _formKey,
        child:  !_isLoading ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
                        currentNode?.id ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        currentNode?.offset.toString() ?? "",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        currentNode?.tooltip.message ?? "",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        currentNode?.status.toString() != null ? "STATUS : ACTIVE" : "STATUS : INACTIVE",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 15),
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
                validator: (value) => value == null ? "Select floor" : null,
                value: selectedFloor,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedFloor = newValue!;
                    addNodeToSelection();
                  });
                },
                items: floorList,
              ),
            ),
      
            Container(
              margin: const EdgeInsets.only(top: 5, bottom: 15, left: 10, right: 10),
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
                validator: (value) => value == null ? "Select node" : null,
                value: selectedNode,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedNode = newValue!;
                  });
                },
                items: nodeList,
              ),
            ),

            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 15),
              child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        selectedNodesId.add(selectedNode.toString());
                        updateLinkToFirebase();   
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),),
                  child: const Text("ADD LINK TO NODE")),
            ),

            SizedBox(
              height: MediaQuery.of(context).size.height - 480,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: selectedNodesId.length,
                itemBuilder: ((context, index) {
                  MapObject? temp = findNodeByName(selectedNodesId[index]);
                  return Card(
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
                              temp!.id,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              temp.offset.toString(),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              temp.tooltip.message,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              temp.status ? "STATUS : ACTIVE" : "STATUS : INACTIVE",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(top: 4),
                            child: TextButton(
                              child: const Text("REMOVE", style: TextStyle(color: Colors.red),),
                              onPressed: (){
                                setState(() {
                                  selectedNodesId.remove(temp.id);
                                  updateLinkToFirebase();
                                });
                              }
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
              ),
            ),
          ],
        ) : const Center(child: CircularProgressIndicator(),),
      ),
    );
  }
}