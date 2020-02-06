import 'dart:convert';
// import 'dart:async';
import 'package:toast/toast.dart';
import 'package:tp2/main.dart';
import 'package:tp2/utils/colors_utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  SharedPreferences sharedPreferences;
  bool isValidate = false;
  bool isLoading = false;

  String token;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    TextEditingController _emailInputController = new TextEditingController();
    TextEditingController _passInputController = new TextEditingController();

    signIn(String email, pass) async {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      Map data = {
        'email': email,
        'password': pass
      };

      print(data.values.toString());

      var jsonResponse;
      var response = await http.post("http://e-water.systems/adfin_pdam/public/api/v1/login", body: data);
      if(response.statusCode == 200) {

        jsonResponse = json.decode(response.body);
        if(jsonResponse != null) {
          setState(() {
            isLoading = false;
            token = jsonResponse['token'];
          });
          print(token);
          Toast.show("You are now logged in", context, duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
          sharedPreferences.setString("token", jsonResponse['token']);
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => MainPage(datatoken: token)), (Route<dynamic> route) => false);
        }
      }
      else {
        setState(() {
          isLoading = false;
        });
        Toast.show("Login failed", context, duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
        print(response.statusCode);
        print(response.body);
      }
    }

    final logo = Hero(
      tag: 'Hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 100.0,
        child: Image.asset('assets/images/wmslogo.png'),
      ),
    );

    final banner = Center(
      child: Text(
        "E-WATER SYSTEMS",
        style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold
        ),
      ),
    );

    final email = TextField(
      controller: _emailInputController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(
          color: Colors.white
      ),
      decoration: InputDecoration(
          labelText: 'EMAIL',
          labelStyle: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: HexColor('#1ab394'))
          ),
          errorText: isValidate ? 'Please enter your email' : null
      ),
    );

    final password = TextField(
      controller: _passInputController,
      obscureText: true,
      style: TextStyle(
          color: Colors.white
      ),
      decoration: InputDecoration(
          labelText: 'PASSWORD',
          labelStyle: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: HexColor('#1ab394'))
          ),
          errorText: isValidate ? 'Please enter your password' : null
      ),
    );

    final loginButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        borderRadius: BorderRadius.circular(10.0),
        shadowColor: Colors.black45,
        elevation: 5.0,
        child: MaterialButton(
          onPressed: () {
            setState(() {
              if (_emailInputController.text == "") {
                isValidate = true;
                return null;
              } else if (_passInputController.text == "") {
                isValidate = true;
                return null;
              } else {
                isValidate = false;
                isLoading = true;
                signIn(_emailInputController.text, _passInputController.text);
                
              }
            });
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
          child: Text(
            "LOGIN",
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 14.0
            ),
          ),
          height: 50.0,
          color: HexColor('#1ab394'),
        ),
      ),
    );

    return Scaffold(
      body: Container(
        color: HexColor('#2f4050'),
        child: isLoading ? Center(child: CircularProgressIndicator()) : Center(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(left: 30.0, right: 30.0),
            children: <Widget>[
              logo,
              SizedBox(height: 15.0),
              banner,
              SizedBox(height: 35.0),
              email,
              SizedBox(height: 20.0),
              password,
              SizedBox(height: 35.0),
              loginButton
            ],
          ),
        ),
      ),
    );
  }
}