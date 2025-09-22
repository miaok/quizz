import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/quiz_page.dart';
import '../pages/result_page.dart';
import '../pages/settings_page.dart';
import '../pages/blind_taste_page.dart';
import '../pages/search_page.dart';
import '../pages/flashcard_page.dart';
import '../pages/wine_simulation_page.dart';
import '../pages/score_records_page.dart';

// 路由路径常量
class AppRoutes {
  static const String home = '/';
  static const String quiz = '/quiz';
  static const String result = '/quiz/result';
  static const String settings = '/settings';
  static const String blindTaste = '/blind-taste';
  static const String search = '/search';
  static const String flashcard = '/flashcard';
  static const String wineSimulation = '/wine-simulation';
  static const String scoreRecords = '/score-records';
}

// 应用路由配置
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    // 首页路由 - 作为根路由
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
      routes: [
        // 设置页路由 - 首页的子路由
        GoRoute(
          path: 'settings', // 相对路径，实际为 /settings
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),

        // 答题页路由 - 首页的子路由
        GoRoute(
          path: 'quiz', // 相对路径，实际为 /quiz
          name: 'quiz',
          builder: (context, state) => const QuizPage(),
          routes: [
            // 结果页路由 - 答题页的子路由
            GoRoute(
              path: 'result', // 相对路径，实际为 /quiz/result
              name: 'result',
              builder: (context, state) => const ResultPage(),
            ),
          ],
        ),

        // 品鉴页路由 - 首页的子路由
        GoRoute(
          path: 'blind-taste', // 相对路径，实际为 /blind-taste
          name: 'blind-taste',
          builder: (context, state) => const BlindTastePage(),
        ),

        // 搜索页路由 - 首页的子路由
        GoRoute(
          path: 'search', // 相对路径，实际为 /search
          name: 'search',
          builder: (context, state) => const SearchPage(),
        ),

        // 闪卡记忆页路由 - 首页的子路由
        GoRoute(
          path: 'flashcard', // 相对路径，实际为 /flashcard
          name: 'flashcard',
          builder: (context, state) => const FlashcardPage(),
        ),

        // 酒样练习页路由 - 首页的子路由
        GoRoute(
          path: 'wine-simulation', // 相对路径，实际为 /wine-simulation
          name: 'wine-simulation',
          builder: (context, state) => const WineSimulationPage(),
        ),

        // 得分记录页路由 - 首页的子路由
        GoRoute(
          path: 'score-records', // 相对路径，实际为 /score-records
          name: 'score-records',
          builder: (context, state) => const ScoreRecordsPage(),
        ),
      ],
    ),
  ],

  // 错误页面处理
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('页面未找到')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('页面未找到: ${state.uri}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('返回首页'),
          ),
        ],
      ),
    ),
  ),
);

// 路由扩展方法
extension AppRouterExtension on GoRouter {
  // 导航到答题页
  void goToQuiz({String? category, int questionCount = 10}) {
    push(AppRoutes.quiz); // 使用push而不是go，保持导航栈
  }

  // 导航到结果页
  void goToResult() {
    push(AppRoutes.result); // 使用push而不是go，保持导航栈
  }

  // 返回首页
  void goToHome() {
    go(AppRoutes.home); // 清空导航栈，回到根页面
  }

  // 导航到设置页
  void goToSettings() {
    push(AppRoutes.settings); // 使用push而不是go，保持导航栈
  }

  // 导航到品鉴页
  void goToBlindTaste() {
    push(AppRoutes.blindTaste); // 使用push而不是go，保持导航栈
  }

  // 导航到搜索页
  void goToSearch() {
    push(AppRoutes.search); // 使用push而不是go，保持导航栈
  }

  // 导航到闪卡记忆页
  void goToFlashcard() {
    push(AppRoutes.flashcard); // 使用push而不是go，保持导航栈
  }

  // 导航到酒样练习页
  void goToWineSimulation() {
    push(AppRoutes.wineSimulation); // 使用push而不是go，保持导航栈
  }

  // 导航到得分记录页
  void goToScoreRecords() {
    push(AppRoutes.scoreRecords); // 使用push而不是go，保持导航栈
  }
}
