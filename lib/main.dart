import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  _setupTimeZone();
  runApp(const AlarmApp());
}

// タイムゾーンを設定する
Future<void> _setupTimeZone() async {
  tz.initializeTimeZones();
  var tokyo = tz.getLocation('Asia/Tokyo');
  tz.setLocalLocation(tokyo);
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Study Timer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: ChangeNotifierProvider(
          create: (BuildContext context) {},
          child: const AlarmPage(),
        ));
  }
}

class AlarmPage extends StatefulWidget {
  final String title = 'Alarm';
  const AlarmPage({super.key});
  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _isTimerStarted = false; // タイマーが実行中かどうか（PlayでもStudyでもOK）
  bool _shouldShowDialog = false; // ダイアログを表示すべきか
  bool _isTimerPaused = false; // タイマーがバックグラウンドで停止中かどうか
  bool get isTimerStarted => _isTimerStarted;
  bool get shouldShowDialog => _shouldShowDialog;
  DateTime alarmTime = DateTime.utc(0, 0, 0);
  DateTime now = DateTime.now();
  DateFormat timeFormatyyyy = DateFormat('yyyy');
  DateFormat timeFormatMM = DateFormat('MM');
  DateFormat timeFormatdd = DateFormat('dd');
  DateFormat timeFormathh = DateFormat('hh');
  DateFormat timeFormatmm = DateFormat('mm');
  DateTime refTime = DateTime.utc(0, 0, 0);
  DateFormat timeFormatHHmm = DateFormat('HH:mm');
  String _statrStopText = 'Stop';
  late int notificationId; // 通知ID
  late Timer _alarmTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/sample.mp3');
    _controller.initialize().then((_) {
      setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
  }

  set shouldShowDialog(bool shouldShowDialog) {
    _shouldShowDialog = shouldShowDialog;
  }

  // アラームスタート
  void startAlarm() {
    _isTimerStarted = true;
    // タイマー起動（アラーム時刻と現在時刻の監視（ループ））
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        _handleAlerm();
      },
    );
  }

  // タイマーを停止する
  void stopAlarm() {
    _isTimerStarted = false;
    if (_timer != null && _timer!.isActive) _timer!.cancel();
  }

  // アラーム時刻と現在時刻の監視
  void _handleAlerm() async {
    // この処理はフォアグラウンドでしか呼ばれないので、ローカル通知は行わない
    // アラーム時刻と現在時刻が異なる場合はリスナー継続
    now = DateTime.now();
    timeFormatyyyy = DateFormat('yyyy');
    timeFormatMM = DateFormat('MM');
    timeFormatdd = DateFormat('dd');
    timeFormathh = DateFormat('HH');
    timeFormatmm = DateFormat('mm');
    refTime = DateTime.utc(
        int.parse(timeFormatyyyy.format(now)),
        int.parse(timeFormatMM.format(now)),
        int.parse(timeFormatdd.format(now)),
        int.parse(timeFormathh.format(now)),
        int.parse(timeFormatmm.format(now)));
    if (alarmTime != refTime) {
      return;
    }
    stopAlarm();
    _shouldShowDialog = true;
  }

  // アプリがバックグラウンドに遷移した際のハンドラ
  void _handleOnPaused() {
    if (_timer != null && _timer!.isActive) {
      _isTimerPaused = true;
    }
  }

  // アプリがフォアグラウンドに復帰した際のハンドラ
  // void _handleOnResumed() {
  //   // タイマーが動いてなければ何もしない
  //   if (_isTimerPaused == false) return;
  //   _isTimerPaused = false;

  //   // アラームをローカル通知
  //   int _scheduleLocalNotification(Duration duration) {
  //     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //         FlutterLocalNotificationsPlugin();

  //     String? selectedNotificationPayload;

  //     WidgetsFlutterBinding.ensureInitialized();

  //     await _configureLocalTimeZone();

  //     const AndroidInitializationSettings initializationSettingsAndroid =
  //         AndroidInitializationSettings('app_icon');
  //     final IOSInitializationSettings initializationSettingsIOS =
  //         IOSInitializationSettings();
  //     final InitializationSettings initializationSettings =
  //         InitializationSettings(
  //       android: initializationSettingsAndroid,
  //       iOS: initializationSettingsIOS,
  //     );

  //     await flutterLocalNotificationsPlugin.initialize(initializationSettings,
  //         onSelectNotification: (String? payload) async {
  //       if (payload != null) {
  //         debugPrint('notification payload: $payload');
  //       }
  //       selectedNotificationPayload = payload;
  //     });

  //     Future<void> _configureLocalTimeZone() async {
  //       tz.initializeTimeZones();
  //       final String? timeZoneName =
  //           await FlutterNativeTimezone.getLocalTimezone();
  //       tz.setLocalLocation(tz.getLocation(timeZoneName!));
  //     }
  //   }
  // }

  // アプリのライフサイクルが変更された際に実行される処理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // バックグラウンドに遷移時
      _handleOnPaused();
    } else if (state == AppLifecycleState.resumed) {
      // フォアグランドに遷移時
      // _handleOnResumed();
    }
  }

  // フロント
  @override
  Widget build(BuildContext context) {
    String currentTimeHHmm = timeFormatHHmm.format(now);

    // アラームをモーダル
    if (shouldShowDialog) {
      _controller.play(); // 音楽再生
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Time is over.'),
                content: const Text('Please stop the alarm.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Stop Alarm'),
                    onPressed: () {
                      _controller.pause();
                      shouldShowDialog = false;
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
      });
    }

    return Scaffold(
      appBar: AppBar(
        // タイトル
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                  width: double.infinity,
                  child: Text(
                    _statrStopText,
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  )),
              // 現在時刻
              SizedBox(
                  width: double.infinity,
                  child: Text(
                    currentTimeHHmm,
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  )),
              // アラーム時刻
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                height: 60,
                alignment: Alignment.center,
                child: Table(columnWidths: const {
                  0: FixedColumnWidth(100),
                  1: FixedColumnWidth(70),
                }, children: [
                  TableRow(children: [
                    Text("Alarm",
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.start),
                    Text(DateFormat.Hm().format(alarmTime),
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
                        onPressed: () {
                          !isTimerStarted ? () => {stopAlarm()} : null;
                          setState(() {
                            _statrStopText = "Stop";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.redAccent,
                          shape: const CircleBorder(),
                        ),
                        child: const Text('Stop'),
                      )),
                  SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                        onPressed: () {
                          !isTimerStarted ? () => {startAlarm()} : null;
                          setState(() {
                            _statrStopText = "Start";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          shape: const CircleBorder(),
                        ),
                        child: const Text('Start'),
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
                          onPressed: isTimerStarted
                              ? null
                              : () {
                                  Picker(
                                    adapter: DateTimePickerAdapter(
                                        type: PickerDateTimeType.kHM,
                                        value: alarmTime,
                                        customColumnType: [3, 4]),
                                    title: const Text("Select Time"),
                                    onConfirm: (Picker picker, List value) {
                                      alarmTime = DateTime.utc(
                                          int.parse(timeFormatyyyy.format(now)),
                                          int.parse(timeFormatMM.format(now)),
                                          int.parse(timeFormatdd.format(now)),
                                          value[0],
                                          value[1],
                                          0);
                                    },
                                  ).showModal(context);
                                },
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                              shape: const CircleBorder()),
                          child: const Text('set'),
                        ),
                      ])),
            ]),
      ),
    );
  }
}
