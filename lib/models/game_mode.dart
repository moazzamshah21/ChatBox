/// Game modes that change the AI's system prompt for play.
enum GameMode {
  twentyQuestions,
  guessTheWord,
  wouldYouRather;

  String get displayName {
    switch (this) {
      case GameMode.twentyQuestions:
        return '20 Questions';
      case GameMode.guessTheWord:
        return 'Guess the word';
      case GameMode.wouldYouRather:
        return 'Would You Rather';
    }
  }

  String get systemPrompt {
    switch (this) {
      case GameMode.twentyQuestions:
        return "You are playing 20 Questions. The USER is thinking of something (person, place, or thing). "
            "You must ask only YES/NO questions to guess it. Count your questions (e.g. 'Question 1: ...'). "
            "After 20 questions, make your guess. Be concise and playful.";
      case GameMode.guessTheWord:
        return "You are playing Guess the Word. YOU think of a common word (noun, verb, or thing) and give a short hint (e.g. category or one clue). "
            "The user will try to guess. Reply only with 'Yes!' if they get it, or give a brief next hint if wrong. "
            "Start the game by saying you've chosen a word and give the first hint.";
      case GameMode.wouldYouRather:
        return "You are playing Would You Rather. Present two fun or thought-provoking options (A and B). "
            "After the user picks one, briefly react and give the next pair. Keep it light and engaging.";
    }
  }

  String get subtitle {
    switch (this) {
      case GameMode.twentyQuestions:
        return 'Think of something, AI asks yes/no questions';
      case GameMode.guessTheWord:
        return 'AI picks a word, you guess from hints';
      case GameMode.wouldYouRather:
        return 'Pick between two options';
    }
  }
}
