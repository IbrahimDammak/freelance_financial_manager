import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/work_session.dart';
import '../utils.dart';

class TimerConflictException implements Exception {
  TimerConflictException(this.projectName);

  final String? projectName;
}

class TimerProvider extends ChangeNotifier {
  bool isRunning = false;
  String? activeProjectId;
  String? activeClientId;
  String? activeProjectName;
  DateTime? startTime;
  int elapsedSeconds = 0;
  Timer? _ticker;

  void startTimer(String clientId, String projectId, String projectName) {
    if (isRunning) {
      throw TimerConflictException(activeProjectName);
    }
    _ticker?.cancel();
    isRunning = true;
    activeClientId = clientId;
    activeProjectId = projectId;
    activeProjectName = projectName;
    startTime = DateTime.now();
    elapsedSeconds = 0;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds += 1;
      notifyListeners();
    });
    notifyListeners();
  }

  WorkSession stopTimer() {
    final savedClientId = activeClientId;
    final savedProjectId = activeProjectId;
    if (!isRunning || savedClientId == null || savedProjectId == null) {
      throw StateError('No active timer to stop.');
    }
    _ticker?.cancel();
    final mins = max(1, (elapsedSeconds / 60).round());

    final session = WorkSession()
      ..id = const Uuid().v4()
      ..date = todayStr()
      ..durationMins = mins
      ..note = 'Live session';

    isRunning = false;
    activeClientId = null;
    activeProjectId = null;
    activeProjectName = null;
    startTime = null;
    elapsedSeconds = 0;
    _ticker = null;
    notifyListeners();

    return session;
  }

  void discardTimer() {
    _ticker?.cancel();
    isRunning = false;
    activeClientId = null;
    activeProjectId = null;
    activeProjectName = null;
    startTime = null;
    elapsedSeconds = 0;
    _ticker = null;
    notifyListeners();
  }

  String get displayTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool isTimerForProject(String projectId) => activeProjectId == projectId;
}
