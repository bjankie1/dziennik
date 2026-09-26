import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/ai_chat_message.dart';
import 'school_ai_context_builder.dart';

/// Service integrating Firebase AI Logic (`firebase_ai: ^4.0.0`, Gemini Developer API)
/// with support for `gemini-3.8-flash` (default) and `gemini-3.1-pro-preview` (deep analysis),
/// structured JSON citations (`responseSchema`), and automatic fallback (`REQ-AI-01`, `REQ-AI-02`).
class SchoolAiAssistantService {
  const SchoolAiAssistantService();

  /// Structured JSON output schema enforcing grounded answers, clickable citations,
  /// and optional Google Calendar / Smart To-Do quick actions (`20-AI-SPEC.md`).
  static Schema get responseSchema => Schema.object(
        properties: {
          'answer': Schema.string(
            description:
                'Odpowiedź po polsku, zwięzła, pomocna, sformatowana w Markdown (pogrubienia **...** dla kluczowych dat, przedmiotów i ocen).',
          ),
          'sources': Schema.array(
            description:
                'Lista źródeł z dziennika szkolnego, na których oparto odpowiedź.',
            items: Schema.object(
              properties: {
                'type': Schema.enumString(
                  enumValues: [
                    'message',
                    'timetable',
                    'exam',
                    'grade',
                    'attendance',
                    'announcement',
                    'task',
                  ],
                  description: 'Typ źródła w dzienniku.',
                ),
                'label': Schema.string(
                  description:
                      'Krótka etykieta na pigułce, np. "📩 Wiadomość: Wycieczka (12.05)" lub "📅 Plan lekcji: Matematyka".',
                ),
                'route': Schema.string(
                  description:
                      'Ścieżka w aplikacji: /wiadomosci, /plan-lekcji, /oceny, /frekwencja lub /zadania.',
                ),
                'targetId': Schema.string(
                  description: 'Opcjonalne ID wiadomości lub zasobu.',
                  nullable: true,
                ),
              },
              optionalProperties: ['targetId'],
            ),
          ),
          'suggestedEvent': Schema.object(
            description:
                'Wypełnij, jeśli odpowiedź dotyczy wydarzenia z konkretną datą (sprawdzian, wycieczka, zebranie z rodzicami).',
            nullable: true,
            properties: {
              'title': Schema.string(
                description: 'Tytuł wydarzenia do Kalendarza Google.',
              ),
              'date': Schema.string(
                description: 'Data wydarzenia w formacie YYYY-MM-DD.',
              ),
              'startTime': Schema.string(
                description: 'Godzina rozpoczęcia HH:MM (np. 08:00 lub 17:30).',
                nullable: true,
              ),
              'description': Schema.string(
                description: 'Szczegóły wydarzenia do opisu w kalendarzu.',
              ),
            },
            optionalProperties: ['startTime'],
          ),
          'suggestedTask': Schema.object(
            description:
                'Wypełnij, jeśli warto dodać zadanie do listy Smart To-Do (np. nauka do sprawdzianu, opłata na wycieczkę).',
            nullable: true,
            properties: {
              'title': Schema.string(description: 'Tytuł zadania To-Do.'),
              'dueDate': Schema.string(
                description: 'Termin wykonania w formacie YYYY-MM-DD.',
                nullable: true,
              ),
              'category': Schema.enumString(
                enumValues: ['exam', 'homework', 'trip', 'other'],
              ),
            },
            optionalProperties: ['dueDate'],
          ),
        },
        optionalProperties: ['suggestedEvent', 'suggestedTask'],
      );

  /// Sends [question] to Gemini via `FirebaseAI.googleAI` with the full gradebook
  /// context and recent conversation [history]. Automatically retries with fallback
  /// Gemini model aliases if a preview/version alias is unavailable in the region,
  /// and falls back to [SchoolAiContextBuilder.generateGroundedLocalReply] if offline.
  Future<AiChatMessage> askQuestion({
    required String question,
    required SchoolAiContextSnapshotInput contextInput,
    required AiModelTier selectedModel,
    List<AiChatMessage> history = const [],
  }) async {
    final trimmed = question.trim();
    final msgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final systemPrompt =
        SchoolAiContextBuilder.buildSystemInstruction(contextInput);

    final candidateModels = <String>[
      selectedModel.modelId,
      ...selectedModel.fallbackModelIds,
    ];

    // Build up to 10 recent turns of multi-turn chat history
    final recentTurns = history
        .where((m) => !m.isError && m.text.trim().isNotEmpty)
        .toList();
    final historyWindow = recentTurns.length > 10
        ? recentTurns.sublist(recentTurns.length - 10)
        : recentTurns;

    final chatHistory = <Content>[
      for (final turn in historyWindow)
        if (turn.isUser)
          Content.text(turn.text)
        else
          Content.model([TextPart(turn.text)]),
    ];

    for (final candidateModelId in candidateModels) {
      try {
        final googleAI = FirebaseAI.googleAI();
        final model = googleAI.generativeModel(
          model: candidateModelId,
          systemInstruction: Content.system(systemPrompt),
          generationConfig: GenerationConfig(
            temperature: 0.2,
            maxOutputTokens: 1200,
            responseMimeType: 'application/json',
            responseSchema: responseSchema,
          ),
        );

        final chat = model.startChat(history: chatHistory);
        final response = await chat
            .sendMessage(Content.text(trimmed))
            .timeout(const Duration(seconds: 25));

        final rawText = response.text;
        if (rawText != null && rawText.trim().isNotEmpty) {
          return AiChatMessage.fromGeminiStructuredJson(
            id: msgId,
            rawJson: rawText,
            viewerRole: contextInput.viewerRole,
            modelUsed: candidateModelId,
          );
        }
      } catch (e) {
        debugPrint(
          '[SchoolAiAssistantService] Model $candidateModelId attempt failed: $e',
        );
        // Continue to next candidate model in fallback chain
      }
    }

    // Resilient local grounded fallback when offline or before `firebase init ailogic` is provisioned
    return SchoolAiContextBuilder.generateGroundedLocalReply(
      question: trimmed,
      input: contextInput,
      id: msgId,
      modelUsed: selectedModel.modelId,
    );
  }
}
