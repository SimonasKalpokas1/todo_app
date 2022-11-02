import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/constants.dart';
import 'package:todo_app/models/category.dart';

import '../models/timed_task.dart';

class TimerWidget extends StatefulWidget {
  final TimedTask timedTask;
  const TimerWidget({Key? key, required this.timedTask}) : super(key: key);

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> with WidgetsBindingObserver {
  late Timer timer;
  late Duration timeLeft;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    timeLeft = widget.timedTask.calculateCurrentRemainingTime();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.timedTask.executing) {
        setState(() {
          timeLeft -= const Duration(seconds: 1);
        });
        if (timeLeft <= Duration.zero) {
          timer.cancel();
          widget.timedTask.updateState();
        }
      }
    });
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      var remainingTime = widget.timedTask.calculateCurrentRemainingTime();
      if (remainingTime != timeLeft) {
        setState(() {
          timeLeft = remainingTime;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant TimerWidget oldWidget) {
    var remainingTime = widget.timedTask.calculateCurrentRemainingTime();
    if (remainingTime != timeLeft) {
      setState(() {
        timeLeft = remainingTime;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorValue = widget.timedTask.categoryId == null
        ? 0xFFFFBE5C
        : Provider.of<Iterable<Category>>(context)
                .firstWhereOrNull((c) => c.id == widget.timedTask.categoryId)
                ?.colorValue ??
            0xFFFFBE5C;
    int hours = timeLeft.inHours;
    int mins = timeLeft.inMinutes - hours * 60;
    int secs = timeLeft.inSeconds - hours * 3600 - mins * 60;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.timedTask.executing
            ? IconButton(
                icon: const Icon(Icons.pause),
                color: Color(colorValue),
                onPressed: () {
                  widget.timedTask.stopExecution();
                },
              )
            : IconButton(
                icon: const Icon(Icons.play_arrow),
                color: Color(colorValue),
                onPressed: () {
                  widget.timedTask.startExecution();
                },
              ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: fontSize * 8 / 9),
            ),
            Container(
                height: 5,
                width: 65,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    color: Colors.white,
                    border: Border.all(color: Color(colorValue), width: 1)),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 5,
                      width: (1 -
                              timeLeft.inSeconds /
                                  widget.timedTask.totalTime.inSeconds) *
                          65,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5.0),
                            bottomLeft: Radius.circular(5.0)),
                        color: Color(colorValue),
                      ),
                    ))),
          ],
        ),
      ],
    );
  }
}
