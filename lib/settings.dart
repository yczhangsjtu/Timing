import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'utils.dart';

class SettingsValue {
  final double thresholdGravity;
  List<SmartSuggestionRule> smartSuggestionRules;

  static const double _defaultThresholdGravity = 3.5;

  SettingsValue({
    this.thresholdGravity = _defaultThresholdGravity,
    List<SmartSuggestionRule> smartSuggestionRules}) :
  assert(thresholdGravity != null),
  this.smartSuggestionRules = smartSuggestionRules ?? [];

  SettingsValue copyWith({
    double thresholdGravity,
    List<SmartSuggestionRule> smartSuggestionRules
  }) {
    return SettingsValue(
      thresholdGravity: thresholdGravity ?? this.thresholdGravity,
      smartSuggestionRules: smartSuggestionRules ?? this.smartSuggestionRules
    );
  }
}

class SmartSuggestionRule {
  final int startTime;
  final int endTime;
  final String previousItem;
  final String itemToAdd;
  SmartSuggestionRule({
      this.startTime = 0,
      this.endTime = 1439,
      this.previousItem = "",
      this.itemToAdd = ""}) :
  assert(startTime != null),
  assert(endTime != null),
  assert(previousItem != null),
  assert(itemToAdd != null);

  SmartSuggestionRule copyWith({
    int startTime,
    int endTime,
    String previousItem,
    String itemToAdd}) {
    return SmartSuggestionRule(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      previousItem: previousItem ?? this.previousItem,
      itemToAdd: itemToAdd ?? this.itemToAdd,
    );
  }

  String serialize() {
    return "$startTime:$endTime:${encodeBase64String(previousItem)}:${encodeBase64String(itemToAdd)}";
  }

  bool match(int time, String lastItem) {
    return startTime <= time && time <= endTime &&
        (previousItem == lastItem || previousItem == "");
  }
}

class SmartSuggestionRuleCard extends StatelessWidget {
  final SmartSuggestionRule rule;
  final int index;
  final bool editingPrevious;
  final TextEditingController controllerPrevious;
  final VoidCallback onConfirmPrevious;
  final VoidCallback onCancelPrevious;
  final VoidCallback onEditPrevious;
  final bool editingToAdd;
  final TextEditingController controllerToAdd;
  final VoidCallback onConfirmToAdd;
  final VoidCallback onCancelToAdd;
  final VoidCallback onEditToAdd;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveToTop;
  final VoidCallback onRemove;
  SmartSuggestionRuleCard(
    this.rule,
    this.index,
    this.editingPrevious,
    this.controllerPrevious,
    this.onConfirmPrevious,
    this.onCancelPrevious,
    this.onEditPrevious,
    this.editingToAdd,
    this.controllerToAdd,
    this.onConfirmToAdd,
    this.onCancelToAdd,
    this.onEditToAdd,
    this.onMoveUp,
    this.onMoveDown,
    this.onMoveToTop,
    this.onRemove);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 16),
      child: Card(
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Row(children: <Widget>[
                  Text("Start Time: "),
                  Expanded(
                    child: Text(DateTimeUtils.timeToString(rule.startTime),
                      style: TextStyle(fontFamily: "Courier"),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                              hour: rule.startTime ~/ 60, minute: rule.startTime % 60))
                          .then((time) {
                        if (time == null) return;
                        Settings.setRuleStartTime(this.index, time.minute + time.hour * 60);
                      });
                    },
                  )
                ],
              ),
              Row(children: <Widget>[
                  Text("End Time: "),
                  Expanded(
                    child: Text(DateTimeUtils.timeToString(rule.endTime),
                      style: TextStyle(fontFamily: "Courier"),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                              hour: rule.endTime ~/ 60, minute: rule.endTime % 60))
                          .then((time) {
                        if (time == null) return;
                        Settings.setRuleEndTime(this.index, time.minute + time.hour * 60);
                      });
                    },
                  )
                ],
              ),
              Row(children: <Widget>[
                Text("Previous: "),
                Expanded(
                  child: editingPrevious
                      ? TextField(controller: controllerPrevious)
                      : Text(rule.previousItem),
                ),
                editingPrevious
                  ? Row(
                      children: <Widget>[
                        IconButton(icon: Icon(Icons.check), onPressed: onConfirmPrevious),
                        IconButton(icon: Icon(Icons.clear), onPressed: onCancelPrevious)
                      ],
                    )
                  : IconButton(icon: Icon(Icons.edit), onPressed: onEditPrevious)
              ],),
              Row(children: <Widget>[
                Text("To Add: "),
                Expanded(
                  child: editingToAdd
                      ? TextField(controller: controllerToAdd)
                      : Text(rule.itemToAdd),
                ),
                editingToAdd
                    ? Row(
                  children: <Widget>[
                    IconButton(icon: Icon(Icons.check), onPressed: onConfirmToAdd),
                    IconButton(icon: Icon(Icons.clear), onPressed: onCancelToAdd)
                  ],
                )
                    : IconButton(icon: Icon(Icons.edit), onPressed: onEditToAdd)
              ],),
              ButtonBar(
                children: <Widget>[
                  IconButton(icon: Icon(Icons.vertical_align_top), onPressed: onMoveToTop),
                  IconButton(icon: Icon(Icons.keyboard_arrow_up), onPressed: onMoveUp),
                  IconButton(icon: Icon(Icons.keyboard_arrow_down), onPressed: onMoveDown),
                  IconButton(icon: Icon(Icons.delete), onPressed: onRemove),
                ],
              )
            ],
          ),
        ),
      ),
    );
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

  static void set({
    double thresholdGravity,
    List<SmartSuggestionRule> smartSuggestionRules
  }) {
    if(smartSuggestionRules == null &&
       (thresholdGravity == null || thresholdGravity == Settings.thresholdGravity)) {
      return;
    }
    settings.value = settings.value.copyWith(
      thresholdGravity: thresholdGravity,
      smartSuggestionRules: smartSuggestionRules
    );
  }

  static void setRule(int index, SmartSuggestionRule rule) {
    if(Settings.smartSuggestionRules.length > index && index >= 0) {
      Settings.smartSuggestionRules[index] = rule;
      set(smartSuggestionRules: Settings.smartSuggestionRules);
    }
  }

  static void addRule(SmartSuggestionRule rule) {
    Settings.smartSuggestionRules.add(rule);
    set(smartSuggestionRules: Settings.smartSuggestionRules);
  }

  static void switchRule(int index) {
    if(Settings.smartSuggestionRules.length-1 > index && index >= 0) {
      final rule = Settings.smartSuggestionRules[index];
      Settings.smartSuggestionRules[index] = Settings.smartSuggestionRules[index+1];
      Settings.smartSuggestionRules[index+1] = rule;
      set(smartSuggestionRules: Settings.smartSuggestionRules);
    }
  }

  static void moveRuleToTop(int index) {
    if(Settings.smartSuggestionRules.length > index && index > 0) {
      final rule = Settings.smartSuggestionRules[index];
      for(int i = index; i > 0; i--) {
        Settings.smartSuggestionRules[i] = Settings.smartSuggestionRules[i-1];
      }
      Settings.smartSuggestionRules[0] = rule;
      set(smartSuggestionRules: Settings.smartSuggestionRules);
    }
  }

  static void removeRule(int index) {
    if(Settings.smartSuggestionRules.length > index && index >= 0) {
      Settings.smartSuggestionRules.removeAt(index);
      set(smartSuggestionRules: Settings.smartSuggestionRules);
    }
  }

  static void setRuleStartTime(int index, int startTime) {
    if(Settings.smartSuggestionRules.length > index && index >= 0) {
      final rule = Settings.smartSuggestionRules[index];
      if(rule.endTime > startTime && startTime >= 0) {
        setRule(index, rule.copyWith(startTime: startTime));
      }
    }
  }

  static void setRuleEndTime(int index, int endTime) {
    if(Settings.smartSuggestionRules.length > index && index >= 0) {
      final rule = Settings.smartSuggestionRules[index];
      if(rule.startTime < endTime && endTime < 1440) {
        setRule(index, rule.copyWith(endTime: endTime));
      }
    }
  }

  static void setRulePreviousItem(int index, String previousItem) {
    if(Settings.smartSuggestionRules.length > index && index >= 0 && previousItem != null) {
      final rule = Settings.smartSuggestionRules[index];
      setRule(index, rule.copyWith(previousItem: previousItem));
    }
  }

  static void setRuleItemToAdd(int index, String itemToAdd) {
    if(Settings.smartSuggestionRules.length > index && index >= 0 && itemToAdd != null) {
      final rule = Settings.smartSuggestionRules[index];
      setRule(index, rule.copyWith(itemToAdd: itemToAdd));
    }
  }

  @override
  State<StatefulWidget> createState() {
    return _SettingsState();
  }
}

class _SettingsState extends State<Settings> {

  double _thresholdGravity;
  TextEditingController controllerPrevious;
  TextEditingController controllerToAdd;
  int editingPrevious;
  int editingToAdd;

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _thresholdGravity = Settings.thresholdGravity;
    Settings.settings.addListener(_onSettingsChanged);
    controllerPrevious = TextEditingController();
    controllerToAdd = TextEditingController();
  }

  @override
  void dispose() {
    controllerPrevious.dispose();
    controllerToAdd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<SmartSuggestionRuleCard> ruleCards = [];
    for(int i = 0; i < Settings.smartSuggestionRules.length; i++) {
      ruleCards.add(SmartSuggestionRuleCard(
        Settings.smartSuggestionRules[i],
        i,
        editingPrevious == i,
        controllerPrevious,
        () {
          editingPrevious = null;
          Settings.setRulePreviousItem(i, controllerPrevious.text);
        },
        () {
          editingPrevious = null;
          setState(() {});
        },
        () {
          editingPrevious = i;
          controllerPrevious.text = Settings.smartSuggestionRules[i].previousItem;
          setState(() {});
        },
        editingToAdd == i,
        controllerToAdd,
        () {
          editingToAdd = null;
          Settings.setRuleItemToAdd(i, controllerToAdd.text);
        },
        () {
          editingToAdd = null;
          setState(() {});
        },
        () {
          editingToAdd = i;
          controllerToAdd.text = Settings.smartSuggestionRules[i].itemToAdd;
          setState(() {});
        },
        editingToAdd == null && editingPrevious == null ? () {
          Settings.switchRule(i-1);
        } : null,
        editingToAdd == null && editingPrevious == null ? () {
          Settings.switchRule(i);
        } : null,
        editingToAdd == null && editingPrevious == null ? () {
          Settings.moveRuleToTop(i);
        } : null,
        editingToAdd == null && editingPrevious == null ? () {
          Settings.removeRule(i);
        } : null,
      ));
    }
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
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          child: ListView(
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Shake Detector Threshold"),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Smart Suggestion Rules"),
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black
                      ),
                      child: Column(
                        children: ruleCards,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Settings.addRule(SmartSuggestionRule());
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 16),
                        height: 48,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 2),
                            color: Colors.grey[300]
                        ),
                        child: Center(child: Icon(Icons.add, size: 32)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

}