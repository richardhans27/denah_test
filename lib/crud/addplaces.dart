import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddPlacePage extends StatefulWidget {
  const AddPlacePage({ Key? key }) : super(key: key);

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  final _formAddPlaceKey = GlobalKey<FormState>();
  final _placeTextController = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;

  void addDataToFirebase(String name) {
    final temp = <String, dynamic>{
      "name": name,
    };

    db.collection("room_info").add(temp).then((DocumentReference doc){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Node successfully added with ID: ${doc.id}"),
        ));

        _placeTextController.text = "";
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add new places"),
      ),
      body: Container(
        margin: const EdgeInsets.all(15),
        child: Form(
          key: _formAddPlaceKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Place name",
                ),
                controller: _placeTextController,
              ),

              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formAddPlaceKey.currentState!.validate()) {
                      addDataToFirebase(_placeTextController.text.toString());
                      _placeTextController.text = "";
                    }
                  },
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),),
                  child: const Text("ADD PLACE")
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}