import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denah_test/functions/functions.dart';
import 'package:denah_test/home.dart';
import 'package:denah_test/locationtracking.dart';
import 'package:flutter/material.dart';

class FindNowPage extends StatefulWidget {
  const FindNowPage({ Key? key }) : super(key: key);

  @override
  State<FindNowPage> createState() => _FindNowPageState();
}

class _FindNowPageState extends State<FindNowPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  List<String> placeList = [];
  List<String> oldPlaceList = [];
  List<String> nameList = [];
  List<String> placeResult = [];
  List<String> buildingList = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getBuildingDataFromFirebase();
  }

  void getBuildingDataFromFirebase() async{
    await db.collection("map_node").get().then((event) async {
      for (var doc1 in event.docs) {
        await db.collection("map_node").doc(doc1.data()['name']).collection("nodes").get().then((eventNode) {
          for (var doc in eventNode.docs) {
            if(doc.data()['tooltip'].toString() != ""){
              placeList.add(doc.data()['tooltip'].toString());
              nameList.add(doc.id.toString());
            }
          }
          // placeList.sort((a, b) {
          //   return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
          // },);
        });
      }
      setState(() {
        placeResult = placeList;
        _isLoading = false;
      });
    });
  }

  void _runFilter(String enteredKeyword) {
    List<String> results = [];
    if (enteredKeyword.isEmpty) {
      // if the search field is empty or only contains white-space, we'll display all users
      results = placeList;
    } else {
      results = placeList.where((place) => place.toLowerCase().contains(enteredKeyword.toLowerCase())).toList();
      // we use the toLowerCase() method to make it case-insensitive
    }

    // Refresh the UI
    setState(() {
      placeResult = results;
    });
  }

  String findIdByTooltip(String text){
    for(int i = 0; i < placeList.length; i++){
      if(placeList[i] == text){
        return nameList[i];
      }
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find your destination"),
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20,),
            TextField(
              onChanged: (value) => _runFilter(value),
              decoration: const InputDecoration(
                  labelText: 'Search', suffixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 20,),
            !_isLoading ? Expanded(
              child: placeResult.isNotEmpty
                ? ListView.builder(
                    itemCount: placeResult.length,
                    itemBuilder: (context, index) => Card(
                      key: ValueKey(placeResult[index]),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(placeResult[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.run_circle_outlined),
                            onPressed: (){
                              var temp = findIdByTooltip(placeResult[index]);
                              navigateTo(context, LocationTracking(end: temp));

                              // BYPASS ONLY
                              // navigateTo(context, MyHomePage(value: splitStringBuilding(temp), start: "2P-1R", end: temp, mode: 1,));
                            },
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("No results found...", style: TextStyle(fontSize: 20),),
                        Text("Please try another keyword", style: TextStyle(fontSize: 20),)
                      ],
                    )
                  ),
            ) : Center(
              child: Container(
                margin: const EdgeInsets.only(top: 70),
                child: const CircularProgressIndicator()
              ),
            ),
          ],
        ),
      ),
    );
  }
}