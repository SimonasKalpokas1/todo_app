import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:todo_app/models/checked_task.dart';
import 'package:todo_app/models/timed_task.dart';

abstract class BaseTaskListenable implements Listenable, BaseTask {
  void refreshState();

  factory BaseTaskListenable.createTaskListenable(
      String? id, Map<String, dynamic> map) {
    switch (TaskType.values[map['type']]) {
      case TaskType.checked:
        return CheckedTaskListenable.fromMap(id, map);
      case TaskType.timed:
        return TimedTaskListenable.fromMap(id, map);
    }
  }
}

abstract class BaseTask {
  String? id;
  String name;
  String description;
  DateTime? lastDoneOn;
  Reoccurrence reoccurrence;
  TaskType type;

  BaseTask(this.type, this.name, this.description, this.reoccurrence);

  factory BaseTask.createTask(String? id, Map<String, dynamic> map) {
    switch (TaskType.values[map['type']]) {
      case TaskType.checked:
        return CheckedTask.fromMap(id, map);
      case TaskType.timed:
        return TimedTask.fromMap(id, map);
    }
  }

  // TODO: for weekly (also maybe for daily) add choice of first week day (time)
  Status calculateCurrentStatus() =>
      reoccurrence.isActiveNow(lastDoneOn) ? Status.done : Status.undone;

  bool get isDone => calculateCurrentStatus() == Status.done;

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'lastDoneOn': lastDoneOn?.toIso8601String(),
        'reoccurrence': reoccurrence.index,
        'type': type.index,
      };

  BaseTask.fromMap(this.id, Map<String, dynamic> map)
      : name = map['name'],
        description = map['description'],
        lastDoneOn = map['lastDoneOn'] == null
            ? null
            : DateTime.parse(map['lastDoneOn']),
        type = TaskType.values[map['type']],
        reoccurrence = Reoccurrence.values[map['reoccurrence']];
}

enum Status {
  undone,
  done,
  // TODO: think about if started is really neccessary
  started,
}

enum Reoccurrence {
  daily,
  weekly,
  notRepeating,
}

enum TaskType {
  checked,
  timed;

  static TaskType of<T extends BaseTask>() {
    if (T == TimedTask) {
      return TaskType.timed;
    }
    if (T == CheckedTask) {
      return TaskType.checked;
    }
    throw Exception('Unexpected type');
  }

  String get displayTitle {
    switch (this) {
      case TaskType.checked:
        return 'Checked';
      case TaskType.timed:
        return 'Timed';
    }
  }
}

extension ReoccurrenceExtension on Reoccurrence {
  String get displayTitle {
    assert(Reoccurrence.values.length == 3);
    switch (this) {
      case Reoccurrence.daily:
        return 'daily';
      case Reoccurrence.weekly:
        return 'weekly';
      case Reoccurrence.notRepeating:
        return 'not repeating';
    }
  }

  bool wasActiveLastTimePeriod(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    }
    if (isActiveNow(dateTime)) {
      return false;
    }

    final now = clock.now();
    switch (this) {
      case Reoccurrence.daily:
        dateTime = dateTime.subtract(const Duration(days: 1));
        if (now.difference(dateTime).inDays > 1 || now.day != dateTime.day) {
          return false;
        }
        break;
      case Reoccurrence.weekly:
        dateTime = dateTime.subtract(const Duration(days: 7));
        if (now.difference(dateTime).inDays > now.weekday ||
            now.weekday < dateTime.weekday) {
          return false;
        }
        break;
      case Reoccurrence.notRepeating:
        break;
    }
    return true;
  }

  bool isActiveNow(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    }
    final now = clock.now();

    if (now.isBefore(dateTime)) {
      // TODO: handle time in the future better
      throw Exception('Time of task completion is in the future.');
    }

    switch (this) {
      case Reoccurrence.daily:
        if (now.difference(dateTime).inDays > 1 || now.day != dateTime.day) {
          return false;
        }
        break;
      case Reoccurrence.weekly:
        if (now.difference(dateTime).inDays > now.weekday ||
            now.weekday < dateTime.weekday) {
          return false;
        }
        break;
      case Reoccurrence.notRepeating:
        break;
    }
    return true;
  }
}
