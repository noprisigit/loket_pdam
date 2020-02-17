import 'package:flutter/material.dart';
import 'package:tp2/main.dart';
import 'package:tp2/tagihan.dart';
import 'utils/colors_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:tp2/login.dart';

class Dashboard extends StatefulWidget {
  Dashboard({Key key, this.datatoken}) : super(key: key);

  String datatoken;
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  SharedPreferences sharedPreferences;

  checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if(sharedPreferences.getString("token") == null) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("LOKET PDAM")),
        leading: Icon(Icons.home),
        actions: <Widget>[
            FlatButton(
              onPressed: () {
                sharedPreferences.clear();
                // sharedPreferences.commit();
                widget.datatoken = "";
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
                Toast.show("You are logout", context, duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
              },
              child: Text(
                "Log Out",
                style: TextStyle(
                  color: Colors.white
                )
              ),
            )
          ],
      ),
      body: Center(
        child : Container(
          height: 300.0,
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 30),
                child: MaterialButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => Tagihan(token: widget.datatoken)), (Route<dynamic> route) => false); 
                  },
                  child: Text(
                    'Cek Tagihan',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white
                    )
                  ),
                  // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  height: 100.0,
                  color: HexColor('#1ab394'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 30),
                child: MaterialButton(
                  onPressed: () {
                    print('Token : ${widget.datatoken}' );
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => MainPage(token: widget.datatoken)), (Route<dynamic> route) => false);
                  },
                  child: Text(
                    'Bayar Tagihan',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white
                    )
                  ),
                  // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  height: 100.0,
                  color: HexColor('#03d3fc'),
                ),
              ),
            ],
          ),
        )
      )
    );
  }
}