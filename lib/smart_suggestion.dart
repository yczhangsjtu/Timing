import 'package:flutter/material.dart';

import 'utils.dart';
import 'settings.dart';

class SmartSuggestionRule {
  final int startTime;
  final int endTime;
  final String afterItem;
  final String itemToAdd;

  SmartSuggestionRule(
      {this.startTime = 0,
        this.endTime = 1439,
        this.afterItem = "",
        this.itemToAdd = ""})
      : assert(startTime != null),
        assert(endTime != null),
        assert(afterItem != null),
        assert(itemToAdd != null);

  factory SmartSuggestionRule.deserialize(String line) {
    if (line == null || line.isEmpty || line.trim().isEmpty) {
      return null;
    }
    final parts = line.split(":");
    if (parts.length != 4) {
      return null;
    }
    final startTime = int.parse(parts[0]);
    final endTime = int.parse(parts[1]);
    if (endTime <= startTime || startTime < 0 || endTime >= 1440) {
      return null;
    }
    return SmartSuggestionRule(
        startTime: startTime,
        endTime: endTime,
        afterItem: decodeBase64String(parts[2]),
        itemToAdd: decodeBase64String(parts[3]));
  }

  SmartSuggestionRule copyWith(
      {int startTime, int endTime, String afterItem, String itemToAdd}) {
    return SmartSuggestionRule(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      afterItem: afterItem ?? this.afterItem,
      itemToAdd: itemToAdd ?? this.itemToAdd,
    );
  }

  String serialize() {
    return "$startTime:$endTime:${encodeBase64String(afterItem)}:${encodeBase64String(itemToAdd)}";
  }

  String display() {
    return "${DateTimeUtils.timeToString(startTime)} - ${DateTimeUtils.timeToString(endTime)}:" +
        " Add $itemToAdd${afterItem.isNotEmpty ? " After $afterItem" : ""}";
  }

  bool match(int time, String lastItem) {
    return startTime <= time &&
        time <= endTime &&
        (afterItem == lastItem || afterItem == "");
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
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveToTop;
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
      this.onMoveUp,
      this.onMoveDown,
      this.onMoveToTop,
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
                              text: rule.afterItem.isEmpty ? "  " : "  After ",
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                      icon: Icon(Icons.vertical_align_top),
                      iconSize: bottomButtonSize,
                      padding: bottomButtonPadding,
                      onPressed: onMoveToTop),
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
            ? () => _removeRule(i)
            : null,
      ));
    }
    return Scaffold(
      appBar: AppBar(title: Text("Smart Suggestion Rules")),
      body: ListView(
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
          DefaultTextStyle(
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.black),
            child: Column(
              children: ruleCards,
            ),
          ),
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
    controllerToAdd.text =
        Settings.smartSuggestionRules[index].itemToAdd;
    setState(() {});
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

  void _removeRule(int index) {
    if (Settings.removeRule(index)) editing = null;
  }
}