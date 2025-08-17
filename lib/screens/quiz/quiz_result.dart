import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'quiz_page.dart';

class QuizResultPage extends StatelessWidget {
  final int correct;
  final int wrong;
  final int unanswered;
  final int totalTimeSeconds;

  const QuizResultPage({
    super.key,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.totalTimeSeconds,
  });

  int get total => correct + wrong + unanswered;

  double get score {
    if (total == 0) return 0;
    double accuracy = correct / total;
    double timeFactor = 1 - (totalTimeSeconds / (total * 30)).clamp(0.0, 1.0);
    return ((accuracy * 0.7 + timeFactor * 0.3) * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final scoreFormatted = score.toStringAsFixed(1);
    final correctPercent = ((correct / total) * 100).toStringAsFixed(0);
    final wrongPercent = ((wrong / total) * 100).toStringAsFixed(0);
    final unansweredPercent = ((unanswered / total) * 100).toStringAsFixed(0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('نتیجه آزمون'),
          backgroundColor: Colors.teal,
        ),
        body: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // دایره نمره کلی
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 12,
                      valueColor: AlwaysStoppedAnimation(Colors.teal.shade600),
                      backgroundColor: Colors.teal.shade100,
                    ),
                  ),
                  Text(
                    scoreFormatted,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // آمار پاسخ‌ها
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black12)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('✅ صحیح', correct, correctPercent, Colors.green),
                    _buildStat('❌ غلط', wrong, wrongPercent, Colors.red),
                    _buildStat('⏳ بی‌پاسخ', unanswered, unansweredPercent,
                        Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // نمودار
              Expanded(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: [
                      PieChartSectionData(
                        value: correct.toDouble(),
                        title: '$correct\nصحیح',
                        color: Colors.green,
                        radius: 60,
                        titleStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      PieChartSectionData(
                        value: wrong.toDouble(),
                        title: '$wrong\nغلط',
                        color: Colors.red,
                        radius: 60,
                        titleStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      PieChartSectionData(
                        value: unanswered.toDouble(),
                        title: '$unanswered\nبی‌پاسخ',
                        color: Colors.grey,
                        radius: 60,
                        titleStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // زمان آزمون
              Text(
                '🕒 زمان صرف‌شده: ${_formatTime(totalTimeSeconds)}',
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              // دکمه‌ها
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.home),
                    label: const Text('بازگشت به خانه'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const QuizPage()),
                      );
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('شروع مجدد آزمون'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value, String percent, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text('$percent٪',
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
