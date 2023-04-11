import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddNodePage extends StatefulWidget {
  const AddNodePage({ Key? key }) : super(key: key);

  @override
  State<AddNodePage> createState() => _AddNodePageState();
}

class _AddNodePageState extends State<AddNodePage> {
  final _formKey = GlobalKey<FormState>();
  final _levelTextController = TextEditingController();
  final _offsetXTextController = TextEditingController();
  final _offsetYTextController = TextEditingController();
  final _tooltipTextController = TextEditingController();

  String? selectedValue;
  List<DropdownMenuItem<String>> buildingList = [];
  FirebaseFirestore db = FirebaseFirestore.instance;
  bool _isLoading = true;
  int val = -1;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getBuildingDataFromFirebase();
  }

  void getBuildingDataFromFirebase() async{
    await db.collection("building_info").get().then((event) {
      for (var doc in event.docs) {
        buildingList.add(DropdownMenuItem(child: Text("Gedung " + doc.data()['name']),value: doc.data()['name']));
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  void addDataToFirebase(String level, String offsetX, String offsetY, String tooltip) {
    final temp = <String, dynamic>{
      "angle": "0",
      "level": level.toString() == '' ? "0" : level.toString(),
      "offset_x": offsetX.toString() == '' ? "0" : offsetX.toString(),
      "offset_y": offsetY.toString() == '' ? "0" : offsetY.toString(),
      "path": val == 2 ? true : false,
      "room": val == 1 ? true : false,
      "tooltip": tooltip.toString(),
    };

    db.collection("map_node").doc(selectedValue.toString()).collection("nodes").add(temp).then((DocumentReference doc){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Node successfully added with ID: ${doc.id}"),
        ));

        _levelTextController.text = '';
        _offsetXTextController.text = '';
        _offsetYTextController.text = '';
        _tooltipTextController.text = '';
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Node"),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Container(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Level",
                  ),
                  controller: _levelTextController,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Offset X",
                  ),
                  controller: _offsetXTextController,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Offset Y",
                  ),
                  controller: _offsetYTextController,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Tooltip",
                  ),
                  controller: _tooltipTextController,
                ),
                Container(
                  padding: const EdgeInsets.all(0.0),
                  child: DropdownButtonFormField(
                    validator: (value) => value == null ? "Pilih gedung" : null,
                    value: selectedValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedValue = newValue!;
                      });
                    },
                    items: buildingList,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: ListTile(
                    title: const Text("Room"),
                    leading: Radio(
                      value: 1,
                      groupValue: val,
                      onChanged: (value) {
                        setState(() {
                          val = int.parse(value.toString());
                        });
                      },
                    ),
                    contentPadding: EdgeInsets.all(0),
                  ),
                ),
                ListTile(
                  title: const Text("Path"),
                  leading: Radio(
                    value: 2,
                    groupValue: val,
                    onChanged: (value) {
                      setState(() {
                        val = int.parse(value.toString());
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.all(0),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          addDataToFirebase(
                            _levelTextController.text, _offsetXTextController.text,
                            _offsetYTextController.text, _tooltipTextController.text
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),),
                      child: const Text("Add data")),
                ),
            ],
          ),
        )
      ),
    );
  }
}