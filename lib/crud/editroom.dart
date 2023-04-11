import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denah_test/functions/functions.dart';
import 'package:denah_test/models/mapobject.dart';
import 'package:flutter/material.dart';

class EditRoomPage extends StatefulWidget {
  final MapObject value;
  final String building;
  const EditRoomPage({ Key? key, required this.value, required this.building }) : super(key: key);

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  final _formEditRoomKey = GlobalKey<FormState>();
  final TextEditingController _roomNameTextController = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;

  void updateDataToFirebase(String name) {
    final temp = <String, dynamic>{
      "name": name,
    };

    db.collection("map_node").doc(widget.building).collection("nodes").doc(widget.value.id).update(temp).then((_){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Node successfully updated"),
        ));

        _roomNameTextController.text = "";
        navigateBack(context);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Node List")
      ),
      body: Column(
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
                      widget.value.id,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.value.offset.toString(),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.value.tooltip.message,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.value.status ? "STATUS : ACTIVE" : "STATUS : INACTIVE",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.all(15),
            child: Form(
              key: _formEditRoomKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Room name",
                    ),
                    controller: _roomNameTextController,
                  ),

                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formEditRoomKey.currentState!.validate()) {
                          updateDataToFirebase(_roomNameTextController.text.toString());
                          _roomNameTextController.text = "";
                        }
                      },
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),),
                      child: const Text("UPDATE ROOM NAME")
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}