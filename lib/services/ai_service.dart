import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
// Removed: import 'package:flutter/services.dart' show rootBundle; // No longer needed for service account
// Removed: import 'package:googleapis_auth/auth_io.dart' as auth; // No longer needed
// Removed: import '../utils/api_config_bridge.dart'; // No longer needed

// Note: Enums like HabitType, Recurrence are not directly used in this service's prompts
// but are part of the broader application logic that consumes this service's output.

class AIService {
  // Initialize Firebase Functions, targeting the region of your 'chatWithGemini' function
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
      region:
          'us-central1'); // Ensure this matches your Firebase function region

  // The model name is now managed by the Firebase function ('gemini-2.0-flash' as per functions/index.js)

  AIService() {
    // No async initialization needed here anymore
  }

  Future<Map<String, dynamic>?> _callFirebaseGemini(
      List<Map<String, dynamic>> parts,
      {required String callingFunctionName}) async {
    try {
      print(
          "[$callingFunctionName] Calling Firebase function 'chatWithGemini' with ${parts.length} parts.");
      final HttpsCallable callable = _functions.httpsCallable('chatWithGemini');
      print(
          "[$callingFunctionName] Sending to Firebase 'chatWithGemini'. Parts: ${jsonEncode(parts)}");
      final HttpsCallableResult result = await callable.call({'parts': parts});

      print(
          "[$callingFunctionName] Firebase function response raw data: ${result.data}");

      if (result.data != null &&
          result.data['success'] == true &&
          result.data['message'] != null) {
        // The 'message' from Firebase should be the direct JSON object from Gemini
        if (result.data['message'] is Map) { // More general Map check
          try {
            // Attempt to cast to Map<String, dynamic>
            return Map<String, dynamic>.from(result.data['message'] as Map);
          } catch (e) {
            print("[$callingFunctionName] Error casting 'message' from Map to Map<String, dynamic>: $e");
            return null;
          }
        } else if (result.data['message'] is String) {
          // If it's a string, try to parse it (though Firebase function should return object)
          try {
            return jsonDecode(result.data['message']) as Map<String, dynamic>;
          } catch (e) {
            print(
                "[$callingFunctionName] Error decoding 'message' string from Firebase: $e. Message was: ${result.data['message']}");
            return null;
          }
        } else {
          print(
              "[$callingFunctionName] Firebase function 'message' is not a Map or String: ${result.data['message'].runtimeType}");
          return null;
        }
      } else {
        String? errorMessage = result.data?['message']?.toString();
        print(
            "[$callingFunctionName] Firebase function call was not successful or 'message' is missing. Success: ${result.data?['success']}, Message: $errorMessage");
        return null; // Or throw an exception based on how you want to handle this
      }
    } on FirebaseFunctionsException catch (e) {
      print(
          "[$callingFunctionName] FirebaseFunctionsException: ${e.code} - ${e.message}");
      print("Details: ${e.details}");
      return null;
    } catch (e, stacktrace) {
      print(
          "[$callingFunctionName] Generic error calling Firebase function: $e");
      print("Stacktrace: $stacktrace");
      return null;
    }
  }

  Future<Map<String, dynamic>?> breakDownHabit(String habitDescription) async {
    final prompt = '''
    System Prompt: Gamified Self-Improvement Framework

    I. Overview:
    You are to understand and operate within a gamified self-improvement system designed to help users develop positive habits and track their progress. The system revolves around creating structured tasks, assigning them to relevant character attributes, and defining their difficulty and recurrence. The core principle is to reflect real-world progress in a gradual and fair manner.

    II. Core Character Attributes (Stats):
    Users will earn points for the following attributes based on the tasks they complete. The mnemonic for these attributes is HICCUP.

        Health (H)
            Description: Reflects the user's physical well-being and healthy lifestyle choices. This attribute increases when the user completes tasks related to maintaining physical health, such as proper diet, adequate sleep, and light fitness activities focused on upkeep rather than building muscle or strength.
            Goal: To foster sustainable healthy living habits.

        Intelligence (I)
            Description: Reflects the user's development of knowledge and skills. This attribute increases when the user engages in activities such as learning, reading, attending classes, or writing.
            Focus: Intellectual growth and self-development.

        Cleanliness (C)
            Description: Measures the user's discipline in maintaining personal hygiene and environmental tidiness. Points are gained from activities like cleaning the house, doing laundry, or practicing neat personal habits.
            Association: Cleanliness is associated with peace of mind and an orderly life.

        Charisma (C)
            Description: Represents the user's social interaction skills, self-confidence, and presence as perceived by others. This stat increases through activities involving communication, teamwork, or public speaking.
            Suitability: Ideal for building connections and interpersonal skills.

        Unity (U)
            Description: Represents the user's inner state, mental well-being, and peace. This stat increases through activities such as meditation, journaling, taking breaks from social media, or spiritual practices.
            Goal: Helps the user maintain stable mental health and life focus.

        Power (P)
            Description: Focuses on the user's physical strength, stamina, and energy. This stat increases when the user performs active physical tasks like sports, workouts, or strenuous activities.
            Emphasis: Physical development and training discipline.

    III. Task Breakdown Instructions:
    Given a user's habit description, break it down into 3-5 actionable, specific, and measurable tasks. For each task:
    1.  Define a clear "taskName".
    2.  Suggest a "taskDescription" that elaborates on how to perform the task.
    3.  Determine the primary "taskAttribute" from HICCUP that this task develops.
    4.  Assign a "taskDifficulty" (Easy, Medium, Hard).
    5.  Suggest a "taskRecurrence" (Daily, Weekly, Monthly, Once).

    User's Habit Description: "$habitDescription"

    Respond with ONLY a JSON object containing a single key "tasks". The value of "tasks" should be an array of JSON objects, where each object represents a task and has the following keys:
    - "taskName": string
    - "taskDescription": string
    - "taskAttribute": string (must be one of H, I, C, C, U, P)
    - "taskDifficulty": string (must be one of Easy, Medium, Hard)
    - "taskRecurrence": string (must be one of Daily, Weekly, Monthly, Once)

    Do not use markdown code fences.
    Example:
    {
      "tasks": [
        {
          "taskName": "Read 1 Chapter",
          "taskDescription": "Read one chapter from 'Atomic Habits' focusing on habit formation techniques.",
          "taskAttribute": "I",
          "taskDifficulty": "Medium",
          "taskRecurrence": "Daily"
        },
        {
          "taskName": "Morning Hydration",
          "taskDescription": "Drink a full glass of water immediately after waking up.",
          "taskAttribute": "H",
          "taskDifficulty": "Easy",
          "taskRecurrence": "Daily"
        }
      ]
    }
    ''';

    final List<Map<String, dynamic>> requestParts = [
      {'text': prompt}
    ];
    final aiResponse = await _callFirebaseGemini(requestParts,
        callingFunctionName: 'breakDownHabit');

    if (aiResponse != null &&
        aiResponse.containsKey('tasks') &&
        aiResponse['tasks'] is List) {
      // Basic validation of the structure
      final tasksList = aiResponse['tasks'] as List;
      if (tasksList
          .every((task) => task is Map && task.containsKey('taskName'))) {
        return aiResponse;
      }
    }
    print(
        "Error or unexpected structure in breakDownHabit AI response: $aiResponse");
    return null; // Fallback if AI response is not as expected
  }

  Future<Map<String, dynamic>> verifyTaskCompletion({
    required String taskDescription, // This is the original task's description
    String? completionDescription, // User's text proof
    Uint8List? imageData, // User's image proof
  }) async {
    if (imageData == null &&
        (completionDescription == null || completionDescription.isEmpty)) {
      return {
        'isValid': false,
        'reason': 'No description or image provided as proof.'
      };
    }

    final List<Map<String, dynamic>> requestParts = [];

    String instruction = '''
    System Prompt: Gamified Self-Improvement Framework

    I. Overview:
    You are to understand and operate within a gamified self-improvement system designed to help users develop positive habits and track their progress. The system revolves around completing tasks that enhance specific character attributes, earn experience points (EXP) for leveling, and accumulate Star Currency for in-system purchases. The core principle is to reflect real-world progress in a gradual and fair manner.

    II. Core Character Attributes (Stats):
    Users will earn points for the following attributes based on the tasks they complete. The mnemonic for these attributes is HICCUP.

        Health (H)
            Description: Reflects the user's physical well-being and healthy lifestyle choices. This attribute increases when the user completes tasks related to maintaining physical health, such as proper diet, adequate sleep, and light fitness activities focused on upkeep rather than building muscle or strength.
            Goal: To foster sustainable healthy living habits.
            Example Tasks & Points:
                Drink 1 glass of water (Easy): +0.5 Health Points
                Sleep for at least 7 hours (Easy): +0.5 Health Points
                Consume fruits/vegetables today (Medium): +1 Health Point
                Avoid junk food for the entire day (Medium): +1 Health Point
                Consult a doctor / undergo a light medical check-up (Hard): +2 Health Points

        Intelligence (I)
            Description: Reflects the user's development of knowledge and skills. This attribute increases when the user engages in activities such as learning, reading, attending classes, or writing.
            Focus: Intellectual growth and self-development.
            Example Tasks & Points:
                Read an educational article (Easy): +0.5 Intelligence Points
                Watch a 10-minute educational video (Easy): +0.5 Intelligence Points
                Attend a 1-hour webinar/online course (Medium): +1 Intelligence Point
                Create a summary of study material (Medium): +1 Intelligence Point
                Complete a new learning module (Hard): +2 Intelligence Points

        Cleanliness (C)
            Description: Measures the user's discipline in maintaining personal hygiene and environmental tidiness. Points are gained from activities like cleaning the house, doing laundry, or practicing neat personal habits.
            Association: Cleanliness is associated with peace of mind and an orderly life.
            Example Tasks & Points:
                Take a bath/shower (Easy): +0.5 Cleanliness Points
                Wash dishes after a meal (Easy): +0.5 Cleanliness Points
                Clean the bathroom (Medium): +1 Cleanliness Point
                Organize a wardrobe (Medium): +1 Cleanliness Point
                Thoroughly clean a room (Hard): +2 Cleanliness Points

        Charisma (C)
            Description: Represents the user's social interaction skills, self-confidence, and presence as perceived by others. This stat increases through activities involving communication, teamwork, or public speaking.
            Suitability: Ideal for building connections and interpersonal skills.
            Example Tasks & Points:
                Give someone a compliment (Easy): +0.5 Charisma Points
                Greet a friend/colleague warmly (Easy): +0.5 Charisma Points
                Actively participate in a group discussion (Medium): +1 Charisma Point
                Voluntarily help someone (Medium): +1 Charisma Point
                Give a presentation in public (Hard): +2 Charisma Points

        Unity (U)
            Description: Represents the user's inner state, mental well-being, and peace. This stat increases through activities such as meditation, journaling, taking breaks from social media, or spiritual practices.
            Goal: Helps the user maintain stable mental health and life focus.
            Example Tasks & Points:
                Write down 3 things you are grateful for today (Easy): +0.5 Unity Points
                Meditate or pray for 5 minutes (Easy): +0.5 Unity Points
                Journal emotions or reflections for the day (Medium): +1 Unity Point
                Stay offline from social media for 6 hours (Medium): +1 Unity Point
                Complete a full-day digital detox (no social media at all) (Hard): +2 Unity Points

        Power (P)
            Description: Focuses on the user's physical strength, stamina, and energy. This stat increases when the user performs active physical tasks like sports, workouts, or strenuous activities.
            Emphasis: Physical development and training discipline.
            Example Tasks & Points:
                Stretch for 3 minutes (Easy): +0.5 Power Points
                Perform 20 push-ups/squats (Easy): +0.5 Power Points
                Go for a 15-minute jog or light workout (Medium): +1 Power Point
                Attend an exercise class (yoga/gym) (Medium): +1 Power Point
                Engage in intense exercise like a 5km run / 1-hour futsal game (Hard): +2 Power Points

    III. Reward System Mechanics:
    The reward system integrates character stats (HICCUP), Experience Points (EXP), and leveling.

        Stat Point Allocation:
            Upon task completion, the character receives points for the specific attribute associated with that task (as detailed above).
            Point values based on task difficulty:
                Easy Task: +0.5 attribute points
                Medium Task: +1 attribute point
                Hard Task: +2 attribute points

        Experience Points (EXP):
            Every task also grants EXP based on its difficulty, regardless of which attribute it affects.
            EXP values based on task difficulty:
                Easy Task: +5 EXP
                Medium Task: +10 EXP
                Hard Task: +20 EXP

        Star Currency:
            An in-system currency used to purchase items from a "Shop."
            Star Currency earned based on task difficulty:
                Easy Task: +10 stars
                Medium Task: +25 stars
                Hard Task: +50 stars

        Leveling:
            The system incorporates a leveling mechanism based on accumulated EXP.
            Level calculation: Level = 1 + (EXP / 100)²

    VERIFICATION INSTRUCTIONS (IMPORTANT - FOLLOW THESE STRICTLY):
    Critically assess if the provided evidence (text description and/or image) CONVINCINGLY demonstrates that the task was completed properly and meets ALL requirements.
    
    A task completion is ONLY valid if ALL of the following criteria are met:
    1. The description provides SPECIFIC DETAILS about HOW the task was completed, not just that it was done
    2. The user demonstrates understanding of the task's purpose and objectives
    3. There is clear evidence of genuine effort appropriate to the task's difficulty level
    4. The completion contains MEASURABLE outcomes or tangible results wherever applicable
    5. If an image is provided, it must clearly show relevant evidence that aligns with the task description
    
    REJECT any completion that:
    • Is excessively vague or generic (e.g., "I did it" or just repeating the task title)
    • Lacks specific details about the completion process
    • Appears insincere or shows minimal effort
    • Contains inconsistencies between the task and claimed completion
    • Does not provide concrete evidence of actual task completion
    
    When determining which HICCUP attribute the task develops, carefully analyze the exact nature of the task and match it to the most appropriate attribute based on the detailed descriptions provided earlier.

    Original Task Description: $taskDescription
    ''';

    if (completionDescription != null && completionDescription.isNotEmpty) {
      instruction += '\nUser Completion Description: $completionDescription';
    }
    requestParts.add({"text": instruction});

    if (imageData != null) {
      requestParts.add({
        "inlineData": {
          "mimeType":
              "image/jpeg", // Or image/png, Firebase function should handle this
          "data": base64Encode(imageData)
        }
      });
    }

    requestParts.add({
      "text": '''
    Respond with ONLY a JSON object containing the following keys:
    - "isValid": boolean (true if the completion is valid, false otherwise)
    - "reason": string (MUST provide a detailed explanation of WHY the completion is valid or invalid - this is REQUIRED for BOTH valid and invalid responses)
    - "suggestedAttribute": string (suggest which HICCUP attribute this task primarily develops based on original task description)
    
    Do not use markdown code fences.
    Example of valid response: {"isValid": true, "reason": "The user provided specific details about completing their 30-minute workout, including which exercises they performed, duration, and how they felt afterward. The image shows a completed workout tracker that matches the description.", "suggestedAttribute": "Power"}
    Example of invalid response: {"isValid": false, "reason": "The description only restates the task title without providing any specific details about how the meditation was performed, for how long, or what techniques were used. There's no evidence of actual completion beyond claiming it was done.", "suggestedAttribute": "Unity"}
    '''
          .trim()
    });

    final aiResponse = await _callFirebaseGemini(requestParts,
        callingFunctionName: 'verifyTaskCompletion');

    if (aiResponse != null &&
        aiResponse.containsKey('isValid') &&
        aiResponse['isValid'] is bool) {
      final reason = aiResponse['reason'];
      final attribute = aiResponse['suggestedAttribute'];

      if ((reason == null || reason is String) &&
          (attribute == null || attribute is String)) {
        return {
          'isValid': aiResponse['isValid'],
          'reason': (reason == null || reason.isEmpty)
              ? (aiResponse['isValid']
                  ? 'Completion verified.'
                  : 'Completion could not be verified.')
              : reason,
          'suggestedAttribute': attribute ?? 'Unknown',
        };
      }
    }
    print(
        "Error or unexpected structure in verifyTaskCompletion AI response: $aiResponse");
    // Fallback if AI response is not as expected
    return {
      'isValid': false,
      'reason': 'AI verification failed or returned an unexpected response.',
      'suggestedAttribute': 'Unknown'
    };
  }

  Future<Map<String, dynamic>> validateHabitDescription(
      String description) async {
    final prompt = '''
    System Prompt: Habit Description Validation

    You are an AI assistant responsible for validating user input for a habit tracking application.
    Your goal is to determine if a user's description of a habit or goal is coherent, specific enough
    to be broken down into actionable tasks, and genuinely related to self-improvement.

    Criteria for a VALID habit description:
    1.  Clarity: The description is understandable and not gibberish.
    2.  Specificity: It's not overly vague (e.g., "be better," "improve myself"). It should hint at concrete actions.
    3.  Relevance: It pertains to personal development, skill-building, health, or well-being.
    4.  Actionability (Implied): It seems possible to derive smaller, actionable steps from it.
    5.  Sincerity: It doesn't appear to be a test message, placeholder, or nonsensical input.

    Criteria for an INVALID habit description:
    1.  Nonsensical: Random characters, gibberish (e.g., "asdfjkl;", "test test").
    2.  Extremely Vague: So general that no clear actions can be inferred (e.g., "be good," "live life").
    3.  Inappropriate Content: Offensive, harmful, or unrelated to self-improvement.
    4.  Not a Habit/Goal: Statements that aren't habits or goals (e.g., "the sky is blue," "I like pizza").
    5.  Too Short/Unclear: Lacks sufficient detail to understand the intent (e.g., "read", "exercise" - without more context, these might be too vague, but "read a book" or "exercise daily" is better).

    User input: "$description"

    Determine if this input is valid for AI processing into tasks.
    
    Respond with ONLY a JSON object containing the following keys:
    - "isValid": boolean (true if the input is valid, false otherwise)
    - "reason": string (explain concisely WHY the input is valid or invalid - this must be detailed and helpful)
    
    Do not use markdown code fences.
    Example (Valid):
    User input: "Learn to play the guitar by practicing chords daily"
    {
      "isValid": true,
      "reason": "The description is clear, specific, and outlines an actionable self-improvement goal."
    }

    Example (Invalid - Too Vague):
    User input: "Be more productive"
    {
      "isValid": false,
      "reason": "The description 'Be more productive' is too vague. Please specify what you want to be more productive in or what actions you plan to take."
    }

    Example (Invalid - Nonsensical):
    User input: "gjhgjg jhgjhg"
    {
      "isValid": false,
      "reason": "The input appears to be nonsensical and cannot be processed as a habit."
    }
    ''';

    final List<Map<String, dynamic>> requestParts = [
      {'text': prompt}
    ];
    final aiResponse = await _callFirebaseGemini(requestParts,
        callingFunctionName: 'validateHabitDescription');

    if (aiResponse != null &&
        aiResponse.containsKey('isValid') &&
        aiResponse['isValid'] is bool) {
      final reason = aiResponse['reason'];
      if (reason == null || reason is String) {
        return {
          'isValid': aiResponse['isValid'],
          'reason': (reason == null || reason.isEmpty)
              ? (aiResponse['isValid']
                  ? 'Description is valid for processing.'
                  : 'Description is not detailed enough for processing.')
              : reason,
        };
      }
    }
    print(
        "Error or unexpected structure in validateHabitDescription AI response: $aiResponse");
    // Fallback for client-side basic validation if AI call fails or returns malformed data
    bool basicIsValid =
        description.length >= 10 && !description.toLowerCase().contains("test");
    return {
      'isValid': basicIsValid,
      'reason': basicIsValid
          ? 'Basic validation passed (AI validation unavailable or failed).'
          : 'Description is too short or seems like a test (AI validation unavailable or failed).'
    };
  }
}
