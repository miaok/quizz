import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';
import '../providers/quiz_provider.dart';

/// 进度保存服务
class ProgressService {
  static const String _quizProgressKey = 'quiz_progress';
  static const String _quizPracticeProgressKey = 'quiz_practice_progress'; // 理论练习进度
  static const String _quizExamProgressKey = 'quiz_exam_progress'; // 理论模拟进度
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

    // 根据模式选择不同的存储键
    String storageKey;
    switch (progress.mode) {
      case QuizMode.practice:
        storageKey = _quizPracticeProgressKey;
        break;
      case QuizMode.exam:
        storageKey = _quizExamProgressKey;
        break;
      default:
        storageKey = _quizProgressKey; // 兼容性处理
        break;
    }

    final jsonString = json.encode(progress.toJson());
    await _prefs!.setString(storageKey, jsonString);
    debugPrint('Quiz progress saved for ${progress.mode?.name ?? 'unknown'} mode: ${progress.description}');
    debugPrint('Storage key: $storageKey, Data size: ${jsonString.length} chars');
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
  Future<QuizProgress?> loadQuizProgress([QuizMode? mode]) async {
    await initialize();

    if (mode != null) {
      // 加载指定模式的进度
      String storageKey;
      switch (mode) {
        case QuizMode.practice:
          storageKey = _quizPracticeProgressKey;
          break;
        case QuizMode.exam:
          storageKey = _quizExamProgressKey;
          break;
      }

      debugPrint('Attempting to load quiz progress for ${mode.name} mode from key: $storageKey');
      final jsonString = _prefs!.getString(storageKey);
      if (jsonString != null) {
        debugPrint('Found saved progress data, size: ${jsonString.length} chars');
        try {
          final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
          final progress = QuizProgress.fromJson(jsonMap);

          if (progress.isValid) {
            debugPrint('Quiz progress loaded successfully for ${mode.name} mode: ${progress.description}');
            debugPrint('Progress details: currentIndex=${progress.currentIndex}, questionsCount=${progress.questions.length}, practiceShuffleMode=${progress.practiceShuffleMode}');
            return progress;
          } else {
            debugPrint('Invalid quiz progress found for ${mode.name} mode, removing...');
            await _clearQuizProgressForMode(mode);
          }
        } catch (e) {
          debugPrint('Error parsing quiz progress for ${mode.name} mode: $e');
          await _clearQuizProgressForMode(mode);
        }
      } else {
        debugPrint('No saved progress found for ${mode.name} mode');
      }

      return null;
    } else {
      // 兼容性处理：先尝试加载旧的通用进度，然后迁移到新的存储方式
      debugPrint('Loading progress without specific mode (compatibility mode)');
      final jsonString = _prefs!.getString(_quizProgressKey);
      if (jsonString != null) {
        try {
          final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
          final progress = QuizProgress.fromJson(jsonMap);

          if (progress.isValid && progress.mode != null) {
            // 迁移到新的存储方式
            debugPrint('Migrating old progress to new storage format for ${progress.mode!.name} mode');
            await saveQuizProgress(progress);
            await _prefs!.remove(_quizProgressKey); // 删除旧的存储
            debugPrint('Migration completed successfully');
            return progress;
          } else {
            debugPrint('Invalid old progress found, removing...');
            await _prefs!.remove(_quizProgressKey);
          }
        } catch (e) {
          debugPrint('Error loading old quiz progress: $e');
          await _prefs!.remove(_quizProgressKey);
        }
      }
      return null;
    }
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
  Future<void> clearQuizProgress([QuizMode? mode]) async {
    await initialize();

    if (mode != null) {
      await _clearQuizProgressForMode(mode);
    } else {
      // 清除所有答题进度
      await _prefs!.remove(_quizProgressKey); // 兼容性处理
      await _prefs!.remove(_quizPracticeProgressKey);
      await _prefs!.remove(_quizExamProgressKey);
      debugPrint('All quiz progress cleared');
    }
  }

  /// 清除指定模式的答题进度
  Future<void> _clearQuizProgressForMode(QuizMode mode) async {
    await initialize();

    String storageKey;
    switch (mode) {
      case QuizMode.practice:
        storageKey = _quizPracticeProgressKey;
        break;
      case QuizMode.exam:
        storageKey = _quizExamProgressKey;
        break;
    }

    await _prefs!.remove(storageKey);
    debugPrint('Quiz progress cleared for ${mode.name} mode');
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
  Future<bool> hasQuizProgress([QuizMode? mode]) async {
    if (mode != null) {
      final progress = await loadQuizProgress(mode);
      return progress != null;
    } else {
      // 检查是否有任何答题进度
      final practiceProgress = await loadQuizProgress(QuizMode.practice);
      final examProgress = await loadQuizProgress(QuizMode.exam);
      final oldProgress = await loadQuizProgress(); // 兼容性检查
      return practiceProgress != null || examProgress != null || oldProgress != null;
    }
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
