import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/faultrecord.dart';
import 'package:flutter/foundation.dart';

class AiCoachService {
  static const _apiKey = 'AIzaSyCcw8k3QiSZdQh43VCKqw_YB9XGdw7hSBY'; 

  Future<String> generateWorkoutSummary({
    required String workoutName,
    required int totalReps,
    required List<FaultRecord> faultRecords,
  }) async {
    if (_apiKey.isEmpty) {
      return "Setup error: Please paste your API key in ai_coach_service.dart.";
    }

    try {
      // Using the absolute latest and fastest model!
      final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: _apiKey);

      // 1. Filter out duplicate consecutive faults to keep the prompt clean for the AI
      final uniqueFaults = <String>{};
      for (var record in faultRecords) {
        // We only care about sending the text string, not the 33 skeletal landmarks!
        if (record.feedbackMessage != null && record.feedbackMessage!.isNotEmpty) {
          uniqueFaults.add(record.feedbackMessage!);
        }
      }

      // 2. Build the prompt
      final promptBuffer = StringBuffer();
      promptBuffer.writeln('You are a supportive and highly knowledgeable fitness coach.');
      promptBuffer.writeln('Your client just finished a set of $totalReps reps of $workoutName.');
      
      if (uniqueFaults.isEmpty) {
        promptBuffer.writeln('They performed the exercise with perfect form! No major errors were detected.');
        promptBuffer.writeln('Write a short, punchy 2-sentence congratulatory message to keep them motivated.');
      } else {
        promptBuffer.writeln('During the set, the following form errors were detected by our tracking system:');
        for (var fault in uniqueFaults) {
          promptBuffer.writeln('- $fault');
        }
        promptBuffer.writeln('\nWrite a short, encouraging 2-to-3 sentence summary.');
        promptBuffer.writeln('Acknowledge their hard work, but gently highlight the main form issue they should focus on next time. Do not make a bulleted list.');
      }

      // 3. Send the request
      final content = [Content.text(promptBuffer.toString())];
      final response = await model.generateContent(content);

      return response.text ?? "Great job on your workout! Keep pushing!";
      
    } catch (e) {
      debugPrint('AI Coach generation failed: $e');
      return "Awesome effort today! Your form data was saved successfully."; 
    }
  }
}