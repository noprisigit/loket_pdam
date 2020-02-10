import 'dart:convert';
//import 'dart:html';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:toast/toast.dart';
import 'package:tp2/login.dart';
import 'dart:async';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tp2/utils/colors_utils.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';


void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "E-LOCKET",
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      theme: ThemeData(
          accentColor: Colors.white70
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.datatoken}) : super(key:key);

  String datatoken;
  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage> {
  SharedPreferences sharedPreferences;

  TextEditingController _customerOnlineCode = new TextEditingController();

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Map userData;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _pressed = false;
  bool issetData = false;
  bool isValidate = false;
  bool isLoading = false;

  String codeOnline;
  String _levelUser;

  String pathImage;
  int biayaAdmin = 0;
  int totalTagihan = 0;
  int jumlah = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initSavetoPath();
    checkLoginStatus();
  }

  checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if(sharedPreferences.getString("token") == null) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => LoginPage()), (Route<dynamic> route) => false);
    }
  }

 initSavetoPath() async{
    //read and write
    //image max 300px X 300px
    final filename = 'test.png';
    var bytes = await rootBundle.load("assets/images/tirtadharma.png");
    String dir = (await getApplicationDocumentsDirectory()).path;
    writeToFile(bytes,'$dir/$filename');
    setState(() {
     pathImage='$dir/$filename';
   });
 }

  Future searchCustomer(String value) async {
    if (widget.datatoken != null) {
      String url = "http://e-water.systems/adfin_pdam/public/api/v1/finance/tagihan/";
      var jsonResponse;
      var response = await http.get( url + value, headers: {
        'Accept' : 'application/json',
        'Authorization' : 'Bearer ${widget.datatoken}'
      });
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          setState(() {
            issetData = true;
            isLoading = false;
            userData = jsonResponse;
            codeOnline = userData['tagihan'][0]['kd_online'];
            _levelUser = userData['user']['level_user'];
            print(_levelUser);

            if (userData['user']['level_user'] != "loket") {
              Toast.show("Akun ini bukan loket", context, duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
            } 

            if (userData['user']['type'] == "internal") {
              biayaAdmin = int.parse(userData['user']['biaya_admin']);
              totalTagihan = int.parse(userData['tagihan'][0]['total_tagihan']);
              jumlah = biayaAdmin + totalTagihan;
            } else if (userData['user']['type'] == "eksternal") {
              biayaAdmin = int.parse(userData['user']['biaya_admin']);
              totalTagihan = int.parse(userData['tagihan'][0]['total_tagihan']);
              jumlah = biayaAdmin + totalTagihan;
            }
          });
        } else {
          setState(() {
            isLoading = false;
            issetData = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          issetData = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
        issetData = false;
      });
      print("Token Kosong");
    }

  }

  Future<void> initPlatformState() async {
    List<BluetoothDevice> devices = [];

    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      print("Failed to get devices");
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            _pressed = false;
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            _pressed = false;
          });
          break;
        default:
          print(state);
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('LOKET PDAM'),
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
        body: Container(
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Device:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton(
                      items: _getDeviceItems(),
                      onChanged: (value) => setState(() => _device = value),
                      value: _device,
                    ),
                    RaisedButton(
                      onPressed:
                          _pressed ? null : _connected ? _disconnect : _connect,
                      child: Text(_connected ? 'Disconnect' : 'Connect'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  "Kode Online",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.0
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 10.0, right: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _customerOnlineCode,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Kode Online Pelanggan",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: HexColor('#3498db'))
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: HexColor('#3498db'))
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red)
                        ),
                        errorText: isValidate ? 'Please fill a field' : null
                      ),
                    ),
                    SizedBox(height: 15.0,),
                    Center(
                      child: RaisedButton(
                        onPressed: () {
                          if (_customerOnlineCode.text == "") {
                            setState(() {
                              isValidate = true;
                              return null;
                            });
                          } else {
                            setState(() {
                              isLoading = true;
                              searchCustomer(_customerOnlineCode.text);
                            });
                          }

                          _customerOnlineCode.clear();
                        },
                        child: Text(
                          "Submit",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600
                          ),
                        ),
                        padding: EdgeInsets.all(15.0),
                        color: HexColor('#3498db'),
                      ),
                    ),  
                    SizedBox(height: 15.0,),
                    Container(
                      child: issetData == false ? ListView(
                        children: <Widget>[
                          isLoading ? Center(child: CircularProgressIndicator()) : Card(
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Center(
                                child: Text(
                                  "Data Tagihan Tidak Ditemukan / Tagihan Sudah Dibayar",
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w700
                                  ),textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          )
                        ],
                        shrinkWrap: true,
                      ) : ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          isLoading ? Center(child: CircularProgressIndicator()) : Card(
                            child: Column(
                              children: <Widget> [
                                Container(
                                  margin: EdgeInsets.all(18.0),
                                  child: Center(
                                      child:Text(
                                        "Data Pelanggan",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.0
                                        ),
                                      )
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    "Kode Online"
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "              : "
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "${userData['tagihan'][0]['kd_online']}"
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "Nama Pelanggan"
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "     : "
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "${userData['tagihan'][0]['nama_pelanggan']}"
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "Alamat Pelanggan"
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "   : "
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "${userData['tagihan'][0]['alamat']}"
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "Periode Tunggakan"
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      " : "
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "${userData['tagihan'][0]['periode']}"
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "Pemakaian (M3)"
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "      : "
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "${userData['tagihan'][0]['pemakaian']}"
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "Tagihan"
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "                     : "
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "${userData['tagihan'][0]['nilai_air']}"
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "Beban & Denda"
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "        : "
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "${userData['tagihan'][0]['nilai_nonair']} & ${userData['tagihan'][0]['denda']}"
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "Biaya Admin"
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "             : "
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "${biayaAdmin.toString()}"
                                                  ),
                                                )
                                              ],
                                            ),
                                            SizedBox(height: 20.0,),
                                            Divider(color: Colors.black,),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "Total Tagihan"
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "           : "
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                      "${jumlah.toString()}"
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ]
                            )
                          )
                        ],
                      )
                    ),
                  ],  
                ) 
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                child: MaterialButton(
                  onPressed: (_connected && codeOnline != null && userData['user']['level_user'] == "loket" ) ?  _tesPrint : null,
                  // onPressed: codeOnline == null && _levelUser != "loket" ? null : () {
                  //   if (_connected && codeOnline != null && _levelUser == "loket") {
                  //     setState(() { 
                  //       codeOnline = null;
                  //     });
                  //     _tesPrint();
                  //   }
                  // },
                  child: Text(
                    'Bayar',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white
                    )
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  height: 50.0,
                  color: HexColor('#1ab394'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devices.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  void _connect() {
    if (_device == null) {
      print('No device selected.');
    } else {
      bluetooth.isConnected.then((isConnected) {
        if (!isConnected) {
          bluetooth.connect(_device).catchError((error) {
            setState(() => _pressed = false);
          });
          setState(() => _pressed = true);
        }
      });
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _pressed = true);
  }

//write to app path
  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  updateBayar() async {
    Map data = {
      'id_bayar': userData['tagihan'][0]['id_bayar'].toString(),
      'id_pelanggan': userData['tagihan'][0]['id_pelanggan'].toString(),
      'total': userData['tagihan'][0]['total_tagihan'],
      'name': userData['user']['name'].toString(),
      'kd_staff': userData['user']['id'].toString()
    };
    
    var response = await http.post("http://e-water.systems/adfin_pdam/public/api/v1/finance/bayarAndroid", body: data);
    if (response.statusCode == 200) {
      Toast.show("Pembayaran Berhasil Dilakukan", context, duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    }
  }

  void _tesPrint() async {
    updateBayar();
    //SIZE
    // 0- normal size text
    // 1- only bold text
    // 2- bold with medium text
    // 3- bold with large text
    //ALIGN
    // 0- ESC_ALIGN_LEFT
    // 1- ESC_ALIGN_CENTER
    // 2- ESC_ALIGN_RIGHT
    bluetooth.isConnected.then((isConnected) {
      if (isConnected) {
        bluetooth.printImage(pathImage);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom("PEMERINTAH ${userData['pdam'][0]['alamat']}", 1, 1);
        bluetooth.printCustom("${userData['pdam'][0]['nama_pdam']}", 1, 1);
        bluetooth.printCustom("${userData['pdam'][0]['alamat2']}", 0, 1);
        bluetooth.printCustom("Telp. ${userData['pdam'][0]['telp']}", 0, 1);
        bluetooth.printCustom("-----------------------------------", 0, 1);
        bluetooth.printNewLine();
        bluetooth.printCustom("BUKTI PEMBAYARAN", 1, 1);
        bluetooth.printNewLine();
        bluetooth.printLeftRight("Kode Online      : ", "${userData['tagihan'][0]['kd_online']}", 0);
        bluetooth.printLeftRight("Nama Pelanggan   : ", "${userData['tagihan'][0]['nama_pelanggan']}", 0);
        bluetooth.printLeftRight("Alamat Pelanggan : ", "${userData['tagihan'][0]['alamat']}", 0);
        bluetooth.printLeftRight("Tipe Pelanggan   : ", "${userData['tagihan'][0]['type_pelanggan']}", 0);
        bluetooth.printLeftRight("Bulan/Tahun      : ", "${userData['tagihan'][0]['bulan']}/${userData['tagihan'][0]['tahun']}", 0);
        bluetooth.printLeftRight("Awal/Akhir (M3)  : ", "${userData['tagihan'][0]['awal']}/${userData['tagihan'][0]['akhir']}", 0);
        bluetooth.printLeftRight("Pemakaian (M3)   : ", "${userData['tagihan'][0]['pemakaian']}", 0);
        bluetooth.printLeftRight("Tagihan          : ", "${userData['tagihan'][0]['nilai_air']}", 0);
        bluetooth.printLeftRight("Beban & Denda    : ", "${userData['tagihan'][0]['nilai_nonair']} & ${userData['tagihan'][0]['denda']}", 0);
        bluetooth.printLeftRight("Biaya Admin      : ", "${biayaAdmin.toString()}", 0);
        bluetooth.printCustom("-----------------------------------", 0, 1);
        bluetooth.printLeftRight("Total Tagihan    : ", "${jumlah.toString()}", 0);
        bluetooth.printNewLine();
        bluetooth.printCustom("Bukti pembayaran ini merupakan", 0, 1);
        bluetooth.printCustom("bukti pembayaran yang sah.", 0, 1);
        bluetooth.printCustom("Terima kasih", 0, 1);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom("Loket : ${userData['user']['name']}", 0, 2);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.paperCut();

        bluetooth.printImage(pathImage);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom("PEMERINTAH ${userData['pdam'][0]['alamat']}", 1, 1);
        bluetooth.printCustom("${userData['pdam'][0]['nama_pdam']}", 1, 1);
        bluetooth.printCustom("${userData['pdam'][0]['alamat2']}", 0, 1);
        bluetooth.printCustom("Telp. ${userData['pdam'][0]['telp']}", 0, 1);
        bluetooth.printCustom("-----------------------------------", 0, 1);
        bluetooth.printNewLine();
        bluetooth.printCustom("BUKTI PEMBAYARAN", 1, 1);
        bluetooth.printNewLine();
        bluetooth.printLeftRight("Kode Online      : ", "${userData['tagihan'][0]['kd_online']}", 0);
        bluetooth.printLeftRight("Nama Pelanggan   : ", "${userData['tagihan'][0]['nama_pelanggan']}", 0);
        bluetooth.printLeftRight("Alamat Pelanggan : ", "${userData['tagihan'][0]['alamat']}", 0);
        bluetooth.printLeftRight("Tipe Pelanggan   : ", "${userData['tagihan'][0]['type_pelanggan']}", 0);
        bluetooth.printLeftRight("Bulan/Tahun      : ", "${userData['tagihan'][0]['bulan']}/${userData['tagihan'][0]['tahun']}", 0);
        bluetooth.printLeftRight("Awal/Akhir (M3)  : ", "${userData['tagihan'][0]['awal']}/${userData['tagihan'][0]['akhir']}", 0);
        bluetooth.printLeftRight("Pemakaian (M3)   : ", "${userData['tagihan'][0]['pemakaian']}", 0);
        bluetooth.printLeftRight("Tagihan          : ", "${userData['tagihan'][0]['nilai_air']}", 0);
        bluetooth.printLeftRight("Beban & Denda    : ", "${userData['tagihan'][0]['nilai_nonair']} & ${userData['tagihan'][0]['denda']}", 0);
        bluetooth.printLeftRight("Biaya Admin      : ", "${biayaAdmin.toString()}", 0);
        bluetooth.printCustom("-----------------------------------", 0, 1);
        bluetooth.printLeftRight("Total Tagihan    : ", "${jumlah.toString()}", 0);
        bluetooth.printNewLine();
        bluetooth.printCustom("Bukti pembayaran ini merupakan", 0, 1);
        bluetooth.printCustom("bukti pembayaran yang sah.", 0, 1);
        bluetooth.printCustom("Terima kasih", 0, 1);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printCustom("Loket : ${userData['user']['name']}", 0, 2);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.paperCut();
      }
    });
  }
  
}
