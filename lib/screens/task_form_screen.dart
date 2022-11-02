import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/custom_icons.dart';
import 'package:todo_app/models/base_task.dart';
import 'package:todo_app/models/category.dart';
import 'package:todo_app/models/checked_task.dart';
import 'package:todo_app/models/timed_task.dart';
import 'package:todo_app/services/firestore_service.dart';
import 'package:collection/collection.dart';

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
  Category? category;
  var showExtra = false;

  @override
  void initState() {
    if (widget.task != null) {
      nameController.text = widget.task!.name;
      descriptionController.text = widget.task!.description;
      reoccurrence = widget.task!.reoccurrence;
      isReoccurringTabController.index =
          reoccurrence == Reoccurrence.notRepeating ? 0 : 1;
      isReoccurring = reoccurrence != Reoccurrence.notRepeating;
      isReoccurrenceOptionsExpanded = !isReoccurring;
      reoccurrencePeriodTabController.index =
          reoccurrence == Reoccurrence.weekly ? 1 : 0;
      isTimed = widget.task!.type == TaskType.timed;
      isTimedOptionsExpanded = !isTimed;
      hoursController.text = widget.task!.type == TaskType.timed
          ? (widget.task as TimedTask).totalTime.inHours.toString()
          : '0';
      minutesController.text = widget.task!.type == TaskType.timed
          ? (widget.task as TimedTask)
              .totalTime
              .inMinutes
              .remainder(60)
              .toString()
          : '0';

      typeTabController.index = widget.task!.type.index;
      type = widget.task!.type;
      if (type == TaskType.timed) {
        totalTime = (widget.task! as TimedTask).totalTime;
      }
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    category = widget.task != null
        ? Provider.of<Iterable<Category>>(context)
            .firstWhereOrNull((c) => c.id == widget.task!.categoryId)
        : null;

    super.didChangeDependencies();
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
    final categories = Provider.of<Iterable<Category>>(context);
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
                      widget.task!.categoryId = category?.id;
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
                      task.categoryId = category?.id;
                      firestoreService.addTask(task);
                    }
                    Navigator.pop(context);
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
          padding: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: ListView(
            children: [
              const FormLabel(text: "Task"),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: "Enter task name",
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 210, 210, 210),
                  ),
                  contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                ),
                style: const TextStyle(fontSize: 20),
                controller: nameController,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Name cannot be empty";
                  }
                  return null;
                },
              ),
              const FormLabel(text: "Description"),
              TextFormField(
                controller: descriptionController,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8)),
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showExtra = !showExtra;
                  });
                },
                child: Row(
                  children: [
                    const Text(
                      "Advanced",
                      style: TextStyle(fontSize: 16, color: Color(0xFF787878)),
                    ),
                    showExtra
                        ? const Icon(Icons.keyboard_arrow_up,
                            color: Color(0xFF787878))
                        : const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFF787878))
                  ],
                ),
              ),
              if (showExtra)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFFFC36A)),
                    ),
                    child: TabBar(
                      labelStyle: Theme.of(context)
                          .tabBarTheme
                          .labelStyle
                          ?.copyWith(fontSize: 16),
                      unselectedLabelStyle: Theme.of(context)
                          .tabBarTheme
                          .unselectedLabelStyle
                          ?.copyWith(fontSize: 16),
                      controller: isReoccurringTabController,
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
              if (showExtra)
                Visibility(
                  visible: isReoccurring,
                  child: isReoccurrenceOptionsExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FormLabel(
                              text: "Repeat",
                              fontSize: 14,
                            ),
                            Container(
                              height: 35,
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
                                labelStyle: Theme.of(context)
                                    .tabBarTheme
                                    .labelStyle
                                    ?.copyWith(fontSize: 14),
                                unselectedLabelStyle: Theme.of(context)
                                    .tabBarTheme
                                    .unselectedLabelStyle
                                    ?.copyWith(fontSize: 14),
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
                                labelStyle: Theme.of(context)
                                    .tabBarTheme
                                    .labelStyle
                                    ?.copyWith(fontSize: 11),
                                unselectedLabelStyle: Theme.of(context)
                                    .tabBarTheme
                                    .unselectedLabelStyle
                                    ?.copyWith(fontSize: 11),
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
              if (showExtra)
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
                      tabs: const [
                        Tab(child: Text('Checklist')),
                        Tab(child: Text('Timed')),
                      ],
                    ),
                  ),
                ),
              if (showExtra)
                Visibility(
                  visible: isTimed,
                  child: isTimedOptionsExpanded
                      ? Row(children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: SizedBox(
                              width: 40,
                              height: 30,
                              child: TextFormField(
                                controller: hoursController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                          const FormLabel(text: "Hours"),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, top: 12.0),
                            child: SizedBox(
                              width: 40,
                              height: 30,
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
                                style:
                                    const TextStyle(color: Color(0xFF666666))),
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
              if (showExtra) const SizedBox(height: 16),
              if (showExtra)
                const AddIconTextButton(
                  iconData: Icons.notifications_active,
                  label: "Set reminder",
                ),
              if (showExtra)
                AddIconTextButton(
                  iconData: Icons.add,
                  label: "Assign a category",
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ChooseCategoryDialog(
                          categories: categories, category: category),
                    ).then((value) => setState(() {
                          category = value;
                        }));
                  },
                  trailing: category != null
                      ? Text(category!.name,
                          style: TextStyle(color: Color(category!.colorValue)))
                      : null,
                ),
              if (showExtra)
                const AddIconTextButton(
                  iconData: CustomIcons.sublist,
                  label: "Assign to parent task",
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChooseCategoryDialog extends StatefulWidget {
  final Category? category;
  final Iterable<Category> categories;

  const ChooseCategoryDialog(
      {super.key, required this.category, required this.categories});

  @override
  State<ChooseCategoryDialog> createState() => _ChooseCategoryDialogState();
}

class _ChooseCategoryDialogState extends State<ChooseCategoryDialog> {
  Category? category;
  @override
  void initState() {
    category = widget.category;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.only(top: 10),
      backgroundColor: const Color(0xFFFFF9F1),
      title: const Text(
        'Select a category',
        style: TextStyle(fontSize: 24),
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: widget.categories
                .map((category) => ListTile(
                      minVerticalPadding: 0,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 15),
                      minLeadingWidth: 10,
                      horizontalTitleGap: 15,
                      title: Text(category.name,
                          style: const TextStyle(fontSize: 14)),
                      leading: SizedBox(
                        height: double.infinity,
                        child: CircleAvatar(
                          backgroundColor: Color(category.colorValue),
                          maxRadius: 5,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          this.category = category;
                          Navigator.pop(context, category);
                        });
                      },
                      trailing: this.category == category
                          ? const Icon(Icons.check)
                          : null,
                    ))
                .followedBy([
              ListTile(
                minVerticalPadding: 0,
                contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                minLeadingWidth: 10,
                horizontalTitleGap: 13,
                title: const Text('Add new..',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6E6E6E))),
                leading: const Icon(Icons.add, size: 15),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const CategoryCreateDialog(),
                  ).then((value) {
                    if (value != null) {
                      Navigator.pop(context, value);
                    }
                  });
                },
              ),
            ]),
          ).toList(),
        ),
      ),
      actionsAlignment: MainAxisAlignment.start,
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 40),
          child: TextButton(
              child: const Text("Cancel",
                  style: TextStyle(color: Color(0xFFFFC36A), fontSize: 20)),
              onPressed: () {
                Navigator.pop(context, category);
              }),
        ),
      ],
    );
  }
}

const pickerColors = [
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.yellow,
  Colors.purple,
  Colors.orange,
  Colors.cyan,
  Colors.lime,
];

class ColorPickerFormField extends FormField<Color> {
  ColorPickerFormField({
    super.key,
    FormFieldSetter<Color>? onSaved,
    FormFieldValidator<Color>? validator,
    Color? initialValue,
    bool autovalidate = false,
  }) : super(
            onSaved: onSaved,
            validator: validator,
            initialValue: initialValue,
            autovalidateMode: autovalidate
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            builder: (FormFieldState<Color> field) {
              final state = field as _ColorPickerFormFieldState;
              return InputDecorator(
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFF9F1))),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFF9F1))),
                  fillColor: const Color(0xFFFFF9F1),
                  errorText: state.errorText,
                ),
                child: Column(
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: pickerColors
                            .map((color) => Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () {
                                      state.didChange(color);
                                    },
                                    child: Container(
                                      height: 26,
                                      width: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color,
                                        border: Border.all(
                                            color: Colors.black,
                                            width: 0.3,
                                            style: BorderStyle.solid),
                                      ),
                                      child: state.value == color
                                          ? const Icon(
                                              Icons.check,
                                              size: 15,
                                              color: Colors.black,
                                            )
                                          : null,
                                    ),
                                  ),
                                ))
                            .toList()),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: const BorderSide(
                                    color: Colors.black, width: 0.25))),
                        onPressed: () {
                          notImplementedAlert(state.context);
                        },
                        icon: const Icon(Icons.palette),
                        label: const Text('Custom color',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              );
            });

  @override
  FormFieldState<Color> createState() => _ColorPickerFormFieldState();
}

class _ColorPickerFormFieldState extends FormFieldState<Color> {
  @override
  ColorPickerFormField get widget => super.widget as ColorPickerFormField;

  @override
  void didChange(Color? value) {
    super.didChange(value);
    setState(() {});
  }
}

class CategoryCreateDialog extends StatefulWidget {
  const CategoryCreateDialog({super.key});

  @override
  State<CategoryCreateDialog> createState() => _CategoryCreateDialogState();
}

class _CategoryCreateDialogState extends State<CategoryCreateDialog> {
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Color? color;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF9F1),
      title: const Text(
        'New category',
        style: TextStyle(fontSize: 24),
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormLabel(text: 'Name'),
              TextFormField(
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const FormLabel(text: 'Color'),
              const SizedBox(height: 10),
              ColorPickerFormField(
                onSaved: (value) {
                  color = value;
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a color';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        Row(
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
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final category =
                          Category(color!.value, nameController.text);
                      await firestoreService.addCategory(category);
                      if (mounted) {
                        Navigator.pop(context, category);
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
                        style:
                            TextStyle(color: Color(0xFFFFC36A), fontSize: 20)),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
              ),
            ),
          ],
        )
      ],
    );
  }
}

class AddIconTextButton extends StatelessWidget {
  final IconData iconData;
  final String label;
  final Widget? trailing;
  final VoidCallback? onPressed;
  const AddIconTextButton(
      {super.key,
      required this.iconData,
      required this.label,
      this.trailing,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onPressed ??
              () {
                notImplementedAlert(context);
              },
          style: const ButtonStyle(alignment: Alignment.centerLeft),
          icon: Icon(iconData, color: const Color(0xFF666666), size: 25),
          label: Text(label,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),
        ),
        const Spacer(),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class FormLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  const FormLabel({super.key, required this.text, this.fontSize = 16.0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Text(
        text,
        style: TextStyle(color: const Color(0xFF666666), fontSize: fontSize),
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
