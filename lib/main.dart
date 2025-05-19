import 'package:flutter/material.dart';
import 'package:questy/features/goal_management/domain/entities/goal_entity.dart';
import 'package:questy/features/goal_management/domain/entities/step_entity.dart';
import 'dart:math'; // For generating a random ID

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GoalInputScreen(),
    );
  }
}

class GoalInputScreen extends StatefulWidget {
  const GoalInputScreen({super.key});

  @override
  State<GoalInputScreen> createState() => _GoalInputScreenState();
}

class _GoalInputScreenState extends State<GoalInputScreen> {
  final TextEditingController _goalController = TextEditingController();
  String? _errorMessage;
  GoalEntity? _currentGoal;

  void _submitGoal() {
    final goalDescription = _goalController.text.trim();
    if (goalDescription.isEmpty) {
      setState(() {
        _errorMessage = 'Deskripsi tujuan tidak boleh kosong';
        _currentGoal = null;
      });
    } else {
      // Generate a simple random ID for now
      final String randomId = Random().nextInt(100000).toString();
      final newGoal = GoalEntity(
        id: randomId,
        description: goalDescription,
        steps: [
          StepEntity(title: 'Step 1', description: 'Complete the first part of ${goalDescription.substring(0, min(goalDescription.length, 10))}...', exp: 10, status: 'Pending'),
          StepEntity(title: 'Step 2', description: 'Continue with ${goalDescription.substring(0, min(goalDescription.length, 10))}...', exp: 15, status: 'Pending'),
          StepEntity(title: 'Step 3', description: 'Finalize ${goalDescription.substring(0, min(goalDescription.length, 10))}...', exp: 20, status: 'Pending'),
        ],
      );
      setState(() {
        _errorMessage = null;
        _currentGoal = newGoal;
      });
      print('Goal Submitted: ${_currentGoal!.description}');
      print('Steps Generated: ${_currentGoal!.steps.length}');
      _goalController.clear(); // Clear input after submission
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Your Goal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 20),
            TextField(
              controller: _goalController,
              decoration: InputDecoration(
                labelText: 'Goal Description',
                hintText: 'E.g., Learn to play guitar',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              onChanged: (text) {
                if (_errorMessage != null && text.isNotEmpty) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitGoal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Submit Goal'),
            ),
            const SizedBox(height: 30),
            if (_currentGoal != null && _currentGoal!.steps.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _currentGoal!.steps.length,
                  itemBuilder: (context, index) {
                    final step = _currentGoal!.steps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(step.title),
                        subtitle: Text('${step.description}\nEXP: ${step.exp} - Status: ${step.status}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }
}
