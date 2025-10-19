import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizSettings {
  final int questionsPerQuiz;
  final int activeHoursStart;
  final int activeHoursEnd;
  final List<int> activeDays;
  final bool notificationsEnabled;

  QuizSettings({
    this.questionsPerQuiz = 5,
    this.activeHoursStart = 9,
    this.activeHoursEnd = 21,
    this.activeDays = const [1, 2, 3, 4, 5], // Mon-Fri
    this.notificationsEnabled = true,
  });
}

class QuizSettingsNotifier extends StateNotifier<QuizSettings> {
  QuizSettingsNotifier() : super(QuizSettings());

  void updateQuestionsPerQuiz(int count) {
    state = QuizSettings(
      questionsPerQuiz: count,
      activeHoursStart: state.activeHoursStart,
      activeHoursEnd: state.activeHoursEnd,
      activeDays: state.activeDays,
      notificationsEnabled: state.notificationsEnabled,
    );
  }

  void updateActiveHours(int start, int end) {
    state = QuizSettings(
      questionsPerQuiz: state.questionsPerQuiz,
      activeHoursStart: start,
      activeHoursEnd: end,
      activeDays: state.activeDays,
      notificationsEnabled: state.notificationsEnabled,
    );
  }

  void updateActiveDays(List<int> days) {
    state = QuizSettings(
      questionsPerQuiz: state.questionsPerQuiz,
      activeHoursStart: state.activeHoursStart,
      activeHoursEnd: state.activeHoursEnd,
      activeDays: days,
      notificationsEnabled: state.notificationsEnabled,
    );
  }

  void toggleNotifications(bool enabled) {
    state = QuizSettings(
      questionsPerQuiz: state.questionsPerQuiz,
      activeHoursStart: state.activeHoursStart,
      activeHoursEnd: state.activeHoursEnd,
      activeDays: state.activeDays,
      notificationsEnabled: enabled,
    );
  }

  Future<void> updateSettings(QuizSettings settings) async {
    state = settings;
  }
}

final quizSettingsProvider = StateNotifierProvider<QuizSettingsNotifier, QuizSettings>((ref) {
  return QuizSettingsNotifier();
});
