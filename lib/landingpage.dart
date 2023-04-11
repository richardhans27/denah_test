import 'package:denah_test/explorepage.dart';
import 'package:denah_test/admin/login.dart';
import 'package:denah_test/findpage.dart';
import 'package:denah_test/functions/functions.dart';
import "package:flutter/material.dart";

class LandingPage extends StatefulWidget {
  const LandingPage({ Key? key }) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Petra Navigation"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                navigateTo(context, const LoginPage());
              },
              child: const Icon(
                Icons.login,
                size: 26.0,
              ),
            )
          ),
        ],
      ),
      body: Column(
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
                    leading: Icon(Icons.place),
                    title: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Find your destination"),
                    ),
                    subtitle: Text("Find your destination anywhere and anytime"),
                  ),
                  TextButton(
                    child: const Text("FIND NOW"),
                    onPressed: () {
                      navigateTo(context, const FindNowPage());
                    },
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const ListTile(
                    leading: Icon(Icons.home_filled),
                    title: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Explore Petra"),
                    ),
                    subtitle: Text("Explore your ways around Petra Christian University"),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: TextButton(
                      child: const Text("EXPLORE NOW"),
                      onPressed: (){
                        navigateTo(context, const BuildingMenu());
                      }
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