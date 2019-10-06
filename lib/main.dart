import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(TimingApp());

class _TimeItem {
  int time;
  String content;

  _TimeItem(this.time, this.content);

  static String encodeBase64String(String s) {
    return base64Encode(utf8.encode(s));
  }

  static String decodeBase64String(String s) {
    return utf8.decode(base64Decode(s));
  }

  String toString() {
    return "$time:${encodeBase64String(content)}";
  }

  static _TimeItem fromString(String s) {
    int i = s.indexOf(":");
    return i < 0 ? null : _TimeItem(
        int.parse(s.substring(0, i)),
        decodeBase64String(s.substring(i+1)));
  }
}

class TimingApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TimingPage(title: 'Timing'),
    );
  }
}

class TimingPage extends StatefulWidget {
  TimingPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _TimingPageState createState() => _TimingPageState();
}

class _TimingPageState extends State<TimingPage> {

  List<_TimeItem> _list = <_TimeItem>[];

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/record');
  }

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void _addCurrentTime(String content) {
    var time = DateTime.now();
    int t = time.hour * 60 + time.minute;
    setState(() {
      _list.add(_TimeItem(t, content));
      _saveList();
    });
  }

  void _readList() async {
    try {
      final file = await _localFile;
      String s = await file.readAsString();
      setState(() {
        _list = s.split("\n")
            .map((line) => _TimeItem.fromString(line))
            .toList();
      });
    } catch(e) {
      setState(() {
        _list = <_TimeItem>[];
      });
    }
  }

  void _saveList() async {
    final file = await _localFile;
    await file.writeAsString(_list.map((item) => item.toString()).join("\n"));
  }

  @override
  void initState() {
    super.initState();
    _readList();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = ListView.separated(
      itemCount: _list.length,
      itemBuilder: (context, i) {
        _TimeItem t = _list[i];
        return _buildItem(i, t.time ~/ 60, t.time % 60);
      },
      separatorBuilder: (context, i) {
        return Divider(height: 2, color: Colors.black26);
      },
    );

    body = DefaultTextStyle(style: TextStyle(
      fontFamily: "Helvetica",
      fontSize: 24,
    ), child: body);

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton<int> (
            onSelected: (result) {
              switch(result) {
                case 0:
                  setState(() {
                    _list = <_TimeItem>[];
                    _saveList();
                  });
              }
            },
            itemBuilder: (context) {
              return <PopupMenuItem<int>>[
                PopupMenuItem<int>(
                  value: 0,
                  child: Text('Clear'),
                )
              ];
            },
          )
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCurrentTime(""),
        tooltip: 'Add Current Time',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildItem(int index, int hour, int minute) {
    Widget ret = Text('$hour:${minute ~/ 10}${minute % 10}');

    ret = ListTile(
      leading: Icon(Icons.access_time, size: 24),
      title: ret,
      trailing: Container(
        width: 150,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.keyboard_arrow_left),
              iconSize: 24,
              onPressed: () {
                setState(() {
                  _list[index].time = (_list[index].time - 1) % 1440;
                  _saveList();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_right),
              iconSize: 24,
              onPressed: () {
                setState(() {
                  _list[index].time = (_list[index].time + 1) % 1440;
                  _saveList();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              iconSize: 24,
              onPressed: () {
                setState(() {
                  _list.removeAt(index);
                  _saveList();
                });
              },
            ),
          ],
        ),
      ),
    );

    return ret;
  }

}
