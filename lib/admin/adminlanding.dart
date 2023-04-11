import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denah_test/crud/addnode.dart';
import 'package:denah_test/crud/addplaces.dart';
import 'package:denah_test/crud/editroom.dart';
import 'package:denah_test/crud/nodelist.dart';
import 'package:denah_test/functions/functions.dart';
import "package:flutter/material.dart";

class AdminLandingPage extends StatefulWidget {
  const AdminLandingPage({ Key? key }) : super(key: key);

  @override
  State<AdminLandingPage> createState() => _AdminLandingPageState();
}

class _AdminLandingPageState extends State<AdminLandingPage> {
  final _dropdownAdminLandingKey = GlobalKey<FormState>();
  FirebaseFirestore db = FirebaseFirestore.instance;

  List<DropdownMenuItem<String>> buildingList = [];

  String? selectedValue;
  bool _isLoading = true;


  @override
  void didChangeDependencies() {
    getBuildingDataFromFirebase();
    super.didChangeDependencies();
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
        title: const Text("Admin menu"),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context,rootNavigator: true).popUntil(ModalRoute.withName('/'));
              },
              child: const Icon(
                Icons.logout,
                size: 26.0,
              ),
            )
          ),
        ],
      ),
      body: !_isLoading ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const ListTile(
                    leading: Icon(Icons.add),
                    title: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Add data to Firestore"),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        child: const Text("ADD NODE"),
                        onPressed: (){
                          navigateTo(context, const AddNodePage());
                        }
                      ),
                      TextButton(
                        child: const Text("ADD PLACES"),
                        onPressed: (){
                          navigateTo(context, const AddPlacePage());
                        }
                      ),
                      // TextButton(
                      //   child: const Text("ADD NEW"),
                      //   onPressed: (){
                      //     navigateTo(context, const AddNodePage());
                      //   }
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Form(
                key: _dropdownAdminLandingKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("Edit data from Firestore"),
                      ),
                      subtitle: DropdownButtonFormField(
                        validator: (value) => value == null ? "Select building first" : null,
                        value: selectedValue,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedValue = newValue!;
                          });
                        },
                        items: buildingList
                      ),
                    ),
                    
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            child: const Text("EDIT NODE"),
                            onPressed: selectedValue != null ? () {
                              if(_dropdownAdminLandingKey.currentState!.validate()){
                                navigateTo(context, NodeListPage(value: selectedValue!));
                              }
                            } : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ) : const Center(child: CircularProgressIndicator()) ,
    );
  }
}