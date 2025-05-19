import './step_entity.dart';

class GoalEntity {
  final String id;
  final String description;
  final List<StepEntity> steps;

  GoalEntity({
    required this.id,
    required this.description,
    List<StepEntity>? steps,
  }) : steps = steps ?? [];
} 