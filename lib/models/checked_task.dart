import 'package:flutter/material.dart';
import 'package:todo_app/models/base_task.dart';

class CheckedTaskListenable extends CheckedTask
    with BaseTaskListenable, ChangeNotifier {
  CheckedTaskListenable(super.name, super.description, super.reoccurrence);
  CheckedTaskListenable.fromMap(super.map) : super.fromMap();

  @override
  void refreshState() {}
}

class CheckedTask extends BaseTask {
  CheckedTask(String name, String description, Reoccurrence reoccurrence)
      : super(TaskType.checked, name, description, reoccurrence);

  CheckedTask.fromMap(super.map) : super.fromMap();
}
