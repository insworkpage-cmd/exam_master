import 'dart:async';
import 'package:flutter/material.dart';
import '../core/question_model.dart';

class QuizProvider with ChangeNotifier {
  List<Question> _questions = [];
  int _currentIndex = 0;
  List<String> _shuffledAnswers = [];
  String? _selectedAnswer;
  bool _answered = false;
  List<int> _questionTimers = [];
  int _currentQuestionTime = 30;
  Timer? _questionTimer;
  Timer? _totalTimer;
  int _totalElapsedSeconds = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _unansweredCount = 0;
  final Map<int, String> _userAnswers = {};
  final Map<int, bool> _hasAnswered = {};

  QuizProvider() {
    _loadQuestions();
  }

  List<Question> get questions => _questions;
  int get currentIndex => _currentIndex;
  List<String> get shuffledAnswers => _shuffledAnswers;
  String? get selectedAnswer => _selectedAnswer;
  bool get answered => _answered;
  int get currentQuestionTime => _currentQuestionTime;
  int get totalElapsedSeconds => _totalElapsedSeconds;
  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  int get unansweredCount => _unansweredCount;
  Question get currentQuestion => _questions[_currentIndex];

  void _loadQuestions() {
    _questions = [
      Question(
        id: '1',
        text: 'حاصل ضرب ۳ در ۴ چند است؟',
        options: ['۸', '۱۲', '۱۰', '۱۴'],
        correctAnswerIndex: 1,
        source: 'کتاب ریاضی پایه پنجم',
      ),
      Question(
        id: '2',
        text: 'کدام گزینه عدد اول است؟',
        options: ['۹', '۱۵', '۱۷', '۲۱'],
        correctAnswerIndex: 2,
        source: 'مفاهیم پایه ریاضی',
      ),
      Question(
        id: '3',
        text: 'کدام یک ماه فصل تابستان نیست؟',
        options: ['مرداد', 'شهریور', 'آذر', 'تیر'],
        correctAnswerIndex: 2,
        source: 'تقویم رسمی کشور',
      ),
    ];

    _shuffledAnswers = List<String>.from(_questions[_currentIndex].options)
      ..shuffle();
    _questionTimers = List.filled(_questions.length, 30);
    startQuestionTimer();
    startTotalTimer();
  }

  void startQuestionTimer() {
    stopQuestionTimer();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!answered) {
        if (_currentQuestionTime > 0) {
          _currentQuestionTime--;
          _questionTimers[_currentIndex] = _currentQuestionTime;
          notifyListeners();
        } else {
          _unansweredCount++;
          _answered = true;
          _hasAnswered[_currentIndex] = false;
          timer.cancel();
          notifyListeners();
        }
      }
    });
  }

  void stopQuestionTimer() => _questionTimer?.cancel();

  void startTotalTimer() {
    _totalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _totalElapsedSeconds++;
      notifyListeners();
    });
  }

  void stopTimers() {
    stopQuestionTimer();
    _totalTimer?.cancel();
  }

  void selectAnswer(String answer) {
    if (answered) return;
    stopQuestionTimer();
    _selectedAnswer = answer;
    _answered = true;
    _userAnswers[_currentIndex] = answer;
    _hasAnswered[_currentIndex] = true;
    if (answer ==
        _questions[_currentIndex]
            .options[_questions[_currentIndex].correctAnswerIndex]) {
      _correctCount++;
    } else {
      _wrongCount++;
    }
    notifyListeners();
  }

  void goToQuestion(int index) {
    _currentIndex = index;
    _selectedAnswer = _userAnswers[index];
    _answered = _hasAnswered[index] == true;
    _currentQuestionTime = _questionTimers[index];
    _shuffledAnswers = List<String>.from(_questions[_currentIndex].options)
      ..shuffle();
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _selectedAnswer = _userAnswers[_currentIndex];
      _answered = _hasAnswered[_currentIndex] == true;
      _currentQuestionTime = _questionTimers[_currentIndex];
      _shuffledAnswers = List<String>.from(_questions[_currentIndex].options)
        ..shuffle();
      if (!answered) startQuestionTimer();
      notifyListeners();
    }
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color getOptionColor(String answer) {
    if (!answered) return Colors.white;
    final correct = _questions[_currentIndex]
        .options[_questions[_currentIndex].correctAnswerIndex];
    if (answer == correct) return Colors.green;
    if (answer == _selectedAnswer) return Colors.red;
    return Colors.white;
  }

  Color getTextColor(String answer) {
    if (!answered) return Colors.black;
    final correct = _questions[_currentIndex]
        .options[_questions[_currentIndex].correctAnswerIndex];
    if (answer == correct || answer == _selectedAnswer) {
      return Colors.white;
    }
    return Colors.black;
  }

  bool hasAnswered(int index) => _hasAnswered[index] == true;
  bool isCorrect(int index) =>
      _userAnswers[index] ==
      _questions[index].options[_questions[index].correctAnswerIndex];
}
