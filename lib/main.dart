import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(TimingApp());

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

  List<int> _list = <int>[];

  void _addCurrentTime() {
    var time = DateTime.now();
    int t = time.hour * 60 + time.minute;
    setState(() {
      _list.add(t);
      _saveList();
    });
  }

  void _readList() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _list = prefs.getStringList('list')?.map((s) => int.parse(s))?.toList() ??
          <int>[];
    });
  }

  void _saveList() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('list', _list.map((t) => '$t').toList());
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
        int t = _list[i];
        return _buildItem(i, t ~/ 60, t % 60);
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
                    _list = <int>[];
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
        onPressed: _addCurrentTime,
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
                  _list[index] = (_list[index] - 1) % 1440;
                  _saveList();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_right),
              iconSize: 24,
              onPressed: () {
                setState(() {
                  _list[index] = (_list[index] + 1) % 1440;
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
