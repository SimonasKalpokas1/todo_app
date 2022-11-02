import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/models/base_task.dart';

class TimedTaskListenable extends TimedTask
    with BaseTaskListenable, ChangeNotifier {
  TimedTaskListenable(
      super.name, super.description, super.reoccurrence, super.totalTime);

  TimedTaskListenable.fromMap(super.map) : super.fromMap();

  @override
  void refreshState() {
    if (super.updateState()) {
      notifyListeners();
    }
  }

  @override
  bool updateState() {
    if (super.updateState()) {
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  bool startExecution() {
    if (super.startExecution()) {
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  bool stopExecution() {
    if (super.stopExecution()) {
      notifyListeners();
      return true;
    }
    return false;
  }
}

// TODO: add constrait that totalTime < reoccurence time period
class TimedTask extends BaseTask {
  Duration totalTime;
  Duration remainingTime;
  bool executing = false;
  DateTime? startOfExecution;

  TimedTask(String name, String description, Reoccurrence reoccurrence,
      this.totalTime)
      : assert(name.isNotEmpty),
        remainingTime = totalTime,
        super(TaskType.timed, name, description, reoccurrence);

  bool isCurrentlyExecuting() {
    return (executing &&
        !reoccurrence.isActiveNow(lastDoneOn) &&
        (remainingTime - clock.now().difference(startOfExecution!) >
            Duration.zero));
  }

  Duration calculateCurrentRemainingTime() {
    if (reoccurrence.isActiveNow(startOfExecution) &&
        reoccurrence.isActiveNow(lastDoneOn)) {
      return Duration.zero;
    }
    if (executing) {
      var dur = remainingTime - clock.now().difference(startOfExecution!);
      if (dur <= Duration.zero) {
        if (reoccurrence.isActiveNow(startOfExecution)) {
          return Duration.zero;
        }
        return totalTime;
      }
      return dur;
    }
    if (reoccurrence.isActiveNow(startOfExecution)) {
      return remainingTime;
    }
    return totalTime;
  }

  @override
  Status calculateCurrentStatus() {
    if (reoccurrence.isActiveNow(startOfExecution) &&
        reoccurrence.isActiveNow(lastDoneOn)) {
      return Status.done;
    }
    if (executing) {
      var dur = remainingTime - clock.now().difference(startOfExecution!);
      if (dur <= Duration.zero) {
        if (reoccurrence.isActiveNow(startOfExecution)) {
          return Status.done;
        }
        return Status.undone;
      }
      return Status.started;
    }
    if (reoccurrence.isActiveNow(startOfExecution)) {
      return Status.started;
    }
    return Status.undone;
  }

  DateTime? calculateCurrentLastDoneOn() {
    if (executing) {
      if (reoccurrence.isActiveNow(startOfExecution)) {
        if (lastDoneOn != null && lastDoneOn!.isAfter(startOfExecution!)) {
          return lastDoneOn;
        }
      }
      var dur = remainingTime - clock.now().difference(startOfExecution!);
      if (dur <= Duration.zero) {
        return startOfExecution!.add(remainingTime);
      }
    }
    return lastDoneOn;
  }

  /// Updates state based on current DateTime.
  /// Returns whether a change has happenned
  bool updateState() {
    var newStatus = calculateCurrentStatus();
    var newRemainingTime = calculateCurrentRemainingTime();

    if (executing && newStatus != Status.started) {
      var newLastDoneOn = calculateCurrentLastDoneOn();
      lastDoneOn = newLastDoneOn;
      executing = false;
      remainingTime = newRemainingTime;
      return true;
    }
    if (newStatus == Status.undone && remainingTime != newRemainingTime) {
      remainingTime = newRemainingTime;
      return true;
    }
    return false;
  }

  /// Returns whether any change has happenned.
  bool startExecution() {
    var ret = updateState();
    if (executing || isDone) {
      return ret;
    }
    startOfExecution = clock.now();
    executing = true;
    return true;
  }

  /// Returns whether any change has happenned.
  bool stopExecution() {
    var ret = updateState();
    if (!executing) {
      return ret;
    }
    remainingTime = calculateCurrentRemainingTime();
    executing = false;
    return true;
  }

  @override
  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map.addAll({
      'totalTime': totalTime.toString(),
      'remainingTime': remainingTime.toString(),
      'startOfExecution': startOfExecution?.toIso8601String(),
      'executing': executing,
    });
    return map;
  }

  @override
  TimedTask.fromMap(super.map)
      : totalTime = DurationParse.tryParse(map['totalTime'])!,
        remainingTime = DurationParse.tryParse(map['remainingTime'])!,
        startOfExecution = map['startOfExecution'] == null
            ? null
            : DateTime.parse(map['startOfExecution']),
        executing = map['executing'],
        super.fromMap();
}

extension DurationParse on Duration {
  static Duration? tryParse(String? str) {
    if (str == null) {
      return null;
    }
    final parts = str.split(':');
    final hours = int.parse(parts[0]);
    final mins = int.parse(parts[1]);
    final secs = int.parse(parts[2].substring(0, 2));
    final microsecs = int.parse(parts[2].substring(3));
    return Duration(
        hours: hours, minutes: mins, seconds: secs, microseconds: microsecs);
  }
}
