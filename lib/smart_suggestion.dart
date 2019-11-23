import 'package:flutter/material.dart';

import 'utils.dart';
import 'settings.dart';

class SmartSuggestionRule {
  final int startTime;
  final int endTime;
  final String afterItem;
  final String itemToAdd;
  final int days;
  final bool dontRepeat;

  static const String LAST = "LAST";

  SmartSuggestionRule(
      {this.startTime = 0,
      this.endTime = 1439,
      this.afterItem = "",
      this.itemToAdd = "",
      this.days = 127,
      this.dontRepeat = false})
      : assert(startTime != null),
        assert(endTime != null),
        assert(afterItem != null),
        assert(itemToAdd != null),
        assert(days != null && days >= 0 && days <= 127),
        assert(dontRepeat != null);

  factory SmartSuggestionRule.deserialize(String line) {
    if (line == null || line.isEmpty || line.trim().isEmpty) {
      return null;
    }
    final parts = line.split(":");
    if (parts.length < 2) {
      return null;
    }
    final startTime = parts.length <= 0 ? 0 : int.parse(parts[0]);
    final endTime = parts.length <= 1 ? 1439 : int.parse(parts[1]);
    if (endTime <= startTime || startTime < 0 || endTime >= 1440) {
      return null;
    }
    final afterItem = parts.length <= 2 ? "" : decodeBase64String(parts[2]);
    final itemToAdd = parts.length <= 3 ? "" : decodeBase64String(parts[3]);
    final days = parts.length <= 4 ? 127 : int.parse(parts[4]);
    final dontRepeat = parts.length <= 5 ? false : int.parse(parts[5]) == 1;
    return SmartSuggestionRule(
        startTime: startTime,
        endTime: endTime,
        afterItem: afterItem,
        itemToAdd: itemToAdd,
        days: days,
        dontRepeat: dontRepeat);
  }

  SmartSuggestionRule copyWith(
      {int startTime,
      int endTime,
      String afterItem,
      String itemToAdd,
      int days,
      bool dontRepeat}) {
    return SmartSuggestionRule(
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        afterItem: afterItem ?? this.afterItem,
        itemToAdd: itemToAdd ?? this.itemToAdd,
        days: days ?? this.days,
        dontRepeat: dontRepeat ?? this.dontRepeat);
  }

  String serialize() {
    return "$startTime:$endTime:${encodeBase64String(afterItem)}:${encodeBase64String(itemToAdd)}:$days:${dontRepeat ? 1 : 0}";
  }

  String display() {
    return "${DateTimeUtils.timeToString(startTime)} - ${DateTimeUtils.timeToString(endTime)}:" +
        " Add $itemToAdd${afterItem.isNotEmpty ? " After $afterItem" : ""}";
  }

  bool hasDay(int day) {
    return day >= 0 && day <= 6 && (days & (1 << day)) > 0;
  }

  bool match(int time, List<TimeItem> items) {
    if (itemToAdd == LAST && items.length < 2) {
      return false;
    }
    if (dontRepeat && itemToAdd != LAST) {
      for (var item in items) {
        if (startTime <= item.time &&
            item.time <= endTime &&
            item.content == itemToAdd) {
          return false;
        }
      }
    }
    return startTime <= time && time <= endTime &&
        ((items.isNotEmpty && afterItem == items[items.length - 1].content) ||
            afterItem == "") &&
        hasDay(DateTimeUtils.dayOfWeek(DateTimeUtils.today()));
  }
}

class SmartSuggestionRuleCard extends StatelessWidget {
  final SmartSuggestionRule rule;
  final int index;
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onFinishEdit;
  final bool editingAfterItem;
  final TextEditingController controllerAfterItem;
  final VoidCallback onConfirmAfterItem;
  final VoidCallback onCancelAfterItem;
  final VoidCallback onEditAfterItem;
  final bool editingToAdd;
  final TextEditingController controllerToAdd;
  final VoidCallback onConfirmToAdd;
  final VoidCallback onCancelToAdd;
  final VoidCallback onEditToAdd;
  final ValueChanged<int> onUpdateDays;
  final ValueChanged<bool> onUpdateDontRepeat;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveToTop;
  final VoidCallback onMoveToBottom;
  final VoidCallback onRemove;
  final double bottomButtonSize;
  final EdgeInsets bottomButtonPadding;

  SmartSuggestionRuleCard(
      this.rule,
      this.index,
      this.editing,
      this.onEdit,
      this.onFinishEdit,
      this.editingAfterItem,
      this.controllerAfterItem,
      this.onConfirmAfterItem,
      this.onCancelAfterItem,
      this.onEditAfterItem,
      this.editingToAdd,
      this.controllerToAdd,
      this.onConfirmToAdd,
      this.onCancelToAdd,
      this.onEditToAdd,
      this.onUpdateDays,
      this.onUpdateDontRepeat,
      this.onMoveUp,
      this.onMoveDown,
      this.onMoveToTop,
      this.onMoveToBottom,
      this.onRemove,
      {this.bottomButtonSize = 20,
      this.bottomButtonPadding = const EdgeInsets.all(2)});

  Widget _buildDisplay(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 4),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: Colors.grey[300], width: 1))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: RichText(
                    text: TextSpan(
                        text:
                            "${DateTimeUtils.timeToString(rule.startTime, padZero: true)}-${DateTimeUtils.timeToString(rule.endTime, padZero: true)}",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent),
                        children: <TextSpan>[
                      TextSpan(
                          text: rule.afterItem.isEmpty ? "" : " After ",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.black)),
                      TextSpan(
                          text: rule.afterItem,
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.grey)),
                      TextSpan(
                          text: " Add ",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 18,
                              color: Colors.black)),
                      TextSpan(
                          text:
                              rule.itemToAdd.isEmpty ? "Empty" : rule.itemToAdd,
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 18,
                              color: Colors.grey)),
                    ])),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: onEdit,
              )
            ],
          ),
        ));
  }

  Widget _buildEditing(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 16),
      child: Card(
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text("Start Time: "),
                  Expanded(
                    child: Text(
                      DateTimeUtils.timeToString(rule.startTime),
                      style: TextStyle(fontFamily: "Courier"),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: rule.startTime ~/ 60,
                                  minute: rule.startTime % 60))
                          .then((time) {
                        if (time == null) return;
                        Settings.setRuleStartTime(
                            this.index, time.minute + time.hour * 60);
                      });
                    },
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  Text("End Time: "),
                  Expanded(
                    child: Text(
                      DateTimeUtils.timeToString(rule.endTime),
                      style: TextStyle(fontFamily: "Courier"),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: rule.endTime ~/ 60,
                                  minute: rule.endTime % 60))
                          .then((time) {
                        if (time == null) return;
                        Settings.setRuleEndTime(
                            this.index, time.minute + time.hour * 60);
                      });
                    },
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  Text("After: "),
                  Expanded(
                    child: editingAfterItem
                        ? TextField(controller: controllerAfterItem)
                        : Text(rule.afterItem),
                  ),
                  editingAfterItem
                      ? Row(
                          children: <Widget>[
                            IconButton(
                                icon: Icon(Icons.check),
                                onPressed: onConfirmAfterItem),
                            IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: onCancelAfterItem)
                          ],
                        )
                      : IconButton(
                          icon: Icon(Icons.edit), onPressed: onEditAfterItem)
                ],
              ),
              Row(
                children: <Widget>[
                  Text("To Add: "),
                  Expanded(
                    child: editingToAdd
                        ? TextField(controller: controllerToAdd)
                        : Text(rule.itemToAdd),
                  ),
                  editingToAdd
                      ? Row(
                          children: <Widget>[
                            IconButton(
                                icon: Icon(Icons.check),
                                onPressed: onConfirmToAdd),
                            IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: onCancelToAdd)
                          ],
                        )
                      : IconButton(
                          icon: Icon(Icons.edit), onPressed: onEditToAdd)
                ],
              ),
              Wrap(
                children: [0, 1, 2, 3, 4, 5, 6].map((day) {
                  return Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    Checkbox(
                        value: rule.hasDay(day),
                        onChanged: (bool value) {
                          onUpdateDays(value
                              ? rule.days | (1 << day)
                              : rule.days & (~(1 << day)));
                        }),
                    Text(DateTimeUtils.weekDayName(day))
                  ]);
                }).toList(),
              ),
              Row(
                children: <Widget>[
                  Text("Don't Repeat: "),
                  Checkbox(
                    value: rule.dontRepeat,
                    onChanged: (bool value) {
                      onUpdateDontRepeat(value);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                      icon: Icon(Icons.vertical_align_top),
                      iconSize: bottomButtonSize,
                      padding: bottomButtonPadding,
                      onPressed: onMoveToTop),
                  IconButton(
                      icon: Icon(Icons.vertical_align_bottom),
                      iconSize: bottomButtonSize,
                      padding: bottomButtonPadding,
                      onPressed: onMoveToBottom),
                  IconButton(
                      icon: Icon(Icons.keyboard_arrow_up),
                      iconSize: bottomButtonSize,
                      padding: bottomButtonPadding,
                      onPressed: onMoveUp),
                  IconButton(
                      icon: Icon(Icons.keyboard_arrow_down),
                      iconSize: bottomButtonSize,
                      padding: bottomButtonPadding,
                      onPressed: onMoveDown),
                  IconButton(
                      icon: Icon(Icons.delete),
                      iconSize: bottomButtonSize,
                      padding: bottomButtonPadding,
                      onPressed: onRemove),
                ],
              ),
              ButtonBar(
                children: <Widget>[
                  FlatButton(
                      child: Text(
                        "OK",
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                      padding: bottomButtonPadding,
                      onPressed: onFinishEdit),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return editing ? _buildEditing(context) : _buildDisplay(context);
  }
}

class SmartRulesPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SmartRulesPageState();
  }
}

class _SmartRulesPageState extends State<SmartRulesPage> {
  TextEditingController controllerAfterItem;
  TextEditingController controllerToAdd;
  int editing;
  int editingAfterItem;
  int editingToAdd;

  @override
  void initState() {
    super.initState();
    Settings.settings.addListener(_onSettingsChanged);
    controllerAfterItem = TextEditingController();
    controllerToAdd = TextEditingController();
  }

  @override
  void dispose() {
    controllerAfterItem.dispose();
    controllerToAdd.dispose();
    Settings.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<SmartSuggestionRuleCard> ruleCards = [];
    for (int i = 0; i < Settings.smartSuggestionRules.length; i++) {
      ruleCards.add(SmartSuggestionRuleCard(
        Settings.smartSuggestionRules[i],
        i,
        editing == i,
        editing == null ? () => _editRule(i) : null,
        editingAfterItem == null && editingToAdd == null
            ? _finishEditRule
            : null,
        editingAfterItem == i,
        controllerAfterItem,
        () => _finishEditAfterItem(i),
        _cancelEditAfterItem,
        editing == i && editingAfterItem == null
            ? () => _editAfterItem(i)
            : null,
        editingToAdd == i,
        controllerToAdd,
        () => _finishEditToAddItem(i),
        _cancelEditToAddItem,
        editing == i && editingToAdd == null ? () => _editToAddItem(i) : null,
        (days) => _onEditDays(i, days),
        (dontRepeat) => _onUpdateDontRepeat(i, dontRepeat),
        editingToAdd == null && editingAfterItem == null
            ? () => _moveRuleUp(i)
            : null,
        editingToAdd == null && editingAfterItem == null
            ? () => _moveRuleDown(i)
            : null,
        editingToAdd == null && editingAfterItem == null
            ? () => _moveRuleToTop(i)
            : null,
        editingToAdd == null && editingAfterItem == null
            ? () => _moveRuleToBottom(i)
            : null,
        editingToAdd == null && editingAfterItem == null
            ? () => _removeRule(i)
            : null,
      ));
    }
    return Scaffold(
      appBar: AppBar(title: Text("Smart Suggestion Rules")),
      body: Column(
        children: <Widget>[
          editing == null
              ? GestureDetector(
                  onTap: () {
                    Settings.addRule(SmartSuggestionRule(), index: 0);
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: 16),
                    height: 48,
                    child: Center(
                        child: Icon(
                      Icons.add,
                      size: 32,
                      color: Colors.blueAccent,
                    )),
                  ),
                )
              : Container(),
          Flexible(
            child: DefaultTextStyle(
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.black),
              child: ListView(
                children: ruleCards,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _editRule(int index) {
    editing = index;
    setState(() {});
  }

  void _finishEditRule() {
    editing = null;
    setState(() {});
  }

  void _finishEditAfterItem(int index) {
    editingAfterItem = null;
    Settings.setRuleAfterItem(index, controllerAfterItem.text);
  }

  void _cancelEditAfterItem() {
    editingAfterItem = null;
    setState(() {});
  }

  void _editAfterItem(int index) {
    editingAfterItem = index;
    controllerAfterItem.text = Settings.smartSuggestionRules[index].afterItem;
    setState(() {});
  }

  void _finishEditToAddItem(int index) {
    editingToAdd = null;
    Settings.setRuleItemToAdd(index, controllerToAdd.text);
  }

  void _cancelEditToAddItem() {
    editingToAdd = null;
    setState(() {});
  }

  void _editToAddItem(int index) {
    editingToAdd = index;
    controllerToAdd.text = Settings.smartSuggestionRules[index].itemToAdd;
    setState(() {});
  }

  void _onEditDays(int index, int days) {
    Settings.setRuleDays(index, days);
  }

  void _onUpdateDontRepeat(int index, bool value) {
    Settings.setDontRepeat(index, value);
  }

  void _moveRuleUp(int index) {
    if (Settings.switchRule(index - 1)) editing = index - 1;
  }

  void _moveRuleDown(int index) {
    if (Settings.switchRule(index)) editing = index + 1;
  }

  void _moveRuleToTop(int index) {
    editing = Settings.moveRuleToTop(index);
  }

  void _moveRuleToBottom(int index) {
    editing = Settings.moveRuleToBottom(index);
  }

  void _removeRule(int index) {
    if (Settings.removeRule(index)) editing = null;
  }
}
