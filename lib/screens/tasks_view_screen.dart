import 'dart:async';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/constants.dart';
import 'package:todo_app/models/base_task.dart';
import 'package:todo_app/models/category.dart';
import 'package:todo_app/models/timed_task.dart';
import 'package:todo_app/services/firestore_service.dart';

import '../widgets/timer_widget.dart';
import 'task_form_screen.dart';

class TasksViewScreen extends StatefulWidget {
  const TasksViewScreen({Key? key}) : super(key: key);

  @override
  State<TasksViewScreen> createState() => _TasksViewScreenState();
}

class _TasksViewScreenState extends State<TasksViewScreen> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    var tasks = firestoreService.getTasks().asBroadcastStream();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasks:"),
        actions: [
          IconButton(
            onPressed: () {
              showDialog<bool?>(
                      context: context,
                      builder: (context) => const ChooseMainCollectionDialog())
                  .then(
                (hasChanged) {
                  if (hasChanged ?? false) {
                    setState(() {});
                  }
                },
              );
            },
            icon: const Icon(
              Icons.settings,
              color: Color(0xFF666666),
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog<bool?>(
                  context: context,
                  builder: (context) => CategorySettingsDialog(
                      categories: Provider.of<Iterable<Category>>(context,
                          listen: false)));
            },
            icon: const Icon(
              Icons.category,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TasksListView(
              condition: (task) => !task.isDone,
              tasks: tasks,
            ),
            DoneTasksListView(tasks: tasks),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskFormScreen()),
          );
        },
        tooltip: 'Add a task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategorySettingsDialog extends StatefulWidget {
  final Iterable<Category> categories;

  const CategorySettingsDialog({Key? key, required this.categories})
      : super(key: key);

  @override
  State<CategorySettingsDialog> createState() => _CategorySettingsDialogState();
}

class _CategorySettingsDialogState extends State<CategorySettingsDialog> {
  final categoryNameController = TextEditingController();
  Category? category;

  @override
  void dispose() {
    categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text('Category settings'),
        content: Column(
          children: [
            DropdownButton<Category?>(
              value: category,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None'),
                ),
                ...widget.categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c.name,
                        style: TextStyle(color: Color(c.colorValue)),
                      ),
                    ))
              ],
              onChanged: (value) {
                setState(() {
                  category = value;
                });
              },
            ),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'New category name'),
              controller: categoryNameController,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                if (category != null &&
                    categoryNameController.text.isNotEmpty) {
                  category!.name = categoryNameController.text;
                  Provider.of<FirestoreService>(context, listen: false)
                      .updateCategory(category!);
                }
                Navigator.pop(context);
              },
              child: const Text('OK')),
          TextButton(
              onPressed: () {
                if (category != null) {
                  Provider.of<FirestoreService>(context, listen: false)
                      .deleteCategory(category!);
                }
                Navigator.pop(context);
              },
              child: const Text('Delete')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ]);
  }
}

class ChooseMainCollectionDialog extends StatefulWidget {
  const ChooseMainCollectionDialog({
    Key? key,
  }) : super(key: key);

  @override
  State<ChooseMainCollectionDialog> createState() =>
      _ChooseMainCollectionDialogState();
}

class _ChooseMainCollectionDialogState
    extends State<ChooseMainCollectionDialog> {
  final mainCollectionController = TextEditingController();

  @override
  void dispose() {
    mainCollectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text('Choose main collection'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Main collection'),
          controller: mainCollectionController,
        ),
        actions: [
          TextButton(
              onPressed: () async {
                var res =
                    await Provider.of<FirestoreService>(context, listen: false)
                        .setMainCollection(mainCollectionController.text);

                if (!mounted) {
                  return;
                }
                Navigator.pop(context, res);
              },
              child: const Text('OK')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ]);
  }
}

class DoneTasksListView extends StatefulWidget {
  final Stream<Iterable<BaseTask>> tasks;
  const DoneTasksListView({super.key, required this.tasks});

  @override
  State<DoneTasksListView> createState() => DoneTasksListViewState();
}

class DoneTasksListViewState extends State<DoneTasksListView> {
  bool showDone = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15.0, top: 8.0),
          child: GestureDetector(
            onTap: () {
              setState(() {
                showDone = !showDone;
              });
            },
            child: Row(
              children: [
                const Text(
                  "Completed",
                  style:
                      TextStyle(fontSize: fontSize, color: Color(0xFF787878)),
                ),
                showDone
                    ? const Icon(Icons.keyboard_arrow_up,
                        color: Color(0xFF787878))
                    : const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF787878))
              ],
            ),
          ),
        ),
        TasksListView(
          condition: (task) => task.isDone,
          tasks: widget.tasks,
          visible: showDone,
        ),
      ],
    );
  }
}

class TasksListView extends StatelessWidget {
  final bool Function(BaseTask)? condition;
  final bool visible;
  final Stream<Iterable<BaseTask>> tasks;

  const TasksListView({
    Key? key,
    this.condition,
    required this.tasks,
    this.visible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Iterable<BaseTask>>(
      stream: tasks,
      builder: (context, AsyncSnapshot<Iterable<BaseTask>> snapshot) {
        if (!visible) {
          return const SizedBox();
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return ListView(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: snapshot.data!.map(
            (task) {
              if (condition != null && !condition!(task)) {
                return Container();
              }
              return TaskCard(task: task);
            },
          ).toList(),
        );
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final BaseTask task;

  const TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var firestoreService = Provider.of<FirestoreService>(context);
    var categories = Provider.of<Iterable<Category>>(context);
    var category = task.categoryId != null
        ? categories.firstWhereOrNull((c) => c.id == task.categoryId)
        : null;
    return Card(
      margin: const EdgeInsets.fromLTRB(15, 8.0, 15, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
            color: Color(task.isDone
                ? 0xFFD7D7D7
                : task.categoryId == null
                    ? 0xFFFFD699
                    : categories
                            .firstWhereOrNull((c) => c.id == task.categoryId)
                            ?.colorValue ??
                        0xFFFFD699)),
      ),
      color: task.isDone ? const Color(0xFFF6F6F6) : Colors.white,
      child: Dismissible(
        key: ObjectKey(task),
        onDismissed: ((direction) {
          firestoreService.deleteTask(task.id);
        }),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
          child: const Icon(Icons.delete_sweep),
        ),
        child: ListTile(
          minLeadingWidth: 10,
          horizontalTitleGap: 7.5,
          leading: Container(
            width: 10,
            decoration: BoxDecoration(
                color: Color(task.isDone
                    ? 0xFFF6F6F6
                    : category?.colorValue ?? 0xFFFFFFFF),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5.0),
                    bottomLeft: Radius.circular(5.0))),
          ),
          contentPadding: const EdgeInsets.only(left: 0),
          title: Column(
            children: [
              if (category != null)
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    category.name,
                    style: TextStyle(
                        fontSize: fontSize * 0.6,
                        color: Color(
                            task.isDone ? 0xFFDBDBDB : category.colorValue)),
                  ),
                ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  overflow: TextOverflow.ellipsis,
                  task.name,
                  style: TextStyle(
                      fontSize: fontSize,
                      color:
                          task.isDone ? const Color(0xFFDBDBDB) : Colors.black),
                ),
              )
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TaskFormScreen(task: task)),
            );
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.isDone && task.reoccurrence != Reoccurrence.notRepeating)
                const Icon(Icons.repeat, color: Color(0xFF5F5F5F)),
              if (task.type == TaskType.timed && !task.isDone)
                TimerWidget(timedTask: task as TimedTask),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: Checkbox(
                    onChanged: (bool? value) {
                      if (value == null) {
                        throw UnimplementedError();
                      }
                      firestoreService.updateTaskFields(task.id, {
                        'lastDoneOn':
                            value ? clock.now().toIso8601String() : null
                      });
                    },
                    value: task.isDone,
                    side: BorderSide(
                        color: Color(category?.colorValue ?? 0xFFFFD699)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    activeColor: const Color(0xFFD9D9D9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
