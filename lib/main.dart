import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

void main() => runApp(TimingApp());

class DateTimeUtils {
  static final weekDayNames = <String>["日", "一", "二", "三", "四", "五", "六"];

  static String weekDayName(int day) {
    return weekDayNames[day];
  }

  static int dayOfWeekByName(String day) {
    for (int i = 0; i < weekDayNames.length; i++) {
      if (weekDayNames[i] == day) {
        return i;
      }
    }
    return null;
  }

  static int today() {
    var today = DateTime.now();
    return _gregorianToJulian(today.year, today.month, today.day);
  }

  static int now() {
    var now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  static String durationToString(int minutes) {
    if (minutes == 0) {
      return "0m";
    }
    var h = minutes ~/ 60;
    var m = minutes % 60;
    // If m is 0, omit the minutes part
    return "${h > 0 ? "${h}h" : ""}${m > 0 ? "${m}m" : ""}";
  }

  static String timeToString(int time) {
    if (time == null) {
      return null;
    }
    var h = time ~/ 60;
    var m = time % 60;
    return "$h:${m ~/ 10}${m % 10}";
  }

  static String dayToString(int day) {
    if (day == null) {
      return null;
    }
    var gregorian = _julianToGregorian(day);
    var y = gregorian ~/ 10000;
    var m = (gregorian % 10000) ~/ 100;
    var d = gregorian % 100;
    return "$y-$m-$d";
  }

  static String timeToStringRelative(int day, int time) {
    if (day == today()) {
      return timeToString(time);
    }
    if (day == today() - 1) {
      return "昨天 ${timeToString(time)}";
    }
    if (day == today() - 2) {
      return "前天 ${timeToString(time)}";
    }
    return "${dayToString(day)} ${timeToString(time)}";
  }

  static String dayToStringRelative(int day) {
    if (day == today()) {
      return "今天";
    }
    if (day == today() - 1) {
      return "昨天";
    }
    if (day == today() - 2) {
      return "前天";
    }
    return dayToString(day);
  }

  static int dayOfWeek(int day) {
    if (day == null) {
      return null;
    }
    return (day + 1) % 7;
  }

  static int yearMonthDayToInt(int y, int m, int d) {
    if (y == null || m == null || d == null) {
      return null;
    }
    return _gregorianToJulian(y, m, d);
  }

  static int yearMonthDayFromInt(int day) {
    if (day == null) {
      return null;
    }
    return _julianToGregorian(day);
  }

  static DateTime dateTimeFromInt(int day) {
    int ymd = yearMonthDayFromInt(day);
    return DateTime(ymd ~/ 10000, (ymd ~/ 100) % 100, ymd % 100);
  }

  // Refer to http://www.stiltner.org/book/bookcalc.htm for gregorian
  // and julian date
  static int _gregorianToJulian(int y, int m, int d) {
    return (1461 * (y + 4800 + (m - 14) ~/ 12)) ~/ 4 +
        (367 * (m - 2 - 12 * ((m - 14) ~/ 12))) ~/ 12 -
        (3 * ((y + 4900 + (m - 14) ~/ 12) / 100)) ~/ 4 +
        d -
        32075;
  }

  static int _julianToGregorian(int jd) {
    var l = jd + 68569;
    var n = (4 * l) ~/ 146097;
    l = l - (146097 * n + 3) ~/ 4;
    var i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    var j = (80 * l) ~/ 2447;
    var d = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    var m = j + 2 - (12 * l);
    var y = 100 * (n - 49) + i + l;
    return y * 10000 + m * 100 + d;
  }
}

class _TimeItem {
  int day;
  int time;
  String content;

  _TimeItem(this.day, this.time, this.content);

  static String encodeBase64String(String s) {
    return base64Encode(utf8.encode(s));
  }

  static String decodeBase64String(String s) {
    return utf8.decode(base64Decode(s));
  }

  String toString() {
    return "$day:$time:${encodeBase64String(content)}";
  }

  static _TimeItem fromString(String s) {
    int i = s.indexOf(":");
    if (i < 0) return null;
    int j = s.indexOf(":", i + 1);
    if (j < 0) return null;
    return i < 0
        ? null
        : _TimeItem(
            int.parse(s.substring(0, i)),
            int.parse(s.substring(i + 1, j)),
            decodeBase64String(s.substring(j + 1)));
  }

  static int compare(_TimeItem item1, _TimeItem item2) {
    if (item1.day < item2.day) return -1;
    if (item1.day > item2.day) return 1;
    if (item1.time < item2.time) return -1;
    if (item1.time > item2.time) return 1;
    return 0;
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
  List<String> _candidates = <String>["工作", "学习", "休息", "睡觉"];
  int _editing;
  TextEditingController _editRecordController;
  bool _focusOnCandidates = false;
  ScrollController _recordsController;
  ScrollController _candidatesController;
  static const int _maxCandidatesCount = 20;

  @override
  void initState() {
    super.initState();
    _editRecordController = TextEditingController();
    _recordsController = ScrollController()
      ..addListener(() {
        setState(() {
          _focusOnCandidates = false;
        });
      });
    _candidatesController = ScrollController()
      ..addListener(() {
        setState(() {
          _focusOnCandidates = true;
        });
      });
    _readList();
    _readCandidates();
  }

  @override
  void dispose() {
    _editRecordController.dispose();
    _recordsController.dispose();
    _candidatesController.dispose();
    super.dispose();
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/record');
  }

  static Future<File> get _localCandidatesFile async {
    final path = await _localPath;
    return File('$path/candidates');
  }

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void _addCurrentTime(String content) {
    var time = DateTime.now();
    int t = time.hour * 60 + time.minute;
    int d = DateTimeUtils.yearMonthDayToInt(time.year, time.month, time.day);
    setState(() {
      _list.add(_TimeItem(d, t, content));
      _saveList();
    });
  }

  void _readList() async {
    try {
      final file = await _localFile;
      String s = await file.readAsString();
      setState(() {
        _list = s.split("\n").map((line) => _TimeItem.fromString(line))
                .where((item) => item != null)
                .toList();
        _list.sort(_TimeItem.compare);
      });
    } catch (e) {
      setState(() {
        _list = <_TimeItem>[];
      });
    }
  }

  void _saveList() async {
    final file = await _localFile;
    await file
        .writeAsString(_list.map((item) => item?.toString() ?? "").join("\n"));
  }

  void _readCandidates() async {
    try {
      final file = await _localCandidatesFile;
      String s = await file.readAsString();
      setState(() {
        _candidates = s.split("\n");
      });
    } catch (e) {
      setState(() {
        _candidates = <String>["工作", "学习", "休息", "睡觉"];
      });
    }
  }

  void _saveCandidates() async {
    final file = await _localCandidatesFile;
    await file.writeAsString(_candidates.join("\n"));
  }

  void _clear() {
    setState(() {
      _list = <_TimeItem>[];
      _saveList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Column(children: <Widget>[
      Expanded(
        flex: 3,
        child: ListView.builder(
            reverse: true,
            controller: _recordsController,
            itemCount: _list.length,
            itemBuilder: (context, i) {
              i = _list.length - 1 - i;
              return _buildItem(_list[i], i);
            }),
      ),
      Expanded(
        flex: _focusOnCandidates ? 9 : 1,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[200])),
              boxShadow: <BoxShadow>[BoxShadow()]),
          child: ListView.separated(
            controller: _candidatesController,
            itemCount: _candidates.length,
            itemBuilder: buildCandidateItem,
            separatorBuilder: (context, index) {
              return Divider(height: 1);
            },
          ),
        ),
      )
    ]);

    body = DefaultTextStyle(
        style: TextStyle(
          fontFamily: "Helvetica",
          fontSize: 24,
        ),
        child: body);

    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _editing == null
                  ? () {
                      _addCurrentTime("");
                      _editing = _list.length - 1;
                      _editRecordController.clear();
                      _recordsController.animateTo(0,
                          duration: Duration(milliseconds: 100),
                          curve: Curves.easeInOut);
                    }
                  : null,
            ),
            PopupMenuButton<int>(
              onSelected: (result) {
                switch (result) {
                  case 0:
                    if(_list.isNotEmpty) {
                      Share.share(_toCSV(","));
                    }
                    break;
                  case 1:
                    showDialog(context: context, builder: (context) {
                      return AlertDialog(
                        title: Text("Sure to clear?"),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          FlatButton(
                            child: Text("Yes"),
                            onPressed: () {
                              _clear();
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      );
                    });
                    break;
                }
              },
              itemBuilder: (context) {
                return <PopupMenuItem<int>>[
                  PopupMenuItem<int>(
                    value: 0,
                    child: Text('Share'),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    child: Text('Clear'),
                  )
                ];
              },
            )
          ],
        ),
        body: body);
  }

  Widget _buildItem(_TimeItem item, int index) {
    if (item == null) {
      return Container();
    }
    Widget ret = index != _editing
        ? GestureDetector(
            onTap: () {
              _addCurrentTime(item.content);
              _updateCandidateList(item.content);
              _saveCandidates();
            },
            child: Text(item.content),
          )
        : TextField(
            controller: _editRecordController,
            autofocus: true,
          );

    ret = ListTile(
      leading: Icon(Icons.access_time, size: 24),
      title: ret,
      trailing: Container(
        width: 100,
        child: Row(
          children: <Widget>[
            _editing != index
                ? IconButton(
                    icon: Icon(Icons.edit),
                    iconSize: 24,
                    onPressed: _editing == null
                        ? () {
                            setState(() {
                              _editRecordController.text = item.content;
                              _editing = index;
                            });
                          }
                        : null,
                  )
                : IconButton(
                    icon: Icon(Icons.check),
                    iconSize: 24,
                    onPressed: () {
                      setState(() {
                        _list[index].content = _editRecordController.text;
                        _editing = null;
                        _saveList();
                        _updateCandidateList(_editRecordController.text);
                        _saveCandidates();
                      });
                    },
                  ),
            _editing != index
                ? IconButton(
                    icon: Icon(Icons.delete),
                    iconSize: 24,
                    onPressed: _editing == null
                        ? () {
                            setState(() {
                              _list.removeAt(index);
                              _editing = null;
                              _saveList();
                            });
                          }
                        : null,
                  )
                : IconButton(
                    icon: Icon(Icons.clear),
                    iconSize: 24,
                    onPressed: () {
                      setState(() {
                        _editing = null;
                      });
                    },
                  )
          ],
        ),
      ),
    );

    Widget date = GestureDetector(
        onTap: () => showDatePicker(
                    context: context,
                    firstDate: DateTime(2019, 1, 1),
                    lastDate: DateTime(2099, 12, 31),
                    initialDate: DateTimeUtils.dateTimeFromInt(item.day))
                .then((day) {
              if (day == null) return;
              _list[index].day =
                  DateTimeUtils.yearMonthDayToInt(day.year, day.month, day.day);
              _list.sort(_TimeItem.compare);
              setState(() {});
              _saveList();
            }),
        child: Text(
          DateTimeUtils.dayToStringRelative(item.day),
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ));

    Widget time = GestureDetector(
        onTap: () => showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                        hour: item.time ~/ 60, minute: item.time % 60))
                .then((time) {
              if (time == null) return;
              _list[index].time = time.minute + time.hour * 60;
              _list.sort(_TimeItem.compare);
              setState(() {});
              _saveList();
            }),
        child: Text(
          DateTimeUtils.timeToString(item.time),
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ));

    ret = Column(children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(child: Divider(height: 2)),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: date),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: time),
          Expanded(child: Divider(height: 2)),
        ],
      ),
      ret
    ]);

    return ret;
  }

  Widget buildCandidateItem(BuildContext context, int index) {
    Widget ret = ListTile(
      leading: Icon(Icons.calendar_today),
      title: GestureDetector(
          onTap: _editing != null
              ? null
              : () {
                  _addCurrentTime(_candidates[index]);
                  _candidateToTop(index);
                  _saveCandidates();
                },
          child: Text(_candidates[index])),
      trailing: Container(
        width: 100,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_upward),
              onPressed: () {
                setState(() {
                  _candidateToTop(index);
                  _saveCandidates();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _candidates.removeAt(index);
                  _saveCandidates();
                });
              },
            )
          ],
        ),
      ),
    );

    return ret;
  }

  bool _candidateToTop(int index) {
    if (index < 0 || index >= _candidates.length ||
        _candidates.length < 2 || index == 0) {
      return false;
    }
    String tmp = _candidates[index];
    for (int i = index - 1; i >= 0; i--) {
      _candidates[i + 1] = _candidates[i];
    }
    _candidates[0] = tmp;
    return true;
  }

  String _toCSV(String delimiter) {
    if(_list.isEmpty) return "";
    StringBuffer sb = StringBuffer();
    for(int i = 0; i < _list.length; i++) {
      sb.writeln("${DateTimeUtils.dayToString(_list[i].day)} " +
          "${DateTimeUtils.timeToString(_list[i].time)}$delimiter" +
          "${_list[i].content.replaceAll(delimiter, " ").replaceAll("\n", " ")}");
    }
    return sb.toString();
  }

  void _updateCandidateList(String item) {
    if (item?.isEmpty ?? true) {
      return;
    }
    if (_candidates.indexOf(item) >= 0) {
      _candidateToTop(_candidates.indexOf(item));
      return;
    }
    _candidates.add(item);
    _candidateToTop(_candidates.length - 1);
    while (_candidates.length > _maxCandidatesCount) {
      _candidates.removeLast();
    }
  }
}
