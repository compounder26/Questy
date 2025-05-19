import 'package:flutter/material.dart';

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

  void _submitGoal() {
    if (_goalController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Deskripsi tujuan tidak boleh kosong';
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
      // Later, we will add logic to process the goal
      print('Goal Submitted: ${_goalController.text}');
      // Potentially clear the text field after submission
      // _goalController.clear();
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
          // Using crossAxisAlignment to stretch the TextField and Button horizontally
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Added some spacing at the top
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
                // Clear error message when user starts typing
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
            // This Spacer pushes the content to the top, if Column's mainAxisAlignment is start
            // const Spacer(), 
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
