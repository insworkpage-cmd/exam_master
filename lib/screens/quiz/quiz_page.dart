import 'dart:async';
import 'package:flutter/material.dart';
import 'quiz_result.dart'; // اضافه شده برای هدایت درست

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'حاصل ضرب ۳ در ۴ چند است؟',
      'correctAnswer': '۱۲',
      'allAnswers': ['۸', '۱۲', '۱۰', '۱۴'],
      'source': 'کتاب ریاضی پایه پنجم'
    },
    {
      'question': 'کدام گزینه عدد اول است؟',
      'correctAnswer': '۱۷',
      'allAnswers': ['۹', '۱۵', '۱۷', '۲۱'],
      'source': 'مفاهیم پایه ریاضی'
    },
    {
      'question': 'کدام یک ماه فصل تابستان نیست؟',
      'correctAnswer': 'آذر',
      'allAnswers': ['مرداد', 'شهریور', 'آذر', 'تیر'],
      'source': 'تقویم رسمی کشور'
    },
  ];

  int currentIndex = 0;
  List<String> shuffledAnswers = [];
  String? selectedAnswer;
  bool answered = false;

  List<int> questionTimers = [];
  int currentQuestionTime = 30;
  Timer? questionTimer;
  Timer? totalTimer;
  int totalElapsedSeconds = 0;

  int correctCount = 0;
  int wrongCount = 0;
  int unansweredCount = 0;

  final Map<int, String> userAnswers = {};
  final Map<int, bool> hasAnswered = {};

  @override
  void initState() {
    super.initState();
    shuffledAnswers = List<String>.from(questions[currentIndex]['allAnswers'])
      ..shuffle();
    questionTimers = List.filled(questions.length, 30);
    startQuestionTimer();
    startTotalTimer();
  }

  void startQuestionTimer() {
    stopQuestionTimer();
    questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!answered) {
        if (currentQuestionTime > 0) {
          setState(() {
            currentQuestionTime--;
            questionTimers[currentIndex] = currentQuestionTime;
          });
        } else {
          setState(() {
            unansweredCount++;
            answered = true;
            hasAnswered[currentIndex] = false;
          });
          timer.cancel();
        }
      }
    });
  }

  void stopQuestionTimer() => questionTimer?.cancel();

  void startTotalTimer() {
    totalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => totalElapsedSeconds++);
    });
  }

  void stopTotalTimer() => totalTimer?.cancel();

  void selectAnswer(String answer) {
    if (answered) return;
    stopQuestionTimer();

    setState(() {
      selectedAnswer = answer;
      answered = true;
      userAnswers[currentIndex] = answer;
      hasAnswered[currentIndex] = true;

      if (answer == questions[currentIndex]['correctAnswer']) {
        correctCount++;
      } else {
        wrongCount++;
      }
    });
  }

  void goToQuestion(int index) {
    setState(() {
      currentIndex = index;
      selectedAnswer = userAnswers[index];
      answered = hasAnswered[index] == true;
      currentQuestionTime = questionTimers[index];
      shuffledAnswers = List<String>.from(questions[currentIndex]['allAnswers'])
        ..shuffle();
    });
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color getOptionColor(String answer, int index) {
    if (!answered) return Colors.white;
    final correct = questions[index]['correctAnswer'];
    if (answer == correct) return Colors.green;
    if (answer == userAnswers[index]) return Colors.red;
    return Colors.white;
  }

  Color getTextColor(String answer, int index) {
    if (!answered) return Colors.black;
    final correct = questions[index]['correctAnswer'];
    if (answer == correct || answer == userAnswers[index]) {
      return Colors.white;
    }
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('آزمون استخدامی'),
          backgroundColor: const Color(0xFF00ACC1),
        ),
        body: Row(
          children: [
            // ستون شماره سوالات
            Container(
              width: 70,
              color: const Color(0xFFE0F7FA),
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  Color bgColor;
                  if (!hasAnswered.containsKey(index)) {
                    bgColor = Colors.amber;
                  } else if (userAnswers[index] ==
                      questions[index]['correctAnswer']) {
                    bgColor = Colors.green;
                  } else {
                    bgColor = Colors.red;
                  }

                  return GestureDetector(
                    onTap: () => goToQuestion(index),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // بخش اصلی آزمون
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '🕒 زمان سؤال: ${formatTime(currentQuestionTime)}'),
                        Text('⏱ زمان کل: ${formatTime(totalElapsedSeconds)}'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // متن سوال
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 3)
                        ],
                      ),
                      child: Text(
                        questions[currentIndex]['question'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // گزینه‌ها
                    ...shuffledAnswers.map((answer) {
                      return GestureDetector(
                        onTap: () => selectAnswer(answer),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: getOptionColor(answer, currentIndex),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                answered
                                    ? (answer ==
                                            questions[currentIndex]
                                                ['correctAnswer']
                                        ? Icons.check
                                        : answer == selectedAnswer
                                            ? Icons.clear
                                            : Icons.radio_button_unchecked)
                                    : Icons.radio_button_unchecked,
                                color: getTextColor(answer, currentIndex),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                answer,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: getTextColor(answer, currentIndex),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    // 📘 منبع زیر گزینه‌ها
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, right: 4.0),
                      child: Text(
                        '📘 منبع: ${questions[currentIndex]['source']}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // گزارش خطا
                    if (answered)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('گزارش شما ثبت شد.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.report_problem_outlined),
                          label: const Text('گزارش خطا در سوال یا گزینه'),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // آمار رنگی و دکمه سوال بعدی
                    if (answered)
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: currentIndex < questions.length - 1
                                ? () {
                                    setState(() {
                                      currentIndex++;
                                      selectedAnswer =
                                          userAnswers[currentIndex];
                                      answered =
                                          hasAnswered[currentIndex] == true;
                                      currentQuestionTime =
                                          questionTimers[currentIndex];
                                      shuffledAnswers = List<String>.from(
                                          questions[currentIndex]['allAnswers'])
                                        ..shuffle();
                                    });
                                    if (!answered) startQuestionTimer();
                                  }
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('سؤال بعد'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: const Color(0xFF00ACC1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black12),
                              color: Colors.teal.shade50,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('✅ صحیح: $correctCount',
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                                Text('❌ غلط: $wrongCount',
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '⏳ بی‌پاسخ: ${questions.length - (correctCount + wrongCount)}',
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // دکمه پایان آزمون → هدایت به quiz_result.dart
                    if (currentIndex == questions.length - 1 && answered)
                      ElevatedButton.icon(
                        onPressed: () {
                          stopQuestionTimer();
                          stopTotalTimer();

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => QuizResultPage(
                                correct: correctCount,
                                wrong: wrongCount,
                                unanswered: unansweredCount,
                                totalTimeSeconds: totalElapsedSeconds,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.done_all),
                        label: const Text('پایان آزمون'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    stopQuestionTimer();
    stopTotalTimer();
    super.dispose();
  }
}
