import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'smart_suggestion.dart';

class SettingsValue {
  final double thresholdGravity;
  List<SmartSuggestionRule> smartSuggestionRules;

  static const double _defaultThresholdGravity = 3.5;

  SettingsValue(
      {this.thresholdGravity = _defaultThresholdGravity,
      List<SmartSuggestionRule> smartSuggestionRules})
      : assert(thresholdGravity != null),
        this.smartSuggestionRules = smartSuggestionRules ?? [];

  SettingsValue copyWith(
      {double thresholdGravity,
      List<SmartSuggestionRule> smartSuggestionRules}) {
    return SettingsValue(
        thresholdGravity: thresholdGravity ?? this.thresholdGravity,
        smartSuggestionRules:
            smartSuggestionRules ?? this.smartSuggestionRules);
  }
}


class Settings extends StatefulWidget {
  static ValueNotifier<SettingsValue> settings;

  static double get thresholdGravity {
    return settings.value.thresholdGravity;
  }

  static List<SmartSuggestionRule> get smartSuggestionRules {
    return settings.value.smartSuggestionRules;
  }

  static void set(
      {double thresholdGravity,
      List<SmartSuggestionRule> smartSuggestionRules}) {
    if (smartSuggestionRules == null &&
        (thresholdGravity == null ||
            thresholdGravity == Settings.thresholdGravity)) {
      return;
    }
    settings.value = settings.value.copyWith(
        thresholdGravity: thresholdGravity,
        smartSuggestionRules: smartSuggestionRules);
  }

  static void setRule(int index, SmartSuggestionRule rule) {
    if (Settings.smartSuggestionRules.length > index && index >= 0) {
      Settings.smartSuggestionRules[index] = rule;
      set(smartSuggestionRules: Settings.smartSuggestionRules);
    }
  }

  static void addRule(SmartSuggestionRule rule, {int index}) {
    if (index == null ||
        index < 0 ||
        index > Settings.smartSuggestionRules.length) {
      Settings.smartSuggestionRules.add(rule);
    }
    Settings.smartSuggestionRules.insert(index, rule);
    set(smartSuggestionRules: Settings.smartSuggestionRules);
  }

  static bool switchRule(int index) {
    if (Settings.smartSuggestionRules.length - 1 > index && index >= 0) {
      final rule = Settings.smartSuggestionRules[index];
      Settings.smartSuggestionRules[index] =
          Settings.smartSuggestionRules[index + 1];
      Settings.smartSuggestionRules[index + 1] = rule;
      set(smartSuggestionRules: Settings.smartSuggestionRules);
      return true;
    }
    return false;
  }

  static int moveRuleToTop(int index) {
    if (Settings.smartSuggestionRules.length > index && index > 0) {
      final rule = Settings.smartSuggestionRules[index];
      for (int i = index; i > 0; i--) {
        Settings.smartSuggestionRules[i] = Settings.smartSuggestionRules[i - 1];
      }
      Settings.smartSuggestionRules[0] = rule;
      set(smartSuggestionRules: Settings.smartSuggestionRules);
      return 0;
    }
    return index;
  }

  static bool removeRule(int index) {
    if (Settings.smartSuggestionRules.length > index && index >= 0) {
      Settings.smartSuggestionRules.removeAt(index);
      set(smartSuggestionRules: Settings.smartSuggestionRules);
      return true;
    }
    return false;
  }

  static void setRuleStartTime(int index, int startTime) {
    if (Settings.smartSuggestionRules.length > index && index >= 0) {
      final rule = Settings.smartSuggestionRules[index];
      if (rule.endTime > startTime && startTime >= 0) {
        setRule(index, rule.copyWith(startTime: startTime));
      }
    }
  }

  static void setRuleEndTime(int index, int endTime) {
    if (Settings.smartSuggestionRules.length > index && index >= 0) {
      final rule = Settings.smartSuggestionRules[index];
      if (rule.startTime < endTime && endTime < 1440) {
        setRule(index, rule.copyWith(endTime: endTime));
      }
    }
  }

  static void setRuleAfterItem(int index, String afterItem) {
    if (Settings.smartSuggestionRules.length > index &&
        index >= 0 &&
        afterItem != null) {
      final rule = Settings.smartSuggestionRules[index];
      setRule(index, rule.copyWith(afterItem: afterItem));
    }
  }

  static void setRuleItemToAdd(int index, String itemToAdd) {
    if (Settings.smartSuggestionRules.length > index &&
        index >= 0 &&
        itemToAdd != null) {
      final rule = Settings.smartSuggestionRules[index];
      setRule(index, rule.copyWith(itemToAdd: itemToAdd));
    }
  }

  static void setRuleDays(int index, int days) {
    if (Settings.smartSuggestionRules.length > index &&
        index >= 0 && days != null) {
      final rule = Settings.smartSuggestionRules[index];
      setRule(index, rule.copyWith(days: days));
    }
  }

  @override
  State<StatefulWidget> createState() {
    return _SettingsState();
  }
}

class _SettingsState extends State<Settings> {
  double _thresholdGravity;

  @override
  void initState() {
    super.initState();
    _thresholdGravity = Settings.thresholdGravity;
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Settings.set(thresholdGravity: _thresholdGravity);
        });
        return new Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
        ),
        body: DefaultTextStyle(
          style: TextStyle(
              fontSize: 18, color: Colors.black),
          child: Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Shake Detector Threshold"),
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                        child: Slider(
                          value: _thresholdGravity,
                          min: 0.5,
                          max: 10.0,
                          divisions: 95,
                          label: _thresholdGravity.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _thresholdGravity = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(
                        color: Colors.grey[300], width: 1)),
                    color: Colors.white
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                        return SmartRulesPage();
                      }));
                    },
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text("Smart Suggestion Rules"),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey)
                      ],
                    )
                  )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

}
