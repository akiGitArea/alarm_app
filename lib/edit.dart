import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:alarm_app/timeKeeper.dart';

/// 編集ページ
class EditPage extends StatefulWidget {
  final String title = 'Edit';
  const EditPage({super.key});
  @override
  _EditPageState createState() => _EditPageState();
}

/// タイマーページの状態を管理するクラス
class _EditPageState extends State<EditPage> {
  bool _isChanged = false;

  @override
  Widget build(BuildContext context) {
    TimeKeeper timeKeeper = context.watch<TimeKeeper>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                  width: 200,
                  child: Row(children: [
                    const Text(
                      "Alerm Time:",
                    ),
                    TextButton(
                      child: const Text(
                        'edit',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      onPressed: () {
                        Picker(
                          adapter: DateTimePickerAdapter(
                              type: PickerDateTimeType.kHM,
                              value: timeKeeper.alarmTime,
                              customColumnType: [3, 4]),
                          title: const Text("Select Time"),
                          onConfirm: (Picker picker, List value) {
                            // ignore: unnecessary_set_literal
                            setState(() => {
                                  timeKeeper.alarmTime = DateTime.utc(
                                      int.parse(timeKeeper.timeFormatyyyy
                                          .format(timeKeeper.now)),
                                      int.parse(timeKeeper.timeFormatMM
                                          .format(timeKeeper.now)),
                                      int.parse(timeKeeper.timeFormatdd
                                          .format(timeKeeper.now)),
                                      value[0],
                                      value[1],
                                      0)
                                });
                          },
                        ).showModal(context);
                        _isChanged = true;
                      },
                    )
                  ])),
              SizedBox(
                child: Text(
                  DateFormat.Hm().format(timeKeeper.alarmTime),
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                          onPressed: () => {Navigator.pop(context)},
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blueGrey,
                            shape: const CircleBorder(),
                          ),
                          child: const Text('Cancel'))),
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                          onPressed: !_isChanged
                              ? null
                              : () {
                                  timeKeeper.playTime = timeKeeper.alarmTime;
                                  Navigator.pop(context);
                                },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            shape: const CircleBorder(),
                          ),
                          child: const Text('Save'))),
                ],
              ),
            ]),
      ),
    );
  }
}
