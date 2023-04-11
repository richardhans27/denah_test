import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denah_test/functions/functions.dart';
import 'package:denah_test/home.dart';
import 'package:denah_test/models/mapobject.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class BuildingMenu extends StatefulWidget {
  const BuildingMenu({ Key? key }) : super(key: key);

  @override
  State<BuildingMenu> createState() => _BuildingMenuState();
}

class _BuildingMenuState extends State<BuildingMenu> {
  final _dropdownMenuFormKey = GlobalKey<FormState>();
  FirebaseFirestore db = FirebaseFirestore.instance;

  List<DropdownMenuItem<String>> buildingList = [];
  List<MapObject> nodeObjects = [];
  List<Map<String, dynamic>> nodeData = [];
  List<Map<String,dynamic>> newData = [];

  String? selectedValue;
  bool _isLoading = true;
  String dataFromFile = "";
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getBuildingDataFromFirebase();
    readText();
  }

 
  Future<void> readText() async {
    final String response = await rootBundle.loadString('assets/input_link.txt');
    setState(() {
      dataFromFile = response;
    });
  }

  void processString() async{
    var splitLine = dataFromFile.split(" ");
    String buildingName = splitLine[0];

    for(int i = 1; i < splitLine.length; i++){
      var splitSourceNode = splitLine[i].split(">");
      var splitSourceLinks = splitSourceNode[1].split(",");
      var tempListLink = [];
      for(int j = 0; j < splitSourceLinks.length; j++){
        tempListLink.add(splitSourceLinks[j]);
      }
      var tempData = <String, dynamic>{
        "link": tempListLink
      };

      // print("source node -> ${splitSourceNode[0]}");
      // print("links -> $splitSourceLinks");
      // print(tempListLink);
      // print(tempData);

      db.collection("map_node").doc(buildingName.toString()).collection("nodes").doc(splitSourceNode[0].toString()).update(tempData).then((value) => {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Node links successfully updated"),
          ))
        }
      );
    }
  }

  void getBuildingDataFromFirebase() async{
    await db.collection("building_info").get().then((event) {
      for (var doc in event.docs) {
        buildingList.add(DropdownMenuItem(child: Text("(${doc.data()['name']}) building"), value: doc.data()['name']));
      }
      buildingList.sort((a, b) {
        return a.value.toString().toLowerCase().compareTo(b.value.toString().toLowerCase());
      },);
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Building"),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Container(
        margin: const EdgeInsets.all(20.0),
        child: Form(
          key: _dropdownMenuFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 15),
                child: const Text(
                  "Select building",
                  style: TextStyle(fontSize: 15),
                ),
              ),
              DropdownButtonFormField(
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
                  validator: (value) => value == null ? "Select building first" : null,
                  value: selectedValue,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedValue = newValue!;
                    });
                  },
                  items: buildingList
                ),
              Container(
                width: double.infinity,
                height: 45,
                margin: const EdgeInsets.only(top: 10),
                child: ElevatedButton(
                  onPressed: () {
                    if (_dropdownMenuFormKey.currentState!.validate()) {
                      navigateTo(context, MyHomePage(value: selectedValue!));
                    }
                  },
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),),
                  child: const Text("EXPLORE")
                ),
              ),

              // Container(
              //   width: double.infinity,
              //   margin: const EdgeInsets.only(top: 10),
              //   child: ElevatedButton(
              //     onPressed: () {
              //       setState(() {
              //         processString();
              //       });
              //     },
              //     style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(20.0),
              //     ),),
              //     child: const Text("BATCH LINK")
              //   ),
              // ),
            ],
          )
        ),
      )
    );
  }
}