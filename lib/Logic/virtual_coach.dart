import '../models/faultrecord.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'Groq_service.dart'; // ← NEW

class AiCoachService {

  Future<String> generateWorkoutSummary({
    required String workoutName,
    required int totalReps,
    required List<FaultRecord> faultRecords,
  }) async {

    // ── Build the shared prompt (same for both AI layers) ──────────────────
    final prompt = _buildCoachPrompt(
      workoutName: workoutName,
      totalReps: totalReps,
      faultRecords: faultRecords,
    );

    // ── Layer 1: Gemini ────────────────────────────────────────────────────
    try {
      debugPrint('🤖 [Layer 1] Trying Gemini for workout summary…');
      final gemini = Gemini.instance;

      final response = await gemini.prompt(
        parts: [Part.text(prompt)],
        model: 'gemini-1.5-flash',
      );

      final output = response?.output?.trim() ?? '';
      if (output.isEmpty) throw Exception('Gemini returned an empty response.');

      debugPrint('✅ [Layer 1] Gemini succeeded.');
      return output;

    } catch (geminiError) {
      debugPrint('⚠️ [Layer 1] Gemini failed: $geminiError');
    }

    // ── Layer 2: Groq / Llama 3 ───────────────────────────────────────────
    try {
      debugPrint('🦙 [Layer 2] Trying Groq (Llama 3) for workout summary…');
      final groqOutput = await GroqService.instance.complete(prompt);

      if (groqOutput == null || groqOutput.isEmpty) {
        throw Exception('Groq returned null or empty.');
      }

      debugPrint('✅ [Layer 2] Groq succeeded.');
      return groqOutput;

    } catch (groqError) {
      debugPrint('⚠️ [Layer 2] Groq failed: $groqError');
    }

    // ── Layer 3: Hardcoded offline fallback ───────────────────────────────
    debugPrint('🛡️ [Layer 3] Both APIs failed. Returning offline coach message.');
    return 'Awesome effort today! Keep up the good work. '
        'Stay hydrated and focus on maintaining steady, controlled form on your next set.';
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  String _buildCoachPrompt({
    required String workoutName,
    required int totalReps,
    required List<FaultRecord> faultRecords,
  }) {
    // Filter out duplicate consecutive faults
    final uniqueFaults = <String>{};
    for (var record in faultRecords) {
      if (record.feedbackMessage != null && record.feedbackMessage!.isNotEmpty) {
        uniqueFaults.add(record.feedbackMessage!);
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('You are a supportive and highly knowledgeable fitness coach.');
    buffer.writeln('Your client just finished a set of $totalReps reps of $workoutName.');

    if (uniqueFaults.isEmpty) {
      buffer.writeln('They performed the exercise with perfect form! No major errors were detected.');
      buffer.writeln('Write a short, punchy 2-sentence congratulatory message to keep them motivated.');
    } else {
      buffer.writeln('During the set, the following form errors were detected by our tracking system:');
      for (var fault in uniqueFaults) {
        buffer.writeln('- $fault');
      }
      buffer.writeln('\nWrite a short, encouraging 2-to-3 sentence summary.');
      buffer.writeln(
        'Acknowledge their hard work, but gently highlight the main form issue '
        'they should focus on next time. Do not make a bulleted list.',
      );
    }

    return buffer.toString();
  }
}