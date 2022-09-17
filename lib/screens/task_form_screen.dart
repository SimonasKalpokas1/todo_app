import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/models/base_task.dart';
import 'package:todo_app/models/checked_task.dart';
import 'package:todo_app/models/timed_task.dart';
import 'package:todo_app/services/firestore_service.dart';

class TaskFormScreen extends StatelessWidget {
  final BaseTask? task;
  const TaskFormScreen({Key? key, this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New task"),
        automaticallyImplyLeading: false,
      ),
      body: TaskForm(task: task),
    );
  }
}

class TaskForm extends StatefulWidget {
  final BaseTask? task;
  const TaskForm({Key? key, this.task}) : super(key: key);

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final hoursController = TextEditingController(text: '0');
  final minutesController = TextEditingController(text: '0');

  late final isReoccurringTabController = TabController(length: 2, vsync: this);
  late final reoccurrencePeriodTabController =
      TabController(length: 4, vsync: this);
  late final startingTabController = TabController(length: 4, vsync: this);
  late final typeTabController = TabController(length: 2, vsync: this);

  var isReoccurrenceOptionsExpanded = true;
  var isTimedOptionsExpanded = true;
  var isReoccurring = false;
  var isTimed = false;
  var reoccurrence = Reoccurrence.notRepeating;
  var type = TaskType.checked;
  var totalTime = const Duration(hours: 1);

  @override
  void initState() {
    if (widget.task != null) {
      nameController.text = widget.task!.name;
      descriptionController.text = widget.task!.description;
      reoccurrence = widget.task!.reoccurrence;
      type = widget.task!.type;
      if (type == TaskType.timed) {
        totalTime = (widget.task! as TimedTask).totalTime;
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    isReoccurringTabController.dispose();
    reoccurrencePeriodTabController.dispose();
    typeTabController.dispose();
    startingTabController.dispose();
    super.dispose();
  }

  // TODO: extract title + input to separate widget
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 6.0, 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC36A),
                    minimumSize: const Size.fromHeight(43)),
                child: const Text(
                  "Save",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  var form = _formKey.currentState!;
                  if (form.validate()) {
                    totalTime = Duration(
                        hours: int.parse(hoursController.text),
                        minutes: int.parse(minutesController.text));
                    if (widget.task != null) {
                      widget.task!.name = nameController.text;
                      widget.task!.description = descriptionController.text;
                      widget.task!.reoccurrence = reoccurrence;
                      widget.task!.type =
                          isTimed ? TaskType.timed : TaskType.checked;
                      if (widget.task!.type == TaskType.timed) {
                        (widget.task! as TimedTask).totalTime = totalTime;
                      }
                      firestoreService.updateTask(widget.task!);
                    } else {
                      BaseTask? task;
                      switch (isTimed ? TaskType.timed : TaskType.checked) {
                        case TaskType.checked:
                          task = CheckedTask(nameController.text,
                              descriptionController.text, reoccurrence);
                          break;
                        case TaskType.timed:
                          task = TimedTask(
                              nameController.text,
                              descriptionController.text,
                              reoccurrence,
                              totalTime);
                          break;
                      }
                      firestoreService.addTask(task);
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6.0, 0, 12.0, 8.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(43)),
                  child: const Text("Cancel",
                      style: TextStyle(color: Color(0xFFFFC36A), fontSize: 20)),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: ListView(
            //crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FormLabel(text: "Task"),
              TextFormField(
                controller: nameController,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Name cannot be empty";
                  }
                  return null;
                },
              ),
              const FormLabel(text: "Description"),
              TextFormField(controller: descriptionController),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFFFC36A)),
                  ),
                  child: TabBar(
                    controller: isReoccurringTabController,
                    indicator: const BoxDecoration(color: Color(0xFFFFC36A)),
                    labelColor: Colors.black,
                    unselectedLabelColor: const Color(0xFF737373),
                    labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito'),
                    onTap: (index) {
                      setState(() {
                        isReoccurring = index == 1;
                      });
                      if (index == 1 &&
                          reoccurrence == Reoccurrence.notRepeating) {
                        setState(() {
                          reoccurrence = Reoccurrence.daily;
                        });
                      }
                      if (isTimed && isTimedOptionsExpanded) {
                        setState(() {
                          isTimedOptionsExpanded = false;
                        });
                      }
                    },
                    tabs: const [
                      Tab(child: Text('Normal')),
                      Tab(child: Text('Repeating')),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: isReoccurring,
                child: isReoccurrenceOptionsExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FormLabel(text: "Repeat"),
                          Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border:
                                  Border.all(color: const Color(0xFFFFC36A)),
                            ),
                            child: TabBar(
                              onTap: (index) {
                                if (index > 1) {
                                  reoccurrencePeriodTabController.index =
                                      reoccurrencePeriodTabController
                                          .previousIndex;
                                  notImplementedAlert(context);
                                } else {
                                  setState(() {
                                    reoccurrence = Reoccurrence.values[index];
                                  });
                                }
                              },
                              controller: reoccurrencePeriodTabController,
                              indicator:
                                  const BoxDecoration(color: Color(0xFFFFE1B5)),
                              labelColor: Colors.black,
                              unselectedLabelColor: const Color(0xFF737373),
                              labelStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Nunito'),
                              tabs: const [
                                Tab(child: Text('Daily')),
                                Tab(child: Text('Weekly')),
                                Tab(child: Text('Monthly')),
                                Tab(child: Text('Custom..')),
                              ],
                            ),
                          ),
                          const FormLabel(text: 'Starting'),
                          Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border:
                                  Border.all(color: const Color(0xFFFFC36A)),
                            ),
                            child: TabBar(
                              controller: startingTabController,
                              indicator:
                                  const BoxDecoration(color: Color(0xFFFFE1B5)),
                              labelColor: Colors.black,
                              unselectedLabelColor: const Color(0xFF737373),
                              labelStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Nunito'),
                              tabs: const [
                                Tab(child: Text('Today')),
                                Tab(child: Text('Next week')),
                                Tab(child: Text('Next month')),
                                Tab(child: Text('Custom..')),
                              ],
                            ),
                          ),
                        ],
                      )
                    : DefaultTextStyle(
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFAAAAAA),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito'),
                        child: Row(children: [
                          const Text("Repeats "),
                          Text(
                            reoccurrence.displayTitle,
                            style: const TextStyle(color: Color(0xFF666666)),
                          ),
                          const Text(' starting '),
                          const Text(
                            '8th of August, 2023',
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                          const Spacer(),
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  isReoccurrenceOptionsExpanded = true;
                                });
                                if (isTimed && isTimedOptionsExpanded) {
                                  setState(() {
                                    isTimedOptionsExpanded = false;
                                  });
                                }
                              },
                              child: const Text(
                                'Modify',
                                style: TextStyle(
                                    color: Color(0xFFFFC36A), fontSize: 11),
                              ))
                        ]),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFFFC36A)),
                  ),
                  child: TabBar(
                    onTap: (index) {
                      setState(() {
                        isTimed = index == 1;
                      });
                      if (isReoccurring && isReoccurrenceOptionsExpanded) {
                        setState(() {
                          isReoccurrenceOptionsExpanded = false;
                        });
                      }
                    },
                    controller: typeTabController,
                    indicator: const BoxDecoration(color: Color(0xFFFFC36A)),
                    labelColor: Colors.black,
                    unselectedLabelColor: const Color(0xFF737373),
                    labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito'),
                    tabs: const [
                      Tab(child: Text('Checklist')),
                      Tab(child: Text('Timed')),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: isTimed,
                child: isTimedOptionsExpanded
                    ? Row(children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SizedBox(
                            width: 44,
                            height: 22,
                            child: TextFormField(
                              controller: hoursController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ),
                        const FormLabel(text: "Hours"),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 12.0),
                          child: SizedBox(
                            width: 44,
                            height: 22,
                            child: TextFormField(
                              controller: minutesController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ),
                        const FormLabel(text: "Minutes"),
                      ])
                    : DefaultTextStyle(
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFAAAAAA),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito'),
                        child: Row(children: [
                          Text(
                              '${hoursController.text} hours ${minutesController.text} minutes',
                              style: const TextStyle(color: Color(0xFF666666))),
                          const Text(' to complete'),
                          const Spacer(),
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  isTimedOptionsExpanded = true;
                                });
                                if (isReoccurring &&
                                    isReoccurrenceOptionsExpanded) {
                                  setState(() {
                                    isReoccurrenceOptionsExpanded = false;
                                  });
                                }
                              },
                              child: const Text(
                                'Modify',
                                style: TextStyle(
                                    color: Color(0xFFFFC36A), fontSize: 11),
                              ))
                        ]),
                      ),
              ),
              // DropdownButton<Reoccurrence>(
              //   value: reoccurrence,
              //   items: Reoccurrence.values
              //       .map((type) => DropdownMenuItem<Reoccurrence>(
              //             value: type,
              //             child: Text(type.displayTitle),
              //           ))
              //       .toList(),
              //   onChanged: (value) => setState(() => reoccurrence = value!),
              // ),
              // widget.task != null
              //     ? Text(widget.task!.type.displayTitle)
              //     : DropdownButton<TaskType>(
              //         value: type,
              //         items: TaskType.values
              //             .map((type) => DropdownMenuItem(
              //                   value: type,
              //                   child: Text(type.displayTitle),
              //                 ))
              //             .toList(),
              //         onChanged: (value) => setState(() => type = value!),
              //       ),
              // Visibility(
              //   visible: type == TaskType.timed,
              //   child: CupertinoTimerPicker(
              //     onTimerDurationChanged: (duration) {
              //       setState(() {
              //         totalTime = duration;
              //       });
              //     },
              //     mode: CupertinoTimerPickerMode.hms,
              //     initialTimerDuration: totalTime,
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: TextButton(
                  onPressed: () {
                    notImplementedAlert(context);
                  },
                  child: Row(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: Icon(
                          Icons.notifications_active,
                          color: Color(0xFF666666),
                          size: 16,
                        ),
                      ),
                      Text(
                        "Set reminder",
                        style:
                            TextStyle(color: Color(0xFF666666), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: TextButton(
                  onPressed: () {
                    notImplementedAlert(context);
                  },
                  child: Row(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: Icon(
                          Icons.add,
                          color: Color(0xFF666666),
                          size: 16,
                        ),
                      ),
                      Text(
                        "Assign a category",
                        style:
                            TextStyle(color: Color(0xFF666666), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              //const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
    );
  }
}

void notImplementedAlert(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) =>
          const AlertDialog(content: Text("oops not implemented")));
}
