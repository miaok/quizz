/// 酒样品鉴数据模型
class BlindTasteItemModel {
  final int? id; // 数据库ID
  final String name;
  final String aroma;
  final double alcoholDegree;
  final double totalScore;
  final List<String> equipment;
  final List<String> fermentationAgent;

  const BlindTasteItemModel({
    this.id,
    required this.name,
    required this.aroma,
    required this.alcoholDegree,
    required this.totalScore,
    required this.equipment,
    required this.fermentationAgent,
  });

  factory BlindTasteItemModel.fromJson(Map<String, dynamic> json) {
    // 处理设备字段，可能是字符串或列表
    List<String> equipmentList;
    if (json['设备'] is String) {
      equipmentList = (json['设备'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList();
    } else if (json['设备'] is List) {
      equipmentList = (json['设备'] as List).map((e) => e.toString()).toList();
    } else {
      equipmentList = [];
    }

    // 处理发酵剂字段，可能是字符串或列表
    List<String> fermentationAgentList;
    if (json['发酵剂'] is String) {
      fermentationAgentList = (json['发酵剂'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList();
    } else if (json['发酵剂'] is List) {
      fermentationAgentList = (json['发酵剂'] as List)
          .map((e) => e.toString())
          .toList();
    } else {
      fermentationAgentList = [];
    }

    return BlindTasteItemModel(
      id: json['id'] as int?,
      name: json['酒样名称'] ?? '',
      aroma: json['香型'] ?? '',
      alcoholDegree: (json['酒度'] ?? 0.0).toDouble(),
      totalScore: (json['总分'] ?? 0.0).toDouble(),
      equipment: equipmentList,
      fermentationAgent: fermentationAgentList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '酒样名称': name,
      '香型': aroma,
      '酒度': alcoholDegree,
      '总分': totalScore,
      '设备': equipment.join(','),
      '发酵剂': fermentationAgent.join(','),
    };
  }
}

/// 用户品鉴答案模型
class BlindTasteAnswer {
  String? selectedAroma;
  double? selectedAlcoholDegree;
  double selectedTotalScore;
  List<String> selectedEquipment;
  List<String> selectedFermentationAgent;

  BlindTasteAnswer({
    this.selectedAroma,
    this.selectedAlcoholDegree,
    this.selectedTotalScore = 91.0,
    this.selectedEquipment = const [],
    this.selectedFermentationAgent = const [],
  });

  /// 计算得分（根据启用的品鉴项目动态分配分数）
  double calculateScore(
    BlindTasteItemModel correctAnswer, {
    bool enableAroma = true,
    bool enableAlcohol = true,
    bool enableScore = true,
    bool enableEquipment = true,
    bool enableFermentation = true,
  }) {
    double score = 0.0;

    // 计算启用的项目数量，用于动态分配分数
    int enabledItemsCount = 0;
    if (enableAroma) enabledItemsCount++;
    if (enableAlcohol) enabledItemsCount++;
    if (enableScore) enabledItemsCount++;
    if (enableEquipment) enabledItemsCount++;
    if (enableFermentation) enabledItemsCount++;

    if (enabledItemsCount == 0) return 0.0;

    // 每个项目的基础分数（总分100分平均分配）
    double baseScore = 100.0 / enabledItemsCount;

    // 香型匹配
    if (enableAroma && selectedAroma == correctAnswer.aroma) {
      score += baseScore;
    }

    // 酒度匹配 - 允许±1-2度误差
    if (enableAlcohol && selectedAlcoholDegree != null) {
      double diff = (selectedAlcoholDegree! - correctAnswer.alcoholDegree)
          .abs();
      if (diff <= 1) {
        score += baseScore;
      } else if (diff <= 2) {
        score += baseScore * 0.25; // 部分分数
      }
    }

    // 总分匹配 - 必须完全匹配
    if (enableScore) {
      if (selectedTotalScore == correctAnswer.totalScore) {
        score += baseScore;
      }
    }

    // 设备匹配 - 顺序不影响，只要包含的元素相同
    if (enableEquipment) {
      Set<String> selectedEquipmentSet = selectedEquipment.toSet();
      Set<String> correctEquipmentSet = correctAnswer.equipment.toSet();
      if (selectedEquipmentSet.length == correctEquipmentSet.length &&
          selectedEquipmentSet.containsAll(correctEquipmentSet)) {
        score += baseScore;
      } else if (correctEquipmentSet.isNotEmpty) {
        int equipmentMatches = selectedEquipmentSet
            .intersection(correctEquipmentSet)
            .length;
        score += (equipmentMatches / correctEquipmentSet.length) * baseScore;
      }
    }

    // 发酵剂匹配 - 顺序不影响，只要包含的元素相同
    if (enableFermentation) {
      Set<String> selectedAgentSet = selectedFermentationAgent.toSet();
      Set<String> correctAgentSet = correctAnswer.fermentationAgent.toSet();
      if (selectedAgentSet.length == correctAgentSet.length &&
          selectedAgentSet.containsAll(correctAgentSet)) {
        score += baseScore;
      } else if (correctAgentSet.isNotEmpty) {
        int fermentationMatches = selectedAgentSet
            .intersection(correctAgentSet)
            .length;
        score += (fermentationMatches / correctAgentSet.length) * baseScore;
      }
    }

    return score.clamp(0, 100);
  }

  /// 兼容性方法：使用默认设置计算得分
  double calculateScoreDefault(BlindTasteItemModel correctAnswer) {
    return calculateScore(correctAnswer);
  }

  /// 重置答案
  void reset() {
    selectedAroma = null;
    selectedAlcoholDegree = null;
    selectedTotalScore = 91.0;
    selectedEquipment = [];
    selectedFermentationAgent = [];
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'selectedAroma': selectedAroma,
      'selectedAlcoholDegree': selectedAlcoholDegree,
      'selectedTotalScore': selectedTotalScore,
      'selectedEquipment': selectedEquipment,
      'selectedFermentationAgent': selectedFermentationAgent,
    };
  }

  /// 从JSON创建
  factory BlindTasteAnswer.fromJson(Map<String, dynamic> json) {
    // 安全地转换设备列表
    List<String> equipmentList = [];
    if (json['selectedEquipment'] != null) {
      final equipmentData = json['selectedEquipment'];
      if (equipmentData is List) {
        equipmentList = equipmentData.map((e) => e.toString()).toList();
      }
    }

    // 安全地转换发酵剂列表
    List<String> fermentationAgentList = [];
    if (json['selectedFermentationAgent'] != null) {
      final agentData = json['selectedFermentationAgent'];
      if (agentData is List) {
        fermentationAgentList = agentData.map((e) => e.toString()).toList();
      }
    }

    return BlindTasteAnswer(
      selectedAroma: json['selectedAroma'] as String?,
      selectedAlcoholDegree: json['selectedAlcoholDegree'] as double?,
      selectedTotalScore: json['selectedTotalScore'] as double? ?? 91.0,
      selectedEquipment: equipmentList,
      selectedFermentationAgent: fermentationAgentList,
    );
  }
}

/// 品鉴选项常量
class BlindTasteOptions {
  // 香型选项
  static const List<String> aromaTypes = [
    '浓香型',
    '清香型',
    '酱香型',
    '米香型',
    '兼香型',
    '凤香型',
    '豉香型',
    '特香型',
    '芝麻香型',
    '小曲清香型',
    '麸曲清香型',
    '大麸清香型',
    '多粮浓香型',
    '董香型',
    '老白干型',
    '馥郁香型',
  ];

  // 酒度选项 (常见酒度)
  static const List<double> alcoholDegrees = [32, 45, 50, 52, 53, 54, 55];

  // 设备选项
  static const List<String> equipmentTypes = [
    '泥窖',
    '地缸',
    '石窖',
    '砖窖',
    '水泥池',
    '瓷砖窖',
    '陶罐',
    '发酵罐',
  ];

  // 发酵剂选项
  static const List<String> fermentationAgents = ['大曲', '小曲', '酵母', '麸曲'];
}
