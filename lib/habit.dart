class Habit {
  int? id; // Make nullable for when inserting a new habit
  String name;
  String type;
  int createdAt; // Using integer for timestamp

  Habit({this.id, required this.name, required this.type, required this.createdAt});

  // Convert a Habit object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'createdAt': createdAt,
    };
  }

  // Extract a Habit object from a Map object
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['_id'], // Use _id as defined in the database helper
      name: map['name'],
      type: map['type'],
      createdAt: map['createdAt'],
    );
  }
} 