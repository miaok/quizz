import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../models/question_model.dart';
import '../models/blind_taste_model.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 初始化搜索数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).initialize();
    });

    // 监听标签页切换
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tab = _tabController.index == 0
            ? SearchTab.multipleChoice
            : SearchTab.blindTaste;

        // 切换标签页时清空搜索框
        _searchController.clear();
        ref.read(searchProvider.notifier).switchTab(tab);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final searchStatsAsync = ref.watch(searchStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '题库搜索',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz, size: 20),
                  const SizedBox(width: 8),
                  Text('选择题题库', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wine_bar, size: 20),
                  const SizedBox(width: 8),
                  Text('品鉴题库', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 搜索栏
            _buildSearchBar(searchState),

            // 统计信息
            _buildStatsBar(searchStatsAsync, searchState),

            // 搜索结果
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMultipleChoiceResults(searchState),
                  _buildBlindTasteResults(searchState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(SearchState searchState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: searchState.currentTab == SearchTab.multipleChoice
              ? '搜索题目、选项'
              : '搜索酒样名称、发酵剂、设备...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchProvider.notifier).clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
        ),
        onChanged: (value) {
          ref.read(searchProvider.notifier).updateQuery(value);
        },
      ),
    );
  }

  Widget _buildStatsBar(
    AsyncValue<Map<String, int>> statsAsync,
    SearchState searchState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: statsAsync.when(
              data: (stats) {
                final totalCount =
                    searchState.currentTab == SearchTab.multipleChoice
                    ? stats['multipleChoiceCount'] ?? 0
                    : stats['blindTasteCount'] ?? 0;
                final resultCount = searchState.currentResultCount;

                return Text(
                  searchState.query.isEmpty
                      ? '共 $totalCount 条数据'
                      : '找到 $resultCount 条结果（共 $totalCount 条数据）',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
              loading: () => Text(
                '加载中...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              error: (error, _) => Text(
                '加载失败',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
          if (searchState.isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceResults(SearchState searchState) {
    if (searchState.error != null) {
      return _buildErrorWidget(searchState.error!);
    }

    if (searchState.isLoading && searchState.multipleChoiceResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.multipleChoiceResults.isEmpty) {
      return _buildEmptyWidget('没有找到相关题目');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchState.multipleChoiceResults.length,
      itemBuilder: (context, index) {
        final question = searchState.multipleChoiceResults[index];
        return _buildQuestionCard(question, index);
      },
    );
  }

  Widget _buildBlindTasteResults(SearchState searchState) {
    if (searchState.error != null) {
      return _buildErrorWidget(searchState.error!);
    }

    if (searchState.isLoading && searchState.blindTasteResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.blindTasteResults.isEmpty) {
      return _buildEmptyWidget('没有找到相关酒样');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchState.blindTasteResults.length,
      itemBuilder: (context, index) {
        final item = searchState.blindTasteResults[index];
        return _buildBlindTasteCard(item, index);
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(searchProvider.notifier).initialize();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目标题和类型
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getQuestionTypeColor(question.type),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getQuestionTypeText(question.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (question.category != '通用')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      question.category,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 题目内容
            Text(
              '${index + 1}. ${question.question}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // 选项
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              final isCorrect = _isCorrectOption(question, optionIndex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + optionIndex), // A, B, C, D
                          style: TextStyle(
                            color: isCorrect
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isCorrect
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isCorrect
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              );
            }),

            // 解析
            if (question.explanation != null &&
                question.explanation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '解析',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.explanation!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBlindTasteCard(BlindTasteItemModel item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 酒样名称
            Row(
              children: [
                Icon(
                  Icons.wine_bar,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${index + 1}. ${item.name}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 基本信息
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoItem(
                    '酒度',
                    '${item.alcoholDegree.round()}°',
                    Icons.thermostat,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfoItem(
                    '总分',
                    item.totalScore.toString(),
                    Icons.star,
                  ),
                ),
              ],
            ),

            // 设备和发酵剂信息
            if (item.equipment.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildCompactInfoItem(
                '设备',
                item.equipment.join('、'),
                Icons.build,
              ),
            ],
            if (item.fermentationAgent.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildCompactInfoItem(
                '发酵剂',
                item.fermentationAgent.join('、'),
                Icons.science,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法
  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return Colors.blue;
      case QuestionType.multiple:
        return Colors.orange;
      case QuestionType.boolean:
        return Colors.green;
    }
  }

  String _getQuestionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return '单选';
      case QuestionType.multiple:
        return '多选';
      case QuestionType.boolean:
        return '判断';
    }
  }

  bool _isCorrectOption(QuestionModel question, int optionIndex) {
    if (question.answer is String) {
      // 单选题或判断题
      return question.options[optionIndex] == question.answer;
    } else if (question.answer is List) {
      // 多选题
      final correctAnswers = question.answer as List;
      return correctAnswers.contains(question.options[optionIndex]);
    }
    return false;
  }
}
