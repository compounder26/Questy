import 'dart:convert';
import 'dart:io'; // For File operations - will be replaced by services for asset loading
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle; // Import for rootBundle
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../config/api_config.dart';
// Removed: import '../models/enums/habit_type.dart';
// Removed: import '../models/enums/recurrence.dart';
// These enums are used by the app's internal models, not directly by the AI service prompts in this version.

class AIService {
  final String _projectId = ApiConfig.vertexProjectId;
  final String _region = ApiConfig.vertexRegion;
  final String _serviceAccountKeyPath = ApiConfig.vertexServiceAccountKeyPath;
  
  auth.AutoRefreshingAuthClient? _authClient;

  // Model name - consider gemini-1.5-pro-latest for robust JSON and general tasks
  // or specific versions like gemini-1.5-flash-latest if speed/cost is a bigger concern.
  // gemini-2.5-pro might require specific endpoint or preview access.
  // For Gemini 2.5 Flash, verify the exact model ID in Vertex AI Model Garden for your region.
  // Example: 'gemini-2.5-flash-preview', 'gemini-2.5-flash-latest', or a specific versioned ID.
  // Using 'gemini-1.5-flash-latest' as a known available and capable Flash model.
  // Please update if you find a specific '2.5-flash' variant you want to use.
  final String _modelName = 'gemini-2.0-flash'; // Using the ID from the provided documentation

  AIService() {
    // Initialization of auth client is now async
  }

  Future<void> _initialize() async {
    if (_authClient != null) return;

    try {
      // Load the service account key from Flutter's asset bundle
      final String content = await rootBundle.loadString(ApiConfig.vertexServiceAccountKeyPath);
      final credentials = auth.ServiceAccountCredentials.fromJson(jsonDecode(content));
      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      _authClient = await auth.clientViaServiceAccount(credentials, scopes);
      print("Vertex AI Service Account authenticated successfully from assets.");
    } catch (e, stacktrace) {
      print("Error initializing Vertex AI auth from assets: $e");
      print("Stacktrace: $stacktrace");
      print("Please ensure '${ApiConfig.vertexServiceAccountKeyPath}' is correctly listed in pubspec.yaml's assets section and the file exists.");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> breakDownHabit(String habitDescription) async {
    await _initialize(); // Ensure client is initialized
    if (_authClient == null) {
      print("Error: Auth client not initialized for breakDownHabit.");
      return null;
    }

    // Note: Using gemini-1.5-pro-latest or similar. For "gemini-2.5-pro", ensure it's available
    // and the model ID is correct (e.g., publishers/google/models/gemini-2.5-pro)
    final url = Uri.parse(
        'https://$_region-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_region/publishers/google/models/$_modelName:generateContent');

    final prompt = '''
    Analyze the following user request for a new goal or habit. Based on the description, determine the following attributes.
    Your entire response MUST be a single, valid JSON object. Do NOT include any text, explanations, thoughts, comments, or any non-JSON characters (like 'inhaled', 'thought', etc.) anywhere, neither outside nor inside the JSON structure (e.g., between key-value pairs, within arrays, or within string values unless they are part of the actual requested data).
    Do not use markdown code fences (e.g., ```json ... ```). The response must start with '{' and end with '}'. Ensure all string values within the JSON are properly escaped if they contain special characters.
x
    The JSON object must contain the following keys:
    1.  `concisePromptTitle`: Create a short, clear title summarizing the overall goal/habit (e.g., "Learn Flutter Basics", "Daily Morning Meditation").
    2.  `habitType`: Classify if this is a one-off 'goal' or a recurring 'habit'. Use the exact strings "goal" or "habit".
    3.  `recurrence`: If it's a 'habit', determine the recurrence. Use the exact strings "daily", "weekly", or "none". If it's a 'goal', use "none".
    4.  `weeklyTarget`: If `recurrence` is "weekly", determine the target number of completions per week (e.g., for "exercise 3 times a week", `weeklyTarget` would be 3). If not applicable, set to null.
    5.  `endDate`: Determine if the request implies a specific duration (e.g., "for 3 weeks", "in 6 months", "by Dec 31st"). If a duration is found, calculate the corresponding end date from today (assume today is ${DateTime.now().toIso8601String().substring(0,10)}) and return it as an ISO 8601 string (YYYY-MM-DD). If no duration or it seems permanent, return null.
    6.  `tasks`: Break down the overall goal/habit into smaller, manageable sub-tasks. For each task, provide:
        *   `task`: A clear description of the sub-task.
        *   `difficulty`: Estimated difficulty ("Easy", "Medium", "Hard").
        *   `estimatedTime`: Estimated time to complete the sub-task in minutes (return as an integer).

    User Request: $habitDescription
    JSON Response:
    ''';

    final requestBody = jsonEncode({
      "contents": [
        {
          "role": "user",
          "parts": [{"text": prompt}]
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json", // Request JSON output directly
      }
    });

    try {
      final response = await _authClient!.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print("Vertex AI Raw Response Status: ${response.statusCode}");
      print("Vertex AI Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        
        // Vertex AI response structure for generateContent
        // It usually has a "candidates" array.
        if (responseJson['candidates'] != null && 
            responseJson['candidates'] is List && 
            (responseJson['candidates'] as List).isNotEmpty &&
            responseJson['candidates'][0]['content'] != null &&
            responseJson['candidates'][0]['content']['parts'] != null &&
            (responseJson['candidates'][0]['content']['parts'] as List).isNotEmpty &&
            responseJson['candidates'][0]['content']['parts'][0]['text'] != null) {
          
          // The responseMimeType: "application/json" should make the model output raw JSON string
          // If the model still wraps it, this parsing is necessary.
          // For now, assuming it's a raw JSON string directly.
          String modelOutputText = responseJson['candidates'][0]['content']['parts'][0]['text'] as String;
          print("Extracted model output text (raw): $modelOutputText");

          // Attempt to extract only the JSON part using a regex
          // This looks for a string that starts with { and ends with }, accounting for nested structures.
          // It's a common approach but might not be foolproof for all edge cases of malformed strings.
          final RegExp jsonRegex = RegExp(r'\\{[\\s\\S]*\\}');
          final Match? jsonMatch = jsonRegex.firstMatch(modelOutputText);

          if (jsonMatch != null) {
            modelOutputText = jsonMatch.group(0)!;
            print("Extracted model output text (regex cleaned): $modelOutputText");
          } else {
            print("Warning: Could not extract a clear JSON structure using regex. Attempting to parse raw text.");
          }
          
          // Attempt to remove known model artifacts like "inhaled" that might be injected inside the JSON
          // This is a workaround for model behavior that inserts non-JSON text within the JSON structure.
          modelOutputText = modelOutputText.replaceAll(RegExp(r'\\n\s*inhaled\s*\\n(?=\\s*})'), '\\n'); // Specifically targets 'inhaled' before a closing brace of an object in a list
          modelOutputText = modelOutputText.replaceAll(RegExp(r'\\n\s*inhaled\s*'), ''); // More general cleanup of 'inhaled' if the above is too specific
          print("Extracted model output text (artifact cleaned): $modelOutputText");
          
          try {
            final decoded = jsonDecode(modelOutputText);

            if (decoded is Map<String, dynamic>) {
               if (decoded.containsKey('concisePromptTitle') &&
                   decoded.containsKey('habitType') &&
                   decoded.containsKey('recurrence') &&
                   decoded.containsKey('tasks') &&
                   decoded['tasks'] is List) {
                   // Basic validation for tasks list elements
                   bool tasksValid = true;
                   if ((decoded['tasks'] as List).isNotEmpty) {
                      for (var task in (decoded['tasks'] as List)) {
                         if (task is! Map<String, dynamic> ||
                             !task.containsKey('task') ||
                             !task.containsKey('difficulty') ||
                             !task.containsKey('estimatedTime')) {
                            tasksValid = false;
                            print("Error: Invalid task structure found: $task");
                            break;
                         }
                      }
                   }
                   if (tasksValid) return decoded;
                   print("Error: Tasks list contains invalid items.");
                   return null;
               } else {
                  print("Error: Decoded JSON map is missing required keys or tasks is not a list.");
                  print("Decoded map: $decoded");
                  return null;
               }
            } else {
              print("Error: Decoded JSON is not a map. Received: $decoded");
              return null;
            }
          } catch (e, stacktrace) {
            print("Error decoding extracted JSON from Vertex AI: $e");
            print("Model output text that failed to parse: $modelOutputText");
            print("Stacktrace: $stacktrace");
            return null;
          }
        } else {
          print("Error: Vertex AI response does not have the expected structure.");
          print("Full Response JSON: $responseJson");
          return null;
        }
      } else {
        print('Error calling Vertex AI: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e, stacktrace) {
      print('Error in breakDownHabit with Vertex AI: $e');
      print("Stacktrace: $stacktrace");
      return null;
    }
  }

  Future<Map<String, dynamic>> verifyTaskCompletion({
    required String taskDescription,
    String? completionDescription,
    Uint8List? imageData,
  }) async {
    await _initialize(); // Ensure client is initialized
     if (_authClient == null) {
      print("Error: Auth client not initialized for verifyTaskCompletion.");
       return {'isValid': false, 'reason': 'Authentication not initialized.'};
    }
    
    // For multimodal, gemini-1.5-pro-latest also works.
    // If using a different model specifically for vision, update _modelName or pass it.
    final url = Uri.parse(
        'https://$_region-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_region/publishers/google/models/$_modelName:generateContent');

    final parts = <Map<String, dynamic>>[];
    
    String instruction = '''
    Verify if the provided evidence (text description and/or image) truthfully indicates that the task was completed properly and meets the requirements.
    Consider if the person is:
    1. Being honest about their completion.
    2. Actually completing the task properly according to the task description.
    3. Not slacking or doing a minimal effort (unless the task itself is minimal).
    4. If an image is provided, assess if it visually supports the task completion.

    Task Description: $taskDescription
    ''';

    if (completionDescription != null && completionDescription.isNotEmpty) {
      instruction += '\nCompletion Description: $completionDescription';
    }
    parts.add({"text": instruction});

    if (imageData == null && (completionDescription == null || completionDescription.isEmpty)) {
      return {'isValid': false, 'reason': 'No description or image provided as proof.'};
    }
    
    if (imageData != null) {
      parts.add({
        "inlineData": {
          "mimeType": "image/jpeg", // Or image/png
          "data": base64Encode(imageData) 
        }
      });
    }
    
    parts.add({"text": '''
    Respond with ONLY a JSON object containing two keys:
    - "isValid": boolean (true if the completion is valid, false otherwise)
    - "reason": string (MUST provide a brief explanation ONLY if "isValid" is false, otherwise it should be null or an empty string)
    Do not use markdown code fences.
    Example of valid response: {"isValid": true, "reason": null}
    Example of invalid response: {"isValid": false, "reason": "The description lacks detail about the specific steps taken."}
    '''.trim()});


    final requestBody = jsonEncode({
      "contents": [{"role": "user", "parts": parts}],
      "generationConfig": {
        "responseMimeType": "application/json",
      }
    });

    try {
      final response = await _authClient!.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print("Vertex AI Verification Raw Response Status: ${response.statusCode}");
      print("Vertex AI Verification Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        if (responseJson['candidates'] != null &&
            (responseJson['candidates'] as List).isNotEmpty &&
            responseJson['candidates'][0]['content'] != null &&
            responseJson['candidates'][0]['content']['parts'] != null &&
            (responseJson['candidates'][0]['content']['parts'] as List).isNotEmpty &&
            responseJson['candidates'][0]['content']['parts'][0]['text'] != null) {

            final modelOutputText = responseJson['candidates'][0]['content']['parts'][0]['text'] as String;
            print("Extracted verification model output text: $modelOutputText");
            
            try {
              final decoded = jsonDecode(modelOutputText) as Map<String, dynamic>;
              if (decoded.containsKey('isValid') && decoded['isValid'] is bool) {
                 final reason = decoded['reason'];
                 if (reason == null || reason is String) {
                    return {
                        'isValid': decoded['isValid'],
                        'reason': (decoded['isValid'] == false && (reason == null || reason.isEmpty)) 
                                   ? 'AI rejected the completion but provided no specific reason.'
                                   : reason
                    };
                 }
              }
               print("Error: Decoded verification JSON has invalid structure or types.");
               print("Decoded response: $decoded");
               return {'isValid': false, 'reason': 'AI response structure invalid after decoding.'};

            } catch (e) {
              print("Error decoding verification JSON from Vertex AI: $e");
              print("Model output text for verification that failed to parse: $modelOutputText");
              return {'isValid': false, 'reason': 'Failed to parse AI response for verification.'};
            }
        } else {
          print("Error: Vertex AI verification response does not have the expected structure.");
          print("Full Response JSON: $responseJson");
          return {'isValid': false, 'reason': 'AI response format error (structure).'};
        }
      } else {
        print('Error calling Vertex AI for verification: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {'isValid': false, 'reason': 'Error communicating with AI for verification.'};
      }
    } catch (e, stacktrace) {
      print('Error in verifyTaskCompletion with Vertex AI: $e');
      print("Stacktrace: $stacktrace");
      return {'isValid': false, 'reason': 'Exception during AI verification call.'};
    }
  }
} 