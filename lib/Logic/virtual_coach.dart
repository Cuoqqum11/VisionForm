import '../models/faultrecord.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class AiCoachService {

  Future<String> generateWorkoutSummary({
    required String workoutName,
    required int totalReps,
    required List<FaultRecord> faultRecords,
  }) async {
    
    try {
      // 1. Grab the global instance that we initialized in main.dart!
      // By default, flutter_gemini routes this to gemini-1.5-flash under the hood.
      final gemini = Gemini.instance;

      // 2. Filter out duplicate consecutive faults
      final uniqueFaults = <String>{};
      for (var record in faultRecords) {
        if (record.feedbackMessage != null && record.feedbackMessage!.isNotEmpty) {
          uniqueFaults.add(record.feedbackMessage!);
        }
      }

      // 3. Build the prompt
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

      // 4. Send the request using flutter_gemini 3.0.0 syntax
      final response = await gemini.prompt(
        parts: [
          Part.text(promptBuffer.toString())
        ],
        model: 'gemini-3.5-flash', // You can choose a different model if you want
      );

      // Extract the text payload from the response object
      return response?.output ?? "Great job on your workout! Keep pushing!";
      
    } catch (e) {
      debugPrint('AI Coach generation failed: $e');
      return "Awesome effort today! (Note: AI summary failed to generate. Check console for details)."; 
    }
  }
}