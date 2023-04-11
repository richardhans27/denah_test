import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denah_test/admin/adminlanding.dart';
import 'package:denah_test/functions/functions.dart';
import 'package:denah_test/models/user.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({ Key? key }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginFormKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;
  
  List<User> userList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getUserListFromFirebase();
  }

  void getUserListFromFirebase() async{
    await db.collection("admin").get().then((event) {
      for (var doc in event.docs) {
        userList.add(
          User(
            id: doc.id,
            username: doc['username'],
            password: doc['password'], 
            lastLogin: doc['last_login'],
          )
        );
      }
    });
  }

  void login(String username, String password){
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String date = tsdate.year.toString() + "/" + tsdate.month.toString() + "/" + tsdate.day.toString();
    String time = tsdate.hour.toString() + ":" + tsdate.minute.toString();

    bool status = false;
    for(var user in userList){
      if(user.username == username && user.password == password){
        updateLastLogin(user, "$date $time");
        status = true;
      } else{
        status = false;
       
      }
    }

    if(status){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Login success"),
      ));
    }else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Login failed"),
      ));
    }
    clearField();
  }

  void updateLastLogin(User user, String lastLogin) async {
    final temp = <String, dynamic>{
      "last_login": lastLogin,
    };

    db.collection("admin").doc(user.id).update(temp).then((_){
        navigateTo(context, const AdminLandingPage());
      }
    );
  }

  void clearField(){
    nameController.text = "";
    passwordController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _loginFormKey,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                child: const Text(
                  "Login Admin",
                  style: TextStyle(fontSize: 20),
                )
              ),
              Container(
                padding: const EdgeInsets.all(10),
                child: TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Username",
                  ),
                  validator: (value) => value == '' ? "Please enter your username" : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: TextFormField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Password",
                  ),
                  validator: (value) => value == '' ? "Please enter your password" : null,
                ),
              ),
              // TextButton(
              //   onPressed: () {
              //     //forgot password screen
              //   },
              //   child: const Text('Forgot Password',),
              // ),
              Container(
                height: 50,
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: ElevatedButton(
                  child: const Text("LOGIN"),
                  onPressed: () {
                    if(_loginFormKey.currentState!.validate()){
                      login(nameController.text.toString(), passwordController.text.toString());
                    }
                  },
                )
              ),
              // Row(
              //   children: <Widget>[
              //     const Text('Does not have account?'),
              //     TextButton(
              //       child: const Text(
              //         'Sign in',
              //         style: TextStyle(fontSize: 20),
              //       ),
              //       onPressed: () {
              //         //signup screen
              //       },
              //     )
              //   ],
              //   mainAxisAlignment: MainAxisAlignment.center,
              // ),
            ],
          )),
      ),
    );
  }
}