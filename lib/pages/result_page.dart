import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../models/score_record_model.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../router/app_router.dart';
import '../services/score_record_service.dart';

class ResultPage extends ConsumerStatefulWidget {
  const ResultPage({super.key});

  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  bool _isRetrying = false; // 标志是否正在重新答题
  bool _showOnlyWrongAnswers = false; // 是否只显示错题
  final ScoreRecordService _scoreRecordService = ScoreRecordService();
  bool _hasRecordSaved = false; // 防止重复保存记录

  @override
  void initState() {
    super.initState();
    _saveScoreRecordIfNeeded();
  }

  /// 如果是理论模拟，保存得分记录
  Future<void> _saveScoreRecordIfNeeded() async {
    if (_hasRecordSaved) return;

    final quizState = ref.read(quizControllerProvider);
    final quizController = ref.read(quizControllerProvider.notifier);

    // 只在理论模拟（考试模式）完成时保存记录
    if (quizState.status == QuizStatus.completed &&
        quizState.mode == QuizMode.exam) {
      try {
        final result = quizController.getResult();
        final settings = ref.read(settingsProvider);

        // 创建得分记录
        final scoreRecord = ScoreRecord.fromQuizResult(
          result: result,
          singleChoiceCount: settings.singleChoiceCount,
          multipleChoiceCount: settings.multipleChoiceCount,
          booleanCount: settings.booleanCount,
        );

        // 保存记录
        await _scoreRecordService.saveScoreRecord(scoreRecord);
        _hasRecordSaved = true;

        debugPrint(
          '理论模拟得分记录已保存: ${scoreRecord.scoreText} (${scoreRecord.examTimeText})',
        );
      } catch (e) {
        debugPrint('保存得分记录失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizControllerProvider);
    final quizController = ref.read(quizControllerProvider.notifier);

    if (quizState.status != QuizStatus.completed && !_isRetrying) {
      // 如果不是完成状态且不是在重新答题，返回首页
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 减小垂直边距
      child: Card(
        elevation: 2, // 减小阴影
        child: Padding(
          padding: const EdgeInsets.all(12), // 减小内边距
          child: Row(
            // 改为水平布局，更紧凑
            children: [
              // 分数圆环 - 大幅减小
              Container(
                width: 50, // 从80减小到50
                height: 50, // 从80减小到50
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 4), // 减小边框宽度
                ),
                child: Center(
                  child: Text(
                    result.scoreText,
                    style: TextStyle(
                      fontSize: 14, // 从20减小到14
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 统计信息 - 紧凑布局
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildCompactStatItem(
                          '总题数',
                          '${result.totalQuestions}',
                          Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        _buildCompactStatItem(
                          '正确',
                          '${result.correctAnswers}',
                          Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _buildCompactStatItem(
                          '错误',
                          '${result.totalQuestions - result.correctAnswers}',
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCompactStatItem(
                      '答题用时',
                      result.totalTimeText,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Widget _buildStatItem(String label, String value, Color color) {
  //   return Column(
  //     children: [
  //       Text(
  //         value,
  //         style: TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.bold,
  //           color: color,
  //         ),
  //       ),
  //       Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
  //     ],
  //   );
  // }

  Widget _buildQuestionDetails(QuizResult result) {
    // 根据筛选条件过滤题目
    final filteredResults = _showOnlyWrongAnswers
        ? result.questionResults.where((q) => !q.isCorrect).toList()
        : result.questionResults;

    final wrongAnswersCount = result.questionResults
        .where((q) => !q.isCorrect)
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和筛选按钮 - 减小间距
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4), // 从8减小到4
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '题目详情',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ), // 从18减小到16
                ),
                // 筛选按钮 - 稍微减小
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), // 从20减小到16
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterButton(
                        '全部 (${result.questionResults.length})',
                        !_showOnlyWrongAnswers,
                        () => setState(() => _showOnlyWrongAnswers = false),
                      ),
                      _buildFilterButton(
                        '错题 ($wrongAnswersCount)',
                        _showOnlyWrongAnswers,
                        wrongAnswersCount > 0
                            ? () => setState(() => _showOnlyWrongAnswers = true)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 题目列表 - 现在占用更多空间
          Expanded(
            child: filteredResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 56, // 从64减小到56
                          color: Colors.green[300],
                        ),
                        const SizedBox(height: 12), // 从16减小到12
                        Text(
                          '恭喜！没有错题',
                          style: TextStyle(
                            fontSize: 16, // 从18减小到16
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8), // 添加底部padding
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final questionResult = filteredResults[index];
                      // 找到原始题目编号
                      final originalIndex =
                          result.questionResults.indexOf(questionResult) + 1;
                      return _buildQuestionResultCard(
                        originalIndex,
                        questionResult,
                      );
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
      margin: const EdgeInsets.only(bottom: 6), // 从8减小到6
      elevation: 1, // 减小阴影
      child: ExpansionTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          '第 $questionNumber 题',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          isCorrect ? '✓ 回答正确' : '✗ 回答错误',
          style: TextStyle(
            color: statusColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ), // 减小padding
        childrenPadding: EdgeInsets.zero, // 移除children的默认padding
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 自定义margin
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 题目
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    result.question.question,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
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
                  const SizedBox(height: 12),
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
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '解析',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.question.explanation!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.blue[800],
                          ),
                        ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              answer,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ), // 减小padding
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : onTap != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12, // 从14减小到12
          ),
        ),
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
              onPressed: () => _retryQuiz(context, controller),
              child: const Text('再次模拟'),
            ),
          ),
        ],
      ),
    );
  }

  // 重新开始答题 - 设置标志避免状态检查干扰
  void _retryQuiz(BuildContext context, QuizController controller) async {
    final settings = ref.read(settingsProvider);
    final quizState = ref.read(quizControllerProvider);
    final currentMode = quizState.mode;

    // 设置重新答题标志，避免状态检查干扰
    setState(() {
      _isRetrying = true;
    });

    try {
      // 清除当前模式的保存进度（不影响其他模式）
      await controller.clearSavedProgress(currentMode);

      // 重置当前控制器状态
      controller.reset();

      // 根据之前的模式重新开始答题
      if (currentMode == QuizMode.practice) {
        // 练习模式：开始全题库答题
        await controller.startAllQuestionsQuiz(
          shuffleOptions: settings.shuffleOptions,
          shuffleMode: settings.practiceShuffleMode,
        );
      } else {
        // 考试模式：使用设置中的配置开始模拟考试
        await controller.startQuizWithSettings(
          singleCount: settings.singleChoiceCount,
          multipleCount: settings.multipleChoiceCount,
          booleanCount: settings.booleanCount,
          shuffleOptions: settings.shuffleOptions,
        );
      }

      // 导航到答题页面
      if (context.mounted) {
        appRouter.goToQuiz();
      }
    } catch (e) {
      // 出错时回到首页
      setState(() {
        _isRetrying = false;
      });
      if (context.mounted) {
        appRouter.goToHome();
      }
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  // String _getScoreLevel(double score) {
  //   if (score >= 90) return '优秀';
  //   if (score >= 80) return '良好';
  //   if (score >= 60) return '及格';
  //   return '不及格';
  // }

  // String _formatDateTime(DateTime dateTime) {
  //   return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
  //       '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  // }
}
