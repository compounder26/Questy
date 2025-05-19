class StepEntity {
  final String title;
  final String description;
  final int exp;
  final String status; // Consider using an Enum for status later

  StepEntity({
    required this.title,
    required this.description,
    required this.exp,
    required this.status,
  });
} 