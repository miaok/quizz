import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/question_model.dart';
import '../models/blind_taste_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late AppDatabase _database;
  bool _isInitialized = false;

  AppDatabase get database {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database;
  }

  // 初始化数据库
  Future<void> initialize() async {
    if (_isInitialized) return;

    _database = AppDatabase();
    await _loadQuestionsFromAssets();
    await _loadBlindTasteDataFromAssets();
    _isInitialized = true;
  }

  // 从assets加载题目数据
  Future<void> _loadQuestionsFromAssets() async {
    try {
      // 检查数据库是否已有数据
      final existingCount = await _database.getQuestionCount();
      if (existingCount > 0) {
        return;
      }

      // 读取JSON文件
      final String jsonString = await rootBundle.loadString(
        'assets/questions.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      // 解析JSON数据为QuestionModel
      final List<QuestionModel> questions = jsonData
          .map((json) => QuestionModel.fromJson(json))
          .toList();

      // 转换为数据库格式并插入
      final List<QuestionsCompanion> dbQuestions = questions
          .map((q) => _questionModelToCompanion(q))
          .toList();

      await _database.insertQuestions(dbQuestions);
    } catch (e) {
      rethrow;
    }
  }

  // 从assets加载品鉴数据
  Future<void> _loadBlindTasteDataFromAssets() async {
    try {
      // 检查数据库是否已有品鉴数据
      final existingCount = await _database.getBlindTasteItemCount();
      if (existingCount > 0) {
        return;
      }

      // 读取JSON文件
      final String jsonString = await rootBundle.loadString(
        'assets/blindtaste.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      // 解析JSON数据为BlindTasteItem模型
      final List<BlindTasteItemModel> items = jsonData
          .map((json) => BlindTasteItemModel.fromJson(json))
          .toList();

      // 转换为数据库格式并插入
      final List<BlindTasteItemsCompanion> dbItems = items
          .map(
            (item) => BlindTasteItemsCompanion(
              name: Value(item.name),
              aroma: Value(item.aroma),
              alcoholDegree: Value(item.alcoholDegree),
              totalScore: Value(item.totalScore),
              equipment: Value(json.encode(item.equipment)),
              fermentationAgent: Value(json.encode(item.fermentationAgent)),
            ),
          )
          .toList();

      await _database.insertBlindTasteItems(dbItems);
    } catch (e) {
      rethrow;
    }
  }

  // 将QuestionModel转换为数据库Companion对象
  QuestionsCompanion _questionModelToCompanion(QuestionModel question) {
    return QuestionsCompanion(
      questionText: Value(question.question),
      options: Value(json.encode(question.options)),
      type: Value(question.type.name),
      correctAnswer: Value(json.encode(question.answer)),
      explanation: Value(question.explanation),
      category: Value(question.category),
    );
  }

  // 将数据库Question转换为QuestionModel
  QuestionModel questionToModel(Question dbQuestion) {
    QuestionType type;
    switch (dbQuestion.type) {
      case 'single':
        type = QuestionType.single;
        break;
      case 'multiple':
        type = QuestionType.multiple;
        break;
      case 'boolean':
        type = QuestionType.boolean;
        break;
      default:
        type = QuestionType.single;
    }

    return QuestionModel(
      question: dbQuestion.questionText,
      options: List<String>.from(json.decode(dbQuestion.options)),
      type: type,
      answer: json.decode(dbQuestion.correctAnswer),
      explanation: dbQuestion.explanation,
      category: dbQuestion.category,
    );
  }

  // 获取所有题目
  Future<List<QuestionModel>> getAllQuestions() async {
    final dbQuestions = await _database.getAllQuestions();
    return dbQuestions.map((q) => questionToModel(q)).toList();
  }

  // 根据分类获取题目
  Future<List<QuestionModel>> getQuestionsByCategory(String category) async {
    final dbQuestions = await _database.getQuestionsByCategory(category);
    return dbQuestions.map((q) => questionToModel(q)).toList();
  }

  // 随机获取题目
  Future<List<QuestionModel>> getRandomQuestions(int count) async {
    final dbQuestions = await _database.getRandomQuestions(count);
    return dbQuestions.map((q) => questionToModel(q)).toList();
  }

  // 根据分类随机获取题目
  Future<List<QuestionModel>> getRandomQuestionsByCategory(
    String category,
    int count,
  ) async {
    final dbQuestions = await _database.getRandomQuestionsByCategory(
      category,
      count,
    );
    return dbQuestions.map((q) => questionToModel(q)).toList();
  }

  // 根据题型获取题目
  Future<List<QuestionModel>> getQuestionsByType(String type, int count) async {
    final allQuestions = await getAllQuestions();
    final filteredQuestions = allQuestions
        .where((q) => q.type.name == type)
        .toList();
    filteredQuestions.shuffle();
    return filteredQuestions.take(count).toList();
  }

  // 根据设置获取混合题目（按顺序：判断题→单选题→多选题）
  Future<List<QuestionModel>> getQuestionsBySettings({
    required int singleCount,
    required int multipleCount,
    required int booleanCount,
    required bool shuffleOptions,
  }) async {
    final List<QuestionModel> result = [];

    // 按顺序获取各类型题目：判断题→单选题→多选题
    if (booleanCount > 0) {
      final booleanQuestions = await getQuestionsByType(
        'boolean',
        booleanCount,
      );
      result.addAll(booleanQuestions);
    }

    if (singleCount > 0) {
      final singleQuestions = await getQuestionsByType('single', singleCount);
      result.addAll(singleQuestions);
    }

    if (multipleCount > 0) {
      final multipleQuestions = await getQuestionsByType(
        'multiple',
        multipleCount,
      );
      result.addAll(multipleQuestions);
    }

    // 如果需要乱序选项
    if (shuffleOptions) {
      return result.map((q) => q.shuffleOptions()).toList();
    }

    return result;
  }

  // 获取所有分类
  Future<List<String>> getAllCategories() async {
    return await _database.getAllCategories();
  }

  // 获取题目总数
  Future<int> getQuestionCount() async {
    return await _database.getQuestionCount();
  }

  // 搜索题目（支持题目文本、选项、解析内容搜索）
  Future<List<QuestionModel>> searchQuestions(String query) async {
    if (query.trim().isEmpty) {
      return getAllQuestions();
    }

    final allQuestions = await getAllQuestions();
    final lowerQuery = query.toLowerCase();

    return allQuestions.where((question) {
      // 搜索题目文本
      if (question.question.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索选项
      for (final option in question.options) {
        if (option.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }

      // 搜索解析内容
      if (question.explanation != null &&
          question.explanation!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索分类
      if (question.category.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索正确答案
      if (question.answer is String) {
        if (question.answer.toString().toLowerCase().contains(lowerQuery)) {
          return true;
        }
      } else if (question.answer is List) {
        for (final answer in question.answer) {
          if (answer.toString().toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }

  // 关闭数据库
  Future<void> close() async {
    if (_isInitialized) {
      await _database.close();
      _isInitialized = false;
    }
  }
}
