// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/models/base_task.dart';
import 'package:todo_app/models/category.dart';
import 'package:todo_app/models/checked_task.dart';
import 'package:todo_app/models/timed_task.dart';

import 'package:todo_app/screens/tasks_view_screen.dart';
import 'package:todo_app/services/firestore_service.dart';

// TODO: write tests for existing functionality
class MockFirestoreService extends Mock implements FirestoreService {
  StreamController<Iterable<BaseTaskListenable>> streamController =
      StreamController();
  var one = CheckedTaskListenable("One", "one desc", Reoccurrence.daily);

  MockFirestoreService() {
    streamController.add([
      TimedTaskListenable('TimedOne', 'timedOne desc',
          Reoccurrence.notRepeating, const Duration(days: 1)),
      one,
      CheckedTaskListenable("Two", "two desc", Reoccurrence.weekly),
      CheckedTaskListenable("Three", "three desc", Reoccurrence.notRepeating),
    ]);
  }
  @override
  Stream<Iterable<Category>> getCategories() {
    return Stream.value([
      Category(0xFF000000, "Category 1"),
      Category(0xFF000000, "Category 2"),
      Category(0xFF000000, "Category 3"),
    ]);
  }

  @override
  Stream<Iterable<BaseTaskListenable>> getTasks() {
    return streamController.stream;
  }

  @override
  Future<void> updateTaskFields(
      String? taskId, Map<String, dynamic> fields) async {
    if (fields.length == 1 && fields["lastDoneOn"] != null) {
      one.lastDoneOn = DateTime.parse(fields["lastDoneOn"]);
      streamController.add([
        TimedTaskListenable('TimedOne', 'timedOne desc',
            Reoccurrence.notRepeating, const Duration(days: 1)),
        one,
        CheckedTaskListenable("Two", "two desc", Reoccurrence.weekly),
        CheckedTaskListenable("Three", "three desc", Reoccurrence.notRepeating),
      ]);
    } else {
      throw Exception("Only task with id 'abc' was expected");
    }
  }
}

void main() {
  testWidgets('Widget loading test', (WidgetTester tester) async {
    final mockFirestoreService = MockFirestoreService();
    var categories = await mockFirestoreService.getCategories().first;
    // Build our app and trigger a frame.
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<FirestoreService>(create: (_) => mockFirestoreService),
        StreamProvider<Iterable<Category>>.value(
            value: mockFirestoreService.getCategories(),
            initialData: categories),
      ],
      child: const MaterialApp(home: TasksViewScreen()),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    var completed = find.text("Completed");
    expect(completed, findsOneWidget);

    await tester.pump(Duration.zero);
    var checkedTaskOne =
        find.ancestor(of: find.text("One"), matching: find.byType(ListTile));
    expect(checkedTaskOne, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(
        find.descendant(of: checkedTaskOne, matching: find.byType(Checkbox)));
    await tester.pumpAndSettle();
    expect(checkedTaskOne, findsNothing);

    await tester.tap(completed);
    await tester.pumpAndSettle();
    expect(find.text("TimedOne"), findsOneWidget);
  });

  test('Duration parse test', () {
    const dur = Duration(
      days: 2,
      hours: 1,
      minutes: 11,
      milliseconds: 4,
      microseconds: 3,
      seconds: 11,
    );
    expect(DurationParse.tryParse(dur.toString()), dur);
  });
}
