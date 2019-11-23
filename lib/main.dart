import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:shake/shake.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as FLN;

import 'smart_suggestion.dart';
import 'settings.dart';
import 'utils.dart';

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
  List<TimeItem> _list = <TimeItem>[];
  List<String> _candidates = <String>["工作", "学习", "休息", "睡觉"];
  List<String> _filteredCandidates = [];
  int _editing;
  TextEditingController _editRecordController;
  ScrollController _recordsController;
  ScrollController _candidatesController;
  double _division = 0;
  static const double _offsetDifference = 200;
  static const int _maxCandidatesCount = 50;
  SharedPreferences prefs;
  Timer _timer;
  static const platform = const MethodChannel("notification_panel");

  ShakeDetector detector;

  void _initializeNotification() {
    FLN.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FLN.FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = FLN.AndroidInitializationSettings('ic_action_alarm');
    var initializationSettingsIOS = FLN.IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = FLN.InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onDidReceiveLocalNotification(int i, String a, String b, String c) async {
  }

  Future onSelectNotification(String payload) async {
  }

  void _showPersistentNotification() async {
    try {
      platform.invokeMethod("show", _getSuggestion());
      platform.setMethodCallHandler(_onReceiveAddFromNotification);
    } on PlatformException catch(e) {
      print(e);
    }
  }

  Future<void> _onReceiveAddFromNotification(MethodCall call) async {
    switch(call.method) {
      case "add":
        final suggestion = _getSuggestion();
        _addCurrentTime(suggestion);
        _showNotification("New Record Added", suggestion);
    }
  }

  void _showNotification(String title, String content) async {
    FLN.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FLN.FlutterLocalNotificationsPlugin();
    var androidPlatformChannelSpecifics = FLN.AndroidNotificationDetails(
        'timing channel id',
        'timing channel name',
        'notify that you have recorded a timing item',
        style: FLN.AndroidNotificationStyle.Default,
        enableLights: true,
        vibrationPattern: Int64List.fromList([0, 1]),
        importance: FLN.Importance.Max,
        priority: FLN.Priority.High,
        ticker: 'ticker');
    var iOSPlatformChannelSpecifics = FLN.IOSNotificationDetails();
    var platformChannelSpecifics = FLN.NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, content, platformChannelSpecifics,
        payload: 'item x');
  }

  void _onSettingsChanged() {
    setState(() {});
    if(prefs.getDouble("ThresholdGravity") != Settings.thresholdGravity) {
      prefs.setDouble("ThresholdGravity", Settings.thresholdGravity);
      _resetShakeDetector();
    }
    _saveRules();
  }

  void _initializeSettings() async {
    Settings.settings = ValueNotifier<SettingsValue>(
        SettingsValue()
    );
  }

  void _resetShakeDetector() async {
    if(detector != null) {
      detector.stopListening();
      detector = null;
    }
    detector = ShakeDetector.autoStart(
        shakeThresholdGravity: Settings.thresholdGravity,
        onPhoneShake: () {
          var suggestion = _getSuggestion();
          _addCurrentTime(suggestion);
          _showNotification("New Record Added", suggestion);
        });
  }

  String _getSuggestion() {
    if(Settings.smartSuggestionRules.isEmpty) {
      return "";
    }
    final now = TimeOfDay.now();
    final current = now.hour * 60 + now.minute;
    final lastItem = _list.isEmpty ? "" : _list[_list.length-1].content;
    for(int i = 0; i < Settings.smartSuggestionRules.length; i++) {
      if(Settings.smartSuggestionRules[i].match(current, _list)) {
        return Settings.smartSuggestionRules[i].itemToAdd;
      }
    }
    return "";
  }

  @override
  void initState() {
    super.initState();
    _editRecordController = TextEditingController();
    _recordsController = ScrollController();
    _candidatesController = ScrollController();
    _recordsController.addListener(_onRecordListScroll);
    _candidatesController.addListener(_onCandidateListScroll);
    _recordsController.addListener(_updateDivision);
    _candidatesController.addListener(_updateDivision);

    _editRecordController.addListener(() {
      setState(() {
        _filteredCandidates = _candidates.where((s) {
          return _editRecordController.text.isEmpty ||
              s.startsWith(_editRecordController.text);
        }).toList();
      });
    });

    _readList();
    _readCandidates();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateDivision();
    });
    _initializeSettings();
    _initializeNotification();
    _timer = Timer.periodic(Duration(seconds: 10), (_) {
      setState(() {});
    });
    _readSettings();
  }

  @override
  void dispose() {
    _editRecordController.dispose();
    _recordsController.dispose();
    _candidatesController.dispose();
    Settings.settings.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _onCandidateListScroll() {
    _recordsController.removeListener(_onRecordListScroll);
    _candidatesController.removeListener(_onCandidateListScroll);
    _recordsController
        .animateTo(0,
            duration: Duration(milliseconds: 100), curve: Curves.easeInOut)
        .whenComplete(() {
      _recordsController.addListener(_onRecordListScroll);
      _candidatesController.addListener(_onCandidateListScroll);
    });
  }

  void _onRecordListScroll() {
    _recordsController.removeListener(_onRecordListScroll);
    _candidatesController.removeListener(_onCandidateListScroll);
    _candidatesController
        .animateTo(0,
            duration: Duration(milliseconds: 100), curve: Curves.easeInOut)
        .whenComplete(() {
      _recordsController.addListener(_onRecordListScroll);
      _candidatesController.addListener(_onCandidateListScroll);
    });
  }

  void _updateDivision() {
    setState(() {
      _division = (_recordsController.offset - _candidatesController.offset)
                  .clamp(-_offsetDifference, _offsetDifference) /
              (2 * _offsetDifference) +
          0.5;
    });
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/record');
  }

  static Future<File> get _localCandidatesFile async {
    final path = await _localPath;
    return File('$path/candidates');
  }

  static Future<File> get _localRulesFile async {
    final path = await _localPath;
    return File('$path/rules');
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
      _list.add(TimeItem(d, t, content));
      _saveList();
      _showPersistentNotification();
    });
  }

  void _readList() async {
    try {
      final file = await _localFile;
      String s = await file.readAsString();
      setState(() {
        _list = s
            .split("\n")
            .map((line) => TimeItem.fromString(line))
            .where((item) => item != null)
            .toList();
        _list.sort(TimeItem.compare);
      });
    } catch (e) {
      setState(() {
        _list = <TimeItem>[];
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

  void _readSettings() async {
    try {
      final file = await _localRulesFile;
      String s = await file.readAsString();
      List<SmartSuggestionRule> rules = [];
      s.split("\n").forEach((line) {
        final rule = SmartSuggestionRule.deserialize(line);
        if(rule != null)
          rules.add(rule);
      });
      Settings.set(smartSuggestionRules: rules);
    } catch (e) {
      print(e);
    } finally {
      Settings.settings.addListener(_onSettingsChanged);
      prefs = prefs ?? await SharedPreferences.getInstance();
      double thresholdGravity = prefs.getDouble("ThresholdGravity");
      Settings.set(thresholdGravity: thresholdGravity);
      _showPersistentNotification();
    }
  }

  void _saveRules() async {
    final file = await _localRulesFile;
    await file.writeAsString(
        Settings.smartSuggestionRules.map((rule) {
          return rule.serialize();
        }).join("\n"));
  }

  void _clear() {
    setState(() {
      _list = <TimeItem>[];
      _saveList();
    });
  }

  @override
  Widget build(BuildContext context) {
    _showPersistentNotification();
    Widget body = Stack(children: <Widget>[
      Positioned.fill(
        child: Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: _division * 0.6 + 0.2,
            widthFactor: 1,
            child: ListView.builder(
                reverse: true,
                controller: _recordsController,
                itemCount: _list.length,
                itemBuilder: (context, i) {
                  i = _list.length - 1 - i;
                  return _buildItem(_list[i], i);
                }),
          ),
        ),
      ),
      Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.8 - _division * 0.6,
            widthFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[200])),
                  boxShadow: <BoxShadow>[BoxShadow()]),
              child: ListView.separated(
                controller: _candidatesController,
                itemCount: (_editing == null
                    ? _candidates.length
                    : _filteredCandidates.length) + 1,
                itemBuilder: (context, index) {
                  if(index == (_editing == null
                      ? _candidates.length
                      : _filteredCandidates.length)) {
                    return Container(height: 100);
                  }
                  return buildCandidateItem(context, index);
                },
                separatorBuilder: (context, index) {
                  if(index == (_editing == null
                      ? _candidates.length
                      : _filteredCandidates.length)) {
                    return Container();
                  }
                  return Divider(height: 1);
                },
              ),
            ),
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
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _editing == null
                  ? () {
                _addCurrentTime("");
                _editing = _list.length - 1;
                _editRecordController.text = "";
                _recordsController.animateTo(0,
                    duration: Duration(milliseconds: 100),
                    curve: Curves.easeInOut);
              } : null,
            ),
            PopupMenuButton<int>(
              onSelected: (result) {
                switch (result) {
                  case 0:
                    if (_list.isNotEmpty) {
                      Share.share(_toCSV(","));
                    }
                    break;
                  case 1:
                    showDialog(
                        context: context,
                        builder: (context) {
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
                  case 2:
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return Settings();
                    }));
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
                  ),
                  PopupMenuItem<int>(
                    value: 2,
                    child: Text('Settings'),
                  )
                ];
              },
            )
          ],
        ),
        body: body,
        floatingActionButton: GestureDetector(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              color: Colors.blueAccent
            ),
            child: Text("+${_getSuggestion()}",
                style: TextStyle(fontSize: 18, height: 1, color: Colors.white))
          ),
          onTap: _editing == null
              ? () {
            final suggestion = _getSuggestion();
            _addCurrentTime(suggestion);
            _updateCandidateList(suggestion);
            _recordsController.animateTo(0,
                duration: Duration(milliseconds: 100),
                curve: Curves.easeInOut);
          }
          : null,
        ),
    );
  }

  Widget _buildItem(TimeItem item, int index) {
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
              _list.sort(TimeItem.compare);
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
              _list.sort(TimeItem.compare);
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
    var list = _editing == null ? _candidates : _filteredCandidates;
    Widget ret = ListTile(
      leading: Icon(Icons.calendar_today),
      title: GestureDetector(
          onTap: _editing != null
              ? () {
                  _editRecordController.value = TextEditingValue(
                      text: list[index],
                      selection:
                          TextSelection.collapsed(offset: list[index].length));
                }
              : () {
                  _addCurrentTime(list[index]);
                  _candidateToTop(index);
                  _saveCandidates();
                },
          child: Text(list[index])),
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
                  list.removeAt(index);
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
    if (index < 0 ||
        index >= _candidates.length ||
        _candidates.length < 2 ||
        index == 0) {
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
    if (_list.isEmpty) return "";
    StringBuffer sb = StringBuffer();
    for (int i = 0; i < _list.length; i++) {
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
