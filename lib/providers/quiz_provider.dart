import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/question_model.dart';

class QuizProvider with ChangeNotifier {
  List<Question> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentQuizId = '';
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<int> _userAnswers = [];
  Map<String, dynamic> _quizResults = {};

  // گترها
  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentQuizId => _currentQuizId;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  List<int> get userAnswers => _userAnswers;
  Map<String, dynamic> get quizResults => _quizResults;

  Future<void> loadQuizQuestions(String quizId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentQuizId = quizId;
      _currentQuestionIndex = 0;
      _score = 0;
      _userAnswers = [];
    });

    try {
      // شبیه‌سازی دریافت سوالات از Firestore
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _questions = [
          Question(
            id: '1',
            text: 'مجموع زوایای مثلث قائمه‌ای چقدر است؟',
            options: ['90', '180', '270', '360'],
            correctAnswerIndex: 1,
            source: 'کتاب ریاضی',
            explanation: 'مجموع زوایای مثلث قائمه‌ای برابر با 360 درجه است',
            instructorId: 'instructor-1',
            status: 'approved',
            createdAt: DateTime.now(),
          ),
          Question(
            id: '2',
            text: 'سرعت نور در خلاء چقدر است؟',
            options: [
              '299,792 km/s',
              '300,000 km/s',
              '299,000 km/s',
              '298,792 km/s'
            ],
            correctAnswerIndex: 0,
            source: 'کتاب فیزیک',
            explanation:
                'سرعت نور در خلاء برابر با 299,792 کیلومتر بر ثانیه است',
            instructorId: 'instructor-1',
            status: 'approved',
            createdAt: DateTime.now(),
          ),
          Question(
            id: '3',
            text: 'پایتخت ایران کجاست؟',
            options: ['تهران', 'اصفهان', 'شیراز', 'مشهد'],
            correctAnswerIndex: 0,
            source: 'کتاب جغرافیا',
            explanation: 'تهران پایتخت ایران است',
            instructorId: 'instructor-1',
            status: 'approved',
            createdAt: DateTime.now(),
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> submitAnswer(int questionIndex, int answerIndex) async {
    try {
      _userAnswers.add(answerIndex);

      final question = _questions[questionIndex];
      final isCorrect = answerIndex == question.correctAnswerIndex;

      if (isCorrect) {
        _score++;
      }

      // ذخیره پاسخ کاربر در Firestore
      await FirebaseFirestore.instance
          .collection('quiz_answers')
          .doc(_currentQuizId)
          .set({
        'questionId': question.id,
        'userAnswer': answerIndex,
        'isCorrect': isCorrect,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  Future<void> finishQuiz() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // محاسبه نتیجه نهایی
      final percentage = (_score / _questions.length * 100).round();

      _quizResults = {
        'quizId': _currentQuizId,
        'score': _score,
        'totalQuestions': _questions.length,
        'percentage': percentage,
        'completedAt': DateTime.now().toIso8601String(),
        'answers': _userAnswers.asMap().entries.map((entry) {
          // ← اصلاح شد
          return {
            'questionIndex': entry.key,
            'answerIndex': entry.value,
            'questionId': _questions[entry.key].id,
          };
        }).toList(),
      };

      // ذخیره نتیجه در Firestore
      await FirebaseFirestore.instance
          .collection('quiz_results')
          .doc(_currentQuizId)
          .set(_quizResults);

      setState(() {
        _isLoading = false;
      });

      notifyListeners();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void resetQuiz() {
    _currentQuestionIndex = 0;
    _score = 0;
    _userAnswers = [];
    _quizResults = {};
    notifyListeners();
  }

  // متد کمکی برای دریافت سوال فعلی
  Question? get currentQuestion {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentQuestionIndex];
  }

  // متد کمکی برای دریافت پیشرفت آزمون
  double get progress {
    if (_questions.isEmpty) return 0.0;
    return (_currentQuestionIndex + 1) / _questions.length;
  }

  // متد کمکی برای بررسی اتمام آزمون
  bool get isQuizFinished {
    return _currentQuestionIndex >= _questions.length - 1 &&
        _userAnswers.length == _questions.length;
  }

  // متد کمکی برای دریافت وضعیت پاسخ یک سوال
  AnswerStatus getAnswerStatus(int questionIndex) {
    if (questionIndex >= _userAnswers.length) {
      return AnswerStatus.notAnswered;
    }

    final question = _questions[questionIndex];
    final userAnswer = _userAnswers[questionIndex];

    if (userAnswer == question.correctAnswerIndex) {
      return AnswerStatus.correct;
    } else {
      return AnswerStatus.incorrect;
    }
  }

  // متد کمکی برای دریافت تعداد پاسخ‌های صحیح
  int get correctAnswersCount {
    int count = 0;
    for (int i = 0; i < _userAnswers.length; i++) {
      if (i < _questions.length &&
          _userAnswers[i] == _questions[i].correctAnswerIndex) {
        count++;
      }
    }
    return count;
  }

  void setState(void Function() fn) {
    fn();
    notifyListeners();
  }
}

// enum برای وضعیت پاسخ
enum AnswerStatus {
  notAnswered,
  correct,
  incorrect,
}
