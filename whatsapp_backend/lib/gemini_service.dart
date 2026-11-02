import 'package:google_generative_ai/google_generative_ai.dart';
import 'env.dart';

class GeminiService {
  static Future<String> generateResponse(String incomingMessage) async {
    final apiKey = env['GEMINI_API_KEY'];
    if (apiKey == null) {
      print('Error: GEMINI_API_KEY is not defined.');
      return "I'm sorry, my AI configuration is currently unavailable.";
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "You are a professional sales agent for a POS software named 'Pro Tech Manager'. "
        "Your goal is to be helpful, concise, and persuasive. "
        "Answer customer inquiries about features, pricing, or support in a friendly, professional tone."
      ),
    );

    try {
      final response = await model.generateContent([Content.text(incomingMessage)]);
      return response.text ?? "I'm sorry, I couldn't process your request at this time.";
    } catch (e) {
      print('Exception from Gemini API: $e');
      return "I'm sorry, I encountered an error while processing your request.";
    }
  }
}
