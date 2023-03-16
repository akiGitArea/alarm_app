import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alerm_2/timeKeeper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:video_player/video_player.dart';

// import 'alarm.dart';
import 'edit.dart';

void main() async {
  _setupTimeZone();
  runApp(const TimerApp());
}

// タイムゾーンを設定する
Future<void> _setupTimeZone() async {
  tz.initializeTimeZones();
  var tokyo = tz.getLocation('Asia/Tokyo');
  tz.setLocalLocation(tokyo);
}

/// タイマーアプリ
class TimerApp extends StatelessWidget {
  const TimerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Study Timer', // Webアプリとして実行した際のページタイトル
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: ChangeNotifierProvider(
          create: (context) => TimeKeeper(),
          child: const TimerPage(),
        ));
  }
}

/// タイマーページ
class TimerPage extends StatefulWidget {
  final String title = 'Study Timer';
  const TimerPage({super.key});
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/sample.mp3');
    _controller.initialize().then((_) {
      setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
  }

  /// アプリのライフサイクルが変更された際に実行される処理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    TimeKeeper timeKeeper = context.read<TimeKeeper>();
    if (state == AppLifecycleState.paused) {
      timeKeeper.handleOnPaused();
    } else if (state == AppLifecycleState.resumed) {
      timeKeeper.handleOnResumed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TimeKeeper timeKeeper = context.watch<TimeKeeper>();

    /// 編集画面を表示する
    void startEdit() {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
                  value: timeKeeper,
                  child: EditPage(),
                )),
      );
    }

    /// タイマー終了通知をダイアログ表示
    if (timeKeeper.shouldShowDialog) {
      // 音楽再生
      _controller.play();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            barrierDismissible: false, // ダイアログの外をタップしてダイアログを閉じれないように
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Time is over.'),
                content: const Text('Please stop the alarm.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Stop Alarm'),
                    onPressed: () {
                      _controller.pause();
                      timeKeeper.shouldShowDialog = false;
                      Navigator.of(context).pop(); // これをやらないとダイアログが閉じない
                    },
                  ),
                ],
              );
            });
      });
    }

    /// リセットダイアログを表示
    void showResetDialog() {
      showDialog(
          context: context,
          barrierDismissible: false, // ダイアログの外をタップしてダイアログを閉じれないように
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm'),
              content: const Text('Are you sure you want to reset timer ?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // これをやらないとダイアログが閉じない
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    timeKeeper.stopTimer();
                    timeKeeper.studyTime = DateTime.utc(0, 0, 0);
                    timeKeeper.playTime = DateTime.utc(0, 0, 0);

                    Navigator.of(context).pop(); // これをやらないとダイアログが閉じない
                  },
                ),
              ],
            );
          });
    }

    return Scaffold(
      appBar: AppBar(
        // ステートが所属するwidget情報には`widget`でアクセスできる
        title: Text(widget.title),
      ),
      body: Center(
        // 一つの子を持ち、中央に配置するレイアウト用のwidget
        child: Column(
            // 複数の子を持ち、縦方向に並べるwidget
            // Flutter DevToolsを開いて、Debug Printを有効にすると各Widgetの骨組みを確認できる
            mainAxisAlignment: MainAxisAlignment.center, // 主軸（縦軸）方向に中央寄せ
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                  width: double.infinity,
                  child: Text(
                    timeKeeper.totalTimeText,
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  )),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                height: 60,
                alignment: Alignment.center,
                child: Table(columnWidths: const {
                  0: FixedColumnWidth(100),
                  1: FixedColumnWidth(70),
                }, children: [
                  TableRow(children: [
                    Text("Studied Time:",
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.start),
                    Text(timeKeeper.studyTimeText,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.start),
                  ]),
                  TableRow(children: [
                    Text("Played Time:",
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.start),
                    Text(timeKeeper.playTimeText,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.start),
                  ])
                ]),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                          // FloatingActionButton だと、disabledの制御ができない
                          onPressed: !timeKeeper.isTimerStarted
                              ? () => {timeKeeper.startTimer(TimerMode.Play)}
                              : null, // nullを指定すると無効化
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            shape: const CircleBorder(),
                            side: timeKeeper.timerMode == TimerMode.Play
                                ? const BorderSide(color: Colors.red, width: 3)
                                : BorderSide.none,
                          ),
                          // FloatingActionButton だと、disabledの制御ができない
                          child: const Text('Play'))),
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                        onPressed: timeKeeper.isTimerStarted
                            ? timeKeeper.stopTimer
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueGrey,
                          shape: const CircleBorder(),
                        ),
                        child: const Text('Stop'),
                      )),
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                        onPressed: !timeKeeper.isTimerStarted
                            ? () => {timeKeeper.startTimer(TimerMode.Study)}
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          shape: const CircleBorder(),
                          side: timeKeeper.timerMode == TimerMode.Study
                              ? const BorderSide(color: Colors.blue, width: 3)
                              : BorderSide.none,
                        ),
                        child: const Text('Study'),
                      ))
                ],
              ),
              Container(
                  width: double.infinity,
                  alignment: Alignment.bottomRight,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              timeKeeper.isTimerStarted ? null : startEdit,
                          child: const Text(
                            'edit',
                            style:
                                TextStyle(decoration: TextDecoration.underline),
                          ),
                        ),
                        TextButton(
                          onPressed: showResetDialog,
                          child: const Text(
                            'reset',
                            style:
                                TextStyle(decoration: TextDecoration.underline),
                          ),
                        ),
                      ])),
            ]),
      ),
    );
  }
}