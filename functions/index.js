const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { GoogleGenerativeAI } = require("@google/generative-ai");

// Define the secret that will be loaded from Secret Manager
const geminiApiKey = defineSecret("GEMINI_API_KEY");

exports.chatWithGemini = onCall(
  {
    secrets: [geminiApiKey],
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    console.log("Received request:", JSON.stringify(request.data, null, 2));

    // Optional: Ensure the user is authenticated
    // if (!request.auth) {
    //   throw new HttpsError(
    //     "unauthenticated",
    //     "The function must be called while authenticated."
    //   );
    // }


    const { parts } = request.data;
    if (!parts || !Array.isArray(parts) || parts.length === 0) {
      console.error("Invalid parts received:", parts);
      throw new HttpsError(
        "invalid-argument",
        'The function must be called with a non-empty "parts" array argument.'
      );
    }
    // Log the received parts (first part's text for brevity if it exists)
    if (parts[0] && parts[0].text) {
      console.log("Received parts, first part text sample:", parts[0].text.substring(0, 100) + "...");
    } else {
      console.log("Received parts, first part is not text or does not exist.");
    }

    try {
      // Log the API key status (don't log the actual key)
      console.log("Initializing Gemini API client with API key");
      
      const genAI = new GoogleGenerativeAI(geminiApiKey.value());
      const model = genAI.getGenerativeModel({
        model: "gemini-2.0-flash", // Changed to a stable flash model
        generationConfig: {
          response_mime_type: "application/json", // Request raw JSON output
          temperature: 0.7,
          topP: 0.8,
          topK: 40,
          maxOutputTokens: 4096,
        },
      });

      console.log("Sending parts to Gemini. Number of parts:", parts.length);
      
      const result = await model.generateContent({
        contents: [{
          role: "user", // Assuming all parts from client contribute to a single user turn
          parts: parts, // Pass the received parts array directly
        }],
      });

      const response = result.response;
      if (!response) {
        throw new Error("No response received from Gemini API");
      }

      const rawText = response.text();
      console.log("Successfully got raw response from Gemini. Length:", rawText.length);

      // With response_mime_type: "application/json", rawText should be the JSON string.
      // Cleaning for ```json might still be a good fallback if the model occasionally adds it.
      let cleanedText = rawText;
      if (typeof rawText === 'string' && rawText.startsWith('```json')) {
        cleanedText = rawText.replace(/^```json\s*|\s*```$/g, "").trim();
      } else if (typeof rawText === 'string') {
        cleanedText = rawText.trim();
      }

      let geminiJsonPayload;
      try {
        geminiJsonPayload = JSON.parse(cleanedText);
        console.log("Successfully parsed cleaned Gemini response in Cloud Function.");
      } catch (e) {
        console.error("Failed to parse cleaned Gemini response as JSON. Text was:", cleanedText, "Error:", e);
        // If parsing fails, it means the AI didn't return valid JSON as expected by this prompt path.
        // This could be an error message or a non-JSON formatted string.
        // For functions like breakDownHabit that expect JSON, this is an issue.
        // We might need to decide if we return the cleanedText as-is or throw an error.
        // For now, let's assume for breakDownHabit, JSON is critical.
        throw new HttpsError("internal", `AI response was not valid JSON after cleaning: ${e.message}`);
      }
      
      // Ensure we return a proper JSON response, with the message being a stringified JSON
      // Return the parsed JSON object directly.
      // Firebase Functions will handle serializing this to the client.
      return { 
        success: true, 
        message: geminiJsonPayload 
      };
      
    } catch (error) {
      console.error("Error calling Gemini API:", error);
      
      // More detailed error handling
      let errorMessage = "An error occurred while processing your request.";
      let errorCode = "internal";
      
      if (error.response) {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx
        console.error("Gemini API Error Response:", error.response.status, error.response.data);
        errorMessage = `Gemini API Error: ${error.response.status} - ${JSON.stringify(error.response.data)}`;
      } else if (error.request) {
        // The request was made but no response was received
        console.error("No response received from Gemini API");
        errorMessage = "No response received from the AI service. Please try again.";
      } else {
        // Something happened in setting up the request that triggered an Error
        console.error("Error setting up Gemini API request:", error.message);
        errorMessage = `Error setting up AI service: ${error.message}`;
      }
      
      throw new HttpsError(
        errorCode,
        errorMessage
      );
    }
  }
);