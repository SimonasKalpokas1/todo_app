import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/models/base_task.dart';
import 'package:todo_app/models/category.dart';

class FirestoreService {
  final SharedPreferences _prefs;
  late String mainCollection;
  late CollectionReference<Map<String, dynamic>> tasksCollection;
  final CollectionReference<Map<String, dynamic>> categoriesCollection =
      FirebaseFirestore.instance.collection('categories');

  FirestoreService(SharedPreferences preferences) : _prefs = preferences {
    mainCollection = _prefs.getString('mainCollection') ?? "tasks";
    tasksCollection = FirebaseFirestore.instance
        .collection(mainCollection)
        .doc('tasks')
        .collection('tasks');
  }

  /// Returns whether the main collection was set.
  Future<bool> setMainCollection(String newCollection) async {
    if (newCollection.trim().isEmpty) {
      return false;
    }
    await _prefs.setString('mainCollection', newCollection);
    mainCollection = newCollection;
    tasksCollection = FirebaseFirestore.instance
        .collection(mainCollection)
        .doc('tasks')
        .collection('tasks');
    return true;
  }

  Future<DocumentReference<Map<String, dynamic>>> addTask(BaseTask task) {
    return tasksCollection.add(task.toMap());
  }

  Stream<Iterable<BaseTask>> getTasks() {
    return tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var taskListenable =
            BaseTaskListenable.createTaskListenable(doc.data());
        taskListenable.addListener(() {
          tasksCollection.doc(doc.id).set(taskListenable.toMap());
        });
        taskListenable.refreshState();
        return taskListenable;
      });
    });
  }

  Future<void> updateTaskFields(String? taskId, Map<String, dynamic> fields) {
    return tasksCollection.doc(taskId).update(fields);
  }

  Future<void> deleteTask(String? taskId) {
    return tasksCollection.doc(taskId).delete();
  }

  Future<void> updateTask(BaseTask task) {
    return tasksCollection.doc(task.id).set(task.toMap());
  }

  Stream<Iterable<Category>> getCategories() {
    return categoriesCollection.snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Category.fromMap(doc.data())));
  }

  Future<void> addCategory(Category category) {
    return categoriesCollection.add(category.toMap());
  }

  Future<void> updateCategory(Category category) {
    return categoriesCollection.doc(category.id).set(category.toMap());
  }

  Future<void> deleteCategory(Category category) {
    return categoriesCollection.doc(category.id).delete();
  }
}
