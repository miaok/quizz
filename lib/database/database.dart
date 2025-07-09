import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// 导入表定义
part 'database.g.dart';

// 定义Questions表
class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionText => text()();
  TextColumn get options => text()(); // JSON格式存储选项
  TextColumn get type => text()(); // single, multiple, boolean
  TextColumn get correctAnswer => text()(); // JSON格式存储正确答案
  TextColumn get explanation => text().nullable()(); // 解析内容
  TextColumn get category => text().withDefault(const Constant('通用'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 定义BlindTasteItems表
class BlindTasteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // 酒样名称
  TextColumn get aroma => text()(); // 香型
  RealColumn get alcoholDegree => real()(); // 酒度
  RealColumn get totalScore => real()(); // 总分
  TextColumn get equipment => text()(); // 设备，JSON格式存储数组
  TextColumn get fermentationAgent => text()(); // 发酵剂，JSON格式存储数组
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 数据库类
@DriftDatabase(tables: [Questions, BlindTasteItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // 添加BlindTasteItems表
        await m.createTable(blindTasteItems);
      }
    },
  );

  // 获取所有题目
  Future<List<Question>> getAllQuestions() => select(questions).get();

  // 根据分类获取题目
  Future<List<Question>> getQuestionsByCategory(String category) =>
      (select(questions)..where((tbl) => tbl.category.equals(category))).get();

  // 随机获取指定数量的题目
  Future<List<Question>> getRandomQuestions(int count) async {
    final allQuestions = await getAllQuestions();
    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }

  // 根据分类随机获取题目
  Future<List<Question>> getRandomQuestionsByCategory(String category, int count) async {
    final questions = await getQuestionsByCategory(category);
    questions.shuffle();
    return questions.take(count).toList();
  }

  // 插入题目
  Future<int> insertQuestion(QuestionsCompanion question) =>
      into(questions).insert(question);

  // 批量插入题目
  Future<void> insertQuestions(List<QuestionsCompanion> questionList) async {
    await batch((batch) {
      batch.insertAll(questions, questionList);
    });
  }

  // 获取所有分类
  Future<List<String>> getAllCategories() async {
    final query = selectOnly(questions, distinct: true)
      ..addColumns([questions.category]);
    final result = await query.get();
    return result.map((row) => row.read(questions.category)!).toList();
  }

  // 清空所有题目
  Future<void> clearAllQuestions() => delete(questions).go();

  // 获取题目总数
  Future<int> getQuestionCount() async {
    final countExp = questions.id.count();
    final query = selectOnly(questions)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  // ===== 品鉴数据相关方法 =====

  // 获取所有品鉴数据
  Future<List<BlindTasteItem>> getAllBlindTasteItems() => select(blindTasteItems).get();

  // 随机获取一个品鉴数据
  Future<BlindTasteItem?> getRandomBlindTasteItem() async {
    final allItems = await getAllBlindTasteItems();
    if (allItems.isEmpty) return null;
    allItems.shuffle();
    return allItems.first;
  }

  // 根据ID获取品鉴数据
  Future<BlindTasteItem?> getBlindTasteItemById(int id) =>
      (select(blindTasteItems)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  // 插入品鉴数据
  Future<int> insertBlindTasteItem(BlindTasteItemsCompanion item) =>
      into(blindTasteItems).insert(item);

  // 批量插入品鉴数据
  Future<void> insertBlindTasteItems(List<BlindTasteItemsCompanion> itemList) async {
    await batch((batch) {
      batch.insertAll(blindTasteItems, itemList);
    });
  }

  // 获取品鉴数据总数
  Future<int> getBlindTasteItemCount() async {
    final countExp = blindTasteItems.id.count();
    final query = selectOnly(blindTasteItems)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  // 清空所有品鉴数据
  Future<void> clearAllBlindTasteItems() => delete(blindTasteItems).go();

  // 根据香型搜索品鉴数据
  Future<List<BlindTasteItem>> getBlindTasteItemsByAroma(String aroma) =>
      (select(blindTasteItems)..where((tbl) => tbl.aroma.equals(aroma))).get();

  // 根据名称搜索品鉴数据
  Future<List<BlindTasteItem>> searchBlindTasteItemsByName(String name) =>
      (select(blindTasteItems)..where((tbl) => tbl.name.like('%$name%'))).get();
}

// 数据库连接配置
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'quiz_database.db'));
    return NativeDatabase(file);
  });
}
