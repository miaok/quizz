import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../models/blind_taste_model.dart';
import '../services/database_service.dart';
import '../services/blind_taste_service.dart';

/// 搜索状态枚举
enum SearchTab {
  multipleChoice, // 选择题
  blindTaste,     // 品鉴题
}

/// 搜索状态模型
class SearchState {
  final SearchTab currentTab;
  final String query;
  final bool isLoading;
  final List<QuestionModel> multipleChoiceResults;
  final List<BlindTasteItemModel> blindTasteResults;
  final String? error;

  const SearchState({
    this.currentTab = SearchTab.multipleChoice,
    this.query = '',
    this.isLoading = false,
    this.multipleChoiceResults = const [],
    this.blindTasteResults = const [],
    this.error,
  });

  SearchState copyWith({
    SearchTab? currentTab,
    String? query,
    bool? isLoading,
    List<QuestionModel>? multipleChoiceResults,
    List<BlindTasteItemModel>? blindTasteResults,
    String? error,
  }) {
    return SearchState(
      currentTab: currentTab ?? this.currentTab,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      multipleChoiceResults: multipleChoiceResults ?? this.multipleChoiceResults,
      blindTasteResults: blindTasteResults ?? this.blindTasteResults,
      error: error,
    );
  }

  /// 获取当前标签页的结果数量
  int get currentResultCount {
    switch (currentTab) {
      case SearchTab.multipleChoice:
        return multipleChoiceResults.length;
      case SearchTab.blindTaste:
        return blindTasteResults.length;
    }
  }
}

/// 搜索状态管理器
class SearchNotifier extends StateNotifier<SearchState> {
  final DatabaseService _databaseService;
  final BlindTasteService _blindTasteService;

  SearchNotifier(this._databaseService, this._blindTasteService)
      : super(const SearchState());

  /// 切换标签页
  void switchTab(SearchTab tab) {
    if (state.currentTab != tab) {
      state = state.copyWith(currentTab: tab);
      // 如果有搜索查询，重新搜索
      if (state.query.isNotEmpty) {
        _performSearch(state.query);
      }
    }
  }

  /// 更新搜索查询
  void updateQuery(String query) {
    state = state.copyWith(query: query, error: null);
    _performSearch(query);
  }

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      // 空查询时显示所有数据
      await _loadAllData();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      switch (state.currentTab) {
        case SearchTab.multipleChoice:
          final results = await _databaseService.searchQuestions(query);
          state = state.copyWith(
            isLoading: false,
            multipleChoiceResults: results,
          );
          break;
        case SearchTab.blindTaste:
          final results = await _blindTasteService.searchItems(query);
          state = state.copyWith(
            isLoading: false,
            blindTasteResults: results,
          );
          break;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '搜索失败: ${e.toString()}',
      );
    }
  }

  /// 加载所有数据（用于空查询时显示）
  Future<void> _loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      switch (state.currentTab) {
        case SearchTab.multipleChoice:
          final results = await _databaseService.getAllQuestions();
          state = state.copyWith(
            isLoading: false,
            multipleChoiceResults: results,
          );
          break;
        case SearchTab.blindTaste:
          final results = await _blindTasteService.getAllItems();
          state = state.copyWith(
            isLoading: false,
            blindTasteResults: results,
          );
          break;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载数据失败: ${e.toString()}',
      );
    }
  }

  /// 初始化搜索（加载初始数据）
  Future<void> initialize() async {
    await _loadAllData();
  }

  /// 清空搜索
  void clearSearch() {
    state = state.copyWith(query: '');
    _loadAllData();
  }
}

/// 搜索Provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final databaseService = DatabaseService();
  final blindTasteService = BlindTasteService();
  return SearchNotifier(databaseService, blindTasteService);
});

/// 搜索统计Provider
final searchStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final databaseService = DatabaseService();
  final blindTasteService = BlindTasteService();

  final questionCount = await databaseService.getQuestionCount();
  final blindTasteCount = await blindTasteService.getItemCount();

  return {
    'multipleChoiceCount': questionCount,
    'blindTasteCount': blindTasteCount,
  };
});
