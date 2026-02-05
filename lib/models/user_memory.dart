import 'dart:convert';

/// Lightweight user memory: name, goals, preferences.
/// Persisted so the AI can "remember" the user across sessions.
class UserMemory {
  const UserMemory({
    this.name,
    this.goals = const [],
    this.preferences = const [],
  });

  final String? name;
  final List<String> goals;
  final List<String> preferences;

  UserMemory copyWith({
    String? name,
    List<String>? goals,
    List<String>? preferences,
  }) {
    return UserMemory(
      name: name ?? this.name,
      goals: goals ?? this.goals,
      preferences: preferences ?? this.preferences,
    );
  }

  bool get isEmpty =>
      (name == null || name!.trim().isEmpty) && goals.isEmpty && preferences.isEmpty;

  /// One-line summary for system prompt.
  String toSystemPromptSummary() {
    final parts = <String>[];
    if (name != null && name!.trim().isNotEmpty) {
      parts.add('The user\'s name is ${name!.trim()}.');
    }
    if (goals.isNotEmpty) {
      parts.add('Goals: ${goals.map((g) => g.trim()).where((s) => s.isNotEmpty).join(", ")}.');
    }
    if (preferences.isNotEmpty) {
      parts.add('Preferences: ${preferences.map((p) => p.trim()).where((s) => s.isNotEmpty).join(", ")}.');
    }
    if (parts.isEmpty) return '';
    return 'Remember: ${parts.join(" ")}';
  }

  /// For UI: "I remember you're learning Flutter 🚀" (grammatically correct)
  List<String> get memoryChips {
    final chips = <String>[];
    if (name != null && name!.trim().isNotEmpty) {
      chips.add("I remember your name is ${name!.trim()}");
    }
    for (final g in goals) {
      final t = _normalizeGoalDisplay(g.trim());
      if (t.isEmpty) continue;
      final phrase = _goalReadsAsVerbPhrase(t)
          ? "I remember you're $t 🚀"
          : "I remember you're into $t 🚀";
      chips.add(phrase);
    }
    for (final p in preferences) {
      final t = p.trim();
      if (t.isEmpty) continue;
      final normalized = _normalizePreferenceDisplay(t);
      final phrase = normalized.startsWith('like ')
          ? "I remember you $normalized"
          : "I remember you prefer $normalized";
      chips.add(phrase);
    }
    return chips;
  }

  static final _goalVerbPrefixes = [
    'learning ', 'mastering ', 'building ', 'studying ', 'working on ',
    'exploring ', 'getting into ', 'practicing ', 'improving at ',
  ];

  static bool _goalReadsAsVerbPhrase(String goal) {
    final lower = goal.toLowerCase();
    return _goalVerbPrefixes.any((prefix) => lower.startsWith(prefix));
  }

  static String _normalizeGoalDisplay(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('Masterting', 'Mastering')
        .replaceAll('masterting', 'mastering');
  }

  static String _normalizePreferenceDisplay(String s) {
    if (s.isEmpty) return s;
    final lower = s.toLowerCase();
    if (lower.startsWith('likes ')) return 'like ${lower.substring(6)}';
    if (lower.startsWith('prefer ')) return lower;
    if (lower.startsWith('prefers ')) return 'prefer ${lower.substring(8)}';
    if (lower.startsWith('like ')) return lower;
    return lower;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'goals': goals,
        'preferences': preferences,
      };

  static UserMemory fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserMemory();
    return UserMemory(
      name: json['name'] as String?,
      goals: (json['goals'] as List<dynamic>?)?.cast<String>() ?? [],
      preferences: (json['preferences'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  static UserMemory fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return const UserMemory();
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>?);
    } catch (_) {
      return const UserMemory();
    }
  }

  String toJsonString() => jsonEncode(toJson());
}
