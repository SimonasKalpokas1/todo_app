class BaseTask {
  String? id;
  String name;
  String description;
  Status status = Status.undone;
  // TODO: rename type to reoccurrence
  Reoccurrence type;

  BaseTask(this.name, this.description, this.type);

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'status': status.index,
        'reoccurrence': type.index,
      };

  BaseTask.fromMap(this.id, Map<String, dynamic> map)
      : name = map['name'],
        description = map['description'],
        status = Status.values[map['status']],
        type = Reoccurrence.values[map['reoccurrence']];
}

enum Status {
  undone,
  done,
}

enum Reoccurrence {
  daily,
  weekly,
  notRepeating,
}

extension ReoccurrenceExtension on Reoccurrence {
  String get displayTitle {
    assert(Reoccurrence.values.length == 3);
    switch (this) {
      case Reoccurrence.daily:
        return 'Daily';
      case Reoccurrence.weekly:
        return 'Weekly';
      case Reoccurrence.notRepeating:
        return 'Not repeating';
    }
  }
}
