import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score_record_model.dart';
import '../services/score_record_service.dart';
import '../router/app_router.dart';

/// 得分记录页面Provider
final scoreRecordsProvider = FutureProvider<List<ScoreRecord>>((ref) async {
  final service = ScoreRecordService();
  return await service.loadScoreRecords();
});

/// 得分记录统计Provider
final scoreStatisticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ScoreRecordService();
  return await service.getStatistics();
});

class ScoreRecordsPage extends ConsumerStatefulWidget {
  const ScoreRecordsPage({super.key});

  @override
  ConsumerState<ScoreRecordsPage> createState() => _ScoreRecordsPageState();
}

class _ScoreRecordsPageState extends ConsumerState<ScoreRecordsPage> {
  final ScoreRecordService _scoreRecordService = ScoreRecordService();

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(scoreRecordsProvider);
    final statisticsAsync = ref.watch(scoreStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('理论模拟记录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appRouter.goToHome(),
        ),
        actions: [
          // 清空所有记录按钮
          recordsAsync.when(
            data: (records) => records.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () => _showClearAllDialog(),
                    tooltip: '清空所有记录',
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(scoreRecordsProvider);
          ref.invalidate(scoreStatisticsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // 统计信息
            SliverToBoxAdapter(child: _buildStatisticsSection(statisticsAsync)),
            // 记录列表
            SliverToBoxAdapter(child: _buildRecordsSection(recordsAsync)),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息区域
  Widget _buildStatisticsSection(
    AsyncValue<Map<String, dynamic>> statisticsAsync,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '统计概览',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              statisticsAsync.when(
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '考试次数',
                            '${stats['count']}',
                            Icons.quiz,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            '平均分',
                            '${stats['averageScore'].toStringAsFixed(1)}分',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '最高分',
                            '${stats['highestScore'].toStringAsFixed(1)}分',
                            Icons.star,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            '最近分',
                            '${stats['latestScore'].toStringAsFixed(1)}分',
                            Icons.schedule,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => const Text('加载统计信息失败'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// 构建记录列表区域
  Widget _buildRecordsSection(AsyncValue<List<ScoreRecord>> recordsAsync) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Card(
        elevation: 3,
        shadowColor: Colors.blue.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.05),
                    Colors.blue.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Text(
                '考试记录',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            recordsAsync.when(
              data: (records) => records.isEmpty
                  ? _buildEmptyState()
                  : _buildRecordsTable(records),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('加载记录失败: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无考试记录',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '完成理论模拟后，记录将在这里显示',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建记录表格
  Widget _buildRecordsTable(List<ScoreRecord> records) {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columnSpacing: 0,
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 48,
        columns: [
          DataColumn(
            label: Expanded(
              flex: 2,
              child: Text(
                '考试时间',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              flex: 1,
              child: Text(
                '得分',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              flex: 1,
              child: Text(
                '用时',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        rows: records.map((record) => _buildDataRow(record)).toList(),
      ),
    );
  }

  /// 构建数据行
  DataRow _buildDataRow(ScoreRecord record) {
    final scoreColor = _getScoreColor(record.score);

    return DataRow(
      cells: [
        DataCell(
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  record.examTimeText.split(' ')[0],
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  record.examTimeText.split(' ')[1],
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                record.scoreText,
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              record.durationText,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// 获取得分颜色
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  // 显示清空所有记录确认对话框
  Future<void> _showClearAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有记录'),
        content: const Text('确定要清空所有理论模拟记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _scoreRecordService.clearScoreRecords();
        ref.invalidate(scoreRecordsProvider);
        ref.invalidate(scoreStatisticsProvider);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('所有记录已清空')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('清空失败: $e')));
        }
      }
    }
  }
}
