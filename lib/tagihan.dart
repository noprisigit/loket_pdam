import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'package:tp2/dashboard.dart';
import 'package:tp2/utils/colors_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class Tagihan extends StatefulWidget {
  Tagihan({Key key, this.token}) : super(key: key);

  String token;
  @override
  _TagihanState createState() => _TagihanState();
}

class _TagihanState extends State<Tagihan> {
  ScrollController _scrollController;

  Map data;
  List listData;

  bool _loading = false;
  bool _issetData = false;

  Future getData(String value) async {
    String url =
        "http://e-water.systems/adfin_pdam/public/api/v1/finance/tagihanAll/";
    var response =
        await http.get(url + value, headers: {'Accept': 'application/json'});
    data = json.decode(response.body);
    setState(() {
      _issetData = true;
      _loading = false;
      listData = data['tagihan'];
    });
    print(listData.toList());
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _formTagihan = new TextEditingController();

    final label = Padding(
        padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
        child: Text(
          "Kode Online Pelanggan",
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16.0),
        ));

    final formTagihan = Padding(
        padding: EdgeInsets.all(10.0),
        child: TextField(
          controller: _formTagihan,
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: 16.0),
          decoration: InputDecoration(
              hintText: "Kode Online Pelanggan",
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: HexColor('#1ab394')))),
        ));

    final button = Center(
        child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Material(
              borderRadius: BorderRadius.circular(10.0),
              shadowColor: Colors.black38,
              elevation: 5.0,
              child: MaterialButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                  });
                  getData(_formTagihan.text);
                },
                child: Text(
                  "Submit",
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700),
                ),
                minWidth: 200.0,
                height: 50.0,
                color: HexColor('#1ab394'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0)),
              ),
            )));

    final listPelangganNotFound = ListView(children: <Widget>[
      _loading ? Center(child: CircularProgressIndicator()) : Card(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Center(
              child: Text(
                "Data Tagihan Tidak Ditemukan / Tagihan Sudah Dibayar",
                style:
                    TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        )
      ], 
      shrinkWrap: true
    );

    final listPelanggan = _issetData == false ? Text("") : Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "Nama Pelanggan : ${listData[0]['nama_pelanggan']}",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500
              ),
            )
          ),
          Padding(
            padding: EdgeInsets.all(5.0),
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: listData == null ? 0 : listData.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                   
                  },
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(15.0, 15.0, 0, 15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text("Bulan / Tahun"),
                              Text(" : "),
                              Text(
                                  "${listData[index]['bulan']} / ${listData[index]['tahun']}")
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text("Tarif Air           "),
                              Text(" : "),
                              Text("${listData[index]['tarif_air']}")
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text("Tarif Non Air   "),
                              Text(" : "),
                              Text("${listData[index]['tarif_nonair']}")
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text("Denda              "),
                              Text(" : "),
                              Text("${listData[index]['denda']}")
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text("Total Tagihan "),
                              Text(" : "),
                              Text(
                                  "${listData[index]['total_tagihan']}")
                            ],
                          ),
                        ],
                      )
                    ),
                  )
                );
              }
            ),
          )
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("List Tagihan")),
        leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (BuildContext context) => Dashboard()),
                (Route<dynamic> route) => false)),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            label,
            formTagihan,
            button,
            SizedBox(height: 10.0),
            listPelanggan
          ],
        ),
      ),
    );
  }
}
