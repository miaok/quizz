import 'dart:convert';
import '../models/blind_taste_model.dart';
import '../database/database.dart';
import 'database_service.dart';

/// 酒样品鉴数据服务
class BlindTasteService {
  static final BlindTasteService _instance = BlindTasteService._internal();
  factory BlindTasteService() => _instance;
  BlindTasteService._internal();

  AppDatabase get _database => DatabaseService().database;

  /// 初始化服务（实际上数据已经在DatabaseService中加载了）
  Future<void> initialize() async {
    // 数据已经在DatabaseService中加载，这里不需要做任何事情
  }

  /// 获取所有酒样数据
  Future<List<BlindTasteItemModel>> getAllItems() async {
    final dbItems = await _database.getAllBlindTasteItems();
    return dbItems.map((dbItem) => _convertFromDbItem(dbItem)).toList();
  }

  /// 获取随机酒样
  Future<BlindTasteItemModel?> getRandomItem() async {
    final dbItem = await _database.getRandomBlindTasteItem();
    return dbItem != null ? _convertFromDbItem(dbItem) : null;
  }

  /// 根据索引获取酒样
  Future<BlindTasteItemModel?> getItemByIndex(int index) async {
    final items = await getAllItems();
    if (index < 0 || index >= items.length) return null;
    return items[index];
  }

  /// 根据ID获取酒样
  Future<BlindTasteItemModel?> getItemById(int id) async {
    final dbItem = await _database.getBlindTasteItemById(id);
    return dbItem != null ? _convertFromDbItem(dbItem) : null;
  }

  /// 获取酒样总数
  Future<int> getItemCount() async {
    return await _database.getBlindTasteItemCount();
  }

  /// 将数据库项转换为模型
  BlindTasteItemModel _convertFromDbItem(BlindTasteItem dbItem) {
    return BlindTasteItemModel(
      id: dbItem.id,
      name: dbItem.name,
      aroma: dbItem.aroma,
      alcoholDegree: dbItem.alcoholDegree,
      totalScore: dbItem.totalScore,
      equipment: List<String>.from(json.decode(dbItem.equipment)),
      fermentationAgent: List<String>.from(
        json.decode(dbItem.fermentationAgent),
      ),
    );
  }

  /// 搜索酒样（按名称）
  Future<List<BlindTasteItemModel>> searchByName(String query) async {
    final items = await getAllItems();
    if (query.isEmpty) return items;

    return items
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// 按香型筛选
  Future<List<BlindTasteItemModel>> filterByAroma(String aroma) async {
    final items = await getAllItems();
    return items.where((item) => item.aroma == aroma).toList();
  }

  /// 按酒度范围筛选
  Future<List<BlindTasteItemModel>> filterByAlcoholDegree(
    double minDegree,
    double maxDegree,
  ) async {
    final items = await getAllItems();
    return items
        .where(
          (item) =>
              item.alcoholDegree >= minDegree &&
              item.alcoholDegree <= maxDegree,
        )
        .toList();
  }

  /// 获取所有香型（去重）
  Future<List<String>> getAllAromaTypes() async {
    final items = await getAllItems();
    return items.map((item) => item.aroma).toSet().toList()..sort();
  }

  /// 获取所有设备类型（去重）
  Future<List<String>> getAllEquipmentTypes() async {
    final items = await getAllItems();
    final Set<String> equipmentSet = {};

    for (final item in items) {
      equipmentSet.addAll(item.equipment);
    }

    return equipmentSet.toList()..sort();
  }

  /// 获取所有发酵剂类型（去重）
  Future<List<String>> getAllFermentationAgents() async {
    final items = await getAllItems();
    final Set<String> agentSet = {};

    for (final item in items) {
      agentSet.addAll(item.fermentationAgent);
    }

    return agentSet.toList()..sort();
  }

  /// 获取酒度范围
  Future<(double min, double max)> getAlcoholDegreeRange() async {
    final items = await getAllItems();
    if (items.isEmpty) return (0.0, 100.0);

    double min = items.first.alcoholDegree;
    double max = items.first.alcoholDegree;

    for (final item in items) {
      if (item.alcoholDegree < min) min = item.alcoholDegree;
      if (item.alcoholDegree > max) max = item.alcoholDegree;
    }

    return (min, max);
  }

  /// 获取总分范围
  Future<(double min, double max)> getTotalScoreRange() async {
    final items = await getAllItems();
    if (items.isEmpty) return (0.0, 100.0);

    double min = items.first.totalScore;
    double max = items.first.totalScore;

    for (final item in items) {
      if (item.totalScore < min) min = item.totalScore;
      if (item.totalScore > max) max = item.totalScore;
    }

    return (min, max);
  }
}
