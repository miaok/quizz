import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../providers/quiz_provider.dart';
import '../router/app_router.dart';
import '../utils/system_ui_manager.dart';

class ResultPage extends ConsumerStatefulWidget {
  const ResultPage({super.key});

  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  @override
  void initState() {
    super.initState();
    // 设置结果页面的系统UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemUIManager.setResultPageUI();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizControllerProvider);
    final quizController = ref.read(quizControllerProvider.notifier);

    if (quizState.status != QuizStatus.completed) {
      // 如果不是完成状态，返回首页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appRouter.goToHome();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final result = quizController.getResult();

    return PopScope(
      canPop: false, // 禁止直接返回
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // 系统返回手势时返回首页
          final quizController = ref.read(quizControllerProvider.notifier);
          quizController.reset();
          appRouter.goToHome();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('答题结果'),
          // 使用新的MD3主题，移除自定义背景色
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          bottom: false, // 底部不需要安全区域
          child: Column(
            children: [
              // 结果统计卡片
              _buildResultSummary(result),

              // 题目详情列表
              Expanded(child: _buildQuestionDetails(result)),

              // 底部按钮
              _buildBottomButtons(context, quizController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummary(QuizResult result) {
    final scoreColor = _getScoreColor(result.score);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 分数圆环
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        result.scoreText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        _getScoreLevel(result.score),
                        style: TextStyle(fontSize: 14, color: scoreColor),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 统计信息 - 使用两行布局
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '总题数',
                        '${result.totalQuestions}',
                        Colors.blue,
                      ),
                      _buildStatItem(
                        '正确',
                        '${result.correctAnswers}',
                        Colors.green,
                      ),
                      _buildStatItem(
                        '错误',
                        '${result.totalQuestions - result.correctAnswers}',
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(
                        '答题用时',
                        result.totalTimeText,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                '完成时间: ${_formatDateTime(result.completedAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildQuestionDetails(QuizResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '题目详情',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: result.questionResults.length,
              itemBuilder: (context, index) {
                final questionResult = result.questionResults[index];
                return _buildQuestionResultCard(index + 1, questionResult);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResultCard(int questionNumber, QuestionResult result) {
    final isCorrect = result.isCorrect;
    final statusColor = isCorrect ? Colors.green : Colors.red;
    final statusIcon = isCorrect ? Icons.check_circle : Icons.cancel;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          '第 $questionNumber 题',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isCorrect ? '回答正确' : '回答错误',
          style: TextStyle(color: statusColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 题目
                Text(
                  result.question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // 用户答案
                _buildAnswerRow(
                  '您的答案',
                  result.userAnswerText,
                  isCorrect ? Colors.green : Colors.red,
                ),

                // 正确答案
                if (!isCorrect)
                  _buildAnswerRow(
                    '正确答案',
                    result.question.getCorrectAnswerText(),
                    Colors.green,
                  ),

                // 解析
                if (result.question.explanation != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '解析',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(result.question.explanation!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(String label, String answer, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              answer,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, QuizController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                controller.reset();
                appRouter.goToHome();
              },
              child: const Text('返回首页'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                controller.reset();
                appRouter.goToHome();
              },
              child: const Text('再次答题'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLevel(double score) {
    if (score >= 90) return '优秀';
    if (score >= 80) return '良好';
    if (score >= 60) return '及格';
    return '不及格';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
