import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alarm_app/notifer.dart';

// タイマーのモード
// ignore: constant_identifier_names
enum TimerMode { Study, Play }

// アプリケーション内で共有する状態
class TimeKeeper extends ChangeNotifier {
  Timer? _timer;
  bool _isTimerStarted = false; // タイマーが実行中かどうか（PlayでもStudyでもOK）
  bool _shouldShowDialog = false; // ダイアログを表示すべきか
  DateTime _playTime = DateTime.utc(0, 0, 0);
  bool _isTimerPaused = false; // タイマーがバックグラウンドで停止中かどうか
  Notifier notifier = Notifier();
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

  set shouldShowDialog(bool shouldShowDialog) {
    _shouldShowDialog = shouldShowDialog;
    notifyListeners();
  }

  DateTime get playTime => _playTime;
  String get playTimeText => DateFormat.Hm().format(_playTime);
  set playTime(DateTime datetime) {
    _playTime = datetime;
    notifyListeners();
  }

  // タイマーを開始する
  void startTimer() {
    _isTimerStarted = true;
    // タイマー起動
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
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
        _handleTimeIsOver();
        notifyListeners();
      },
    );
  }

  // タイマーを停止する
  void stopTimer() {
    _isTimerStarted = false;
    if (_timer != null && _timer!.isActive) _timer!.cancel();
    notifyListeners();
  }

  // タイマー停止・アラーム開始・ダイアログ表示を行う
  // この処理はフォアグラウンドでしか呼ばれないので、ローカル通知は行わない
  void _handleTimeIsOver() async {
    // アラーム時刻と現在時刻が異なる場合はリスナー継続
    if (alarmTime != refTime) {
      return;
    }
    stopTimer();
    _shouldShowDialog = true;
  }

  // アプリがバックグラウンドに遷移した際のタイマーに関連する処理をハンドリング
  // TODO
  void handleOnPaused() {
    // タイマーが起動してない時は何もしない
    // if (!_isTimerStarted) return;
    // startTimer();
  }

  // アプリがフォアグラウンドに復帰した際のタイマーに関連する処理をハンドリング
  // TODO
  void handleOnResumed() {
    // タイマー起動中にバックグラウンド遷移してない場合は何もしない
    //   if (!_isTimerPaused) return;
    //   startTimer();
    //   _isTimerPaused = false;
    //   notifyListeners();
  }
}
