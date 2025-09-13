import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';

/// 进度保存服务
class ProgressService {
  static const String _quizProgressKey = 'quiz_progress';
  static const String _blindTasteProgressKey = 'blind_taste_progress';
  static const String _flashcardProgressKey = 'flashcard_progress';

  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 保存答题进度
  Future<void> saveQuizProgress(QuizProgress progress) async {
    await initialize();

    if (progress.type != ProgressType.quiz) {
      throw ArgumentError('Progress type must be quiz');
    }

    final jsonString = json.encode(progress.toJson());
    await _prefs!.setString(_quizProgressKey, jsonString);
    debugPrint('Quiz progress saved: ${progress.description}');
  }

  /// 保存品鉴进度
  Future<void> saveBlindTasteProgress(QuizProgress progress) async {
    await initialize();

    if (progress.type != ProgressType.blindTaste) {
      throw ArgumentError('Progress type must be blindTaste');
    }

    final jsonString = json.encode(progress.toJson());
    await _prefs!.setString(_blindTasteProgressKey, jsonString);
    debugPrint('Blind taste progress saved: ${progress.description}');
  }

  /// 加载答题进度
  Future<QuizProgress?> loadQuizProgress() async {
    await initialize();

    final jsonString = _prefs!.getString(_quizProgressKey);
    if (jsonString != null) {
      try {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final progress = QuizProgress.fromJson(jsonMap);

        if (progress.isValid) {
          debugPrint('Quiz progress loaded: ${progress.description}');
          return progress;
        } else {
          debugPrint('Invalid quiz progress found, removing...');
          await clearQuizProgress();
        }
      } catch (e) {
        debugPrint('Error loading quiz progress: $e');
        await clearQuizProgress();
      }
    }

    return null;
  }

  /// 加载品鉴进度
  Future<QuizProgress?> loadBlindTasteProgress() async {
    await initialize();

    final jsonString = _prefs!.getString(_blindTasteProgressKey);
    if (jsonString != null) {
      try {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final progress = QuizProgress.fromJson(jsonMap);

        if (progress.isValid) {
          debugPrint('Blind taste progress loaded: ${progress.description}');
          return progress;
        } else {
          debugPrint('Invalid blind taste progress found, removing...');
          await clearBlindTasteProgress();
        }
      } catch (e) {
        debugPrint('Error loading blind taste progress: $e');
        await clearBlindTasteProgress();
      }
    }

    return null;
  }

  /// 清除答题进度
  Future<void> clearQuizProgress() async {
    await initialize();
    await _prefs!.remove(_quizProgressKey);
    debugPrint('Quiz progress cleared');
  }

  /// 清除品鉴进度
  Future<void> clearBlindTasteProgress() async {
    await initialize();
    await _prefs!.remove(_blindTasteProgressKey);
    debugPrint('Blind taste progress cleared');
  }

  /// 保存闪卡记忆进度
  Future<void> saveFlashcardProgress(QuizProgress progress) async {
    await initialize();

    if (progress.type != ProgressType.flashcard) {
      throw ArgumentError('Progress type must be flashcard');
    }

    final jsonString = json.encode(progress.toJson());
    await _prefs!.setString(_flashcardProgressKey, jsonString);
    debugPrint('Flashcard progress saved: ${progress.description}');
  }

  /// 加载闪卡记忆进度
  Future<QuizProgress?> loadFlashcardProgress() async {
    await initialize();

    final jsonString = _prefs!.getString(_flashcardProgressKey);
    if (jsonString != null) {
      try {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final progress = QuizProgress.fromJson(jsonMap);

        if (progress.isValid) {
          debugPrint('Flashcard progress loaded: ${progress.description}');
          return progress;
        } else {
          debugPrint('Invalid flashcard progress found, removing...');
          await clearFlashcardProgress();
        }
      } catch (e) {
        debugPrint('Error loading flashcard progress: $e');
        await clearFlashcardProgress();
      }
    }

    return null;
  }

  /// 检查是否有闪卡记忆进度
  Future<bool> hasFlashcardProgress() async {
    final progress = await loadFlashcardProgress();
    return progress != null;
  }

  /// 清除闪卡记忆进度
  Future<void> clearFlashcardProgress() async {
    await initialize();
    await _prefs!.remove(_flashcardProgressKey);
    debugPrint('Flashcard progress cleared');
  }

  /// 清除所有进度
  Future<void> clearAllProgress() async {
    await clearQuizProgress();
    await clearBlindTasteProgress();
    await clearFlashcardProgress();
    debugPrint('All progress cleared');
  }

  /// 检查是否有答题进度
  Future<bool> hasQuizProgress() async {
    final progress = await loadQuizProgress();
    return progress != null;
  }

  /// 检查是否有品鉴进度
  Future<bool> hasBlindTasteProgress() async {
    final progress = await loadBlindTasteProgress();
    return progress != null;
  }

  /// 检查是否有任何进度
  Future<bool> hasAnyProgress() async {
    final hasQuiz = await hasQuizProgress();
    final hasBlindTaste = await hasBlindTasteProgress();
    return hasQuiz || hasBlindTaste;
  }

  /// 获取进度摘要信息
  Future<Map<String, String?>> getProgressSummary() async {
    final quizProgress = await loadQuizProgress();
    final blindTasteProgress = await loadBlindTasteProgress();

    return {
      'quiz': quizProgress?.description,
      'blindTaste': blindTasteProgress?.description,
    };
  }

  /// 根据类型保存进度
  Future<void> saveProgress(QuizProgress progress) async {
    switch (progress.type) {
      case ProgressType.quiz:
        await saveQuizProgress(progress);
        break;
      case ProgressType.blindTaste:
        await saveBlindTasteProgress(progress);
        break;
      case ProgressType.flashcard:
        await saveFlashcardProgress(progress);
        break;
    }
  }

  /// 根据类型加载进度
  Future<QuizProgress?> loadProgress(ProgressType type) async {
    switch (type) {
      case ProgressType.quiz:
        return await loadQuizProgress();
      case ProgressType.blindTaste:
        return await loadBlindTasteProgress();
      case ProgressType.flashcard:
        return await loadFlashcardProgress();
    }
  }

  /// 根据类型清除进度
  Future<void> clearProgress(ProgressType type) async {
    switch (type) {
      case ProgressType.quiz:
        await clearQuizProgress();
        break;
      case ProgressType.blindTaste:
        await clearBlindTasteProgress();
        break;
      case ProgressType.flashcard:
        await clearFlashcardProgress();
        break;
    }
  }

  /// 检查指定类型是否有进度
  Future<bool> hasProgress(ProgressType type) async {
    switch (type) {
      case ProgressType.quiz:
        return await hasQuizProgress();
      case ProgressType.blindTaste:
        return await hasBlindTasteProgress();
      case ProgressType.flashcard:
        return await hasFlashcardProgress();
    }
  }
}
