import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SettingsState();
  }

}

class _SettingsState extends State<Settings> {

  static const double _defaultThresholdGravity = 3.5;
  double thresholdGravity = _defaultThresholdGravity;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      thresholdGravity = prefs.getDouble("ThresholdGravity") ?? _defaultThresholdGravity;
    });
  }

  void _save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble("ThresholdGravity", thresholdGravity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Shake Detector Threshold", style: TextStyle(fontSize: 12)),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                  child: Slider(
                    value: thresholdGravity,
                    min: 0.5,
                    max: 10.0,
                    divisions: 95,
                    label: thresholdGravity.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        thresholdGravity = value;
                        _save();
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

}