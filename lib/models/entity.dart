import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';

class Entity {
  final String id;
  final DateTime createdAt;

  Entity(this.id, this.createdAt);

  Entity.create()
      : id = const Uuid().v4(),
        createdAt = clock.now();

  Entity.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        createdAt = DateTime.parse(map['createdAt']);

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(other) {
    return other is Entity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
