// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, Question> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionTextMeta = const VerificationMeta(
    'questionText',
  );
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
    'question_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctAnswerMeta = const VerificationMeta(
    'correctAnswer',
  );
  @override
  late final GeneratedColumn<String> correctAnswer = GeneratedColumn<String>(
    'correct_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('通用'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionText,
    options,
    type,
    correctAnswer,
    explanation,
    category,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Question> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_text')) {
      context.handle(
        _questionTextMeta,
        questionText.isAcceptableOrUnknown(
          data['question_text']!,
          _questionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTextMeta);
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    } else if (isInserting) {
      context.missing(_optionsMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('correct_answer')) {
      context.handle(
        _correctAnswerMeta,
        correctAnswer.isAcceptableOrUnknown(
          data['correct_answer']!,
          _correctAnswerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctAnswerMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Question map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Question(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_text'],
      )!,
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      correctAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_answer'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class Question extends DataClass implements Insertable<Question> {
  final int id;
  final String questionText;
  final String options;
  final String type;
  final String correctAnswer;
  final String? explanation;
  final String category;
  final DateTime createdAt;
  const Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.type,
    required this.correctAnswer,
    this.explanation,
    required this.category,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_text'] = Variable<String>(questionText);
    map['options'] = Variable<String>(options);
    map['type'] = Variable<String>(type);
    map['correct_answer'] = Variable<String>(correctAnswer);
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      questionText: Value(questionText),
      options: Value(options),
      type: Value(type),
      correctAnswer: Value(correctAnswer),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      category: Value(category),
      createdAt: Value(createdAt),
    );
  }

  factory Question.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Question(
      id: serializer.fromJson<int>(json['id']),
      questionText: serializer.fromJson<String>(json['questionText']),
      options: serializer.fromJson<String>(json['options']),
      type: serializer.fromJson<String>(json['type']),
      correctAnswer: serializer.fromJson<String>(json['correctAnswer']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionText': serializer.toJson<String>(questionText),
      'options': serializer.toJson<String>(options),
      'type': serializer.toJson<String>(type),
      'correctAnswer': serializer.toJson<String>(correctAnswer),
      'explanation': serializer.toJson<String?>(explanation),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Question copyWith({
    int? id,
    String? questionText,
    String? options,
    String? type,
    String? correctAnswer,
    Value<String?> explanation = const Value.absent(),
    String? category,
    DateTime? createdAt,
  }) => Question(
    id: id ?? this.id,
    questionText: questionText ?? this.questionText,
    options: options ?? this.options,
    type: type ?? this.type,
    correctAnswer: correctAnswer ?? this.correctAnswer,
    explanation: explanation.present ? explanation.value : this.explanation,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
  );
  Question copyWithCompanion(QuestionsCompanion data) {
    return Question(
      id: data.id.present ? data.id.value : this.id,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      options: data.options.present ? data.options.value : this.options,
      type: data.type.present ? data.type.value : this.type,
      correctAnswer: data.correctAnswer.present
          ? data.correctAnswer.value
          : this.correctAnswer,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Question(')
          ..write('id: $id, ')
          ..write('questionText: $questionText, ')
          ..write('options: $options, ')
          ..write('type: $type, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questionText,
    options,
    type,
    correctAnswer,
    explanation,
    category,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Question &&
          other.id == this.id &&
          other.questionText == this.questionText &&
          other.options == this.options &&
          other.type == this.type &&
          other.correctAnswer == this.correctAnswer &&
          other.explanation == this.explanation &&
          other.category == this.category &&
          other.createdAt == this.createdAt);
}

class QuestionsCompanion extends UpdateCompanion<Question> {
  final Value<int> id;
  final Value<String> questionText;
  final Value<String> options;
  final Value<String> type;
  final Value<String> correctAnswer;
  final Value<String?> explanation;
  final Value<String> category;
  final Value<DateTime> createdAt;
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.questionText = const Value.absent(),
    this.options = const Value.absent(),
    this.type = const Value.absent(),
    this.correctAnswer = const Value.absent(),
    this.explanation = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  QuestionsCompanion.insert({
    this.id = const Value.absent(),
    required String questionText,
    required String options,
    required String type,
    required String correctAnswer,
    this.explanation = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : questionText = Value(questionText),
       options = Value(options),
       type = Value(type),
       correctAnswer = Value(correctAnswer);
  static Insertable<Question> custom({
    Expression<int>? id,
    Expression<String>? questionText,
    Expression<String>? options,
    Expression<String>? type,
    Expression<String>? correctAnswer,
    Expression<String>? explanation,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionText != null) 'question_text': questionText,
      if (options != null) 'options': options,
      if (type != null) 'type': type,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  QuestionsCompanion copyWith({
    Value<int>? id,
    Value<String>? questionText,
    Value<String>? options,
    Value<String>? type,
    Value<String>? correctAnswer,
    Value<String?>? explanation,
    Value<String>? category,
    Value<DateTime>? createdAt,
  }) {
    return QuestionsCompanion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      type: type ?? this.type,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (correctAnswer.present) {
      map['correct_answer'] = Variable<String>(correctAnswer.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('questionText: $questionText, ')
          ..write('options: $options, ')
          ..write('type: $type, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BlindTasteItemsTable extends BlindTasteItems
    with TableInfo<$BlindTasteItemsTable, BlindTasteItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlindTasteItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aromaMeta = const VerificationMeta('aroma');
  @override
  late final GeneratedColumn<String> aroma = GeneratedColumn<String>(
    'aroma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alcoholDegreeMeta = const VerificationMeta(
    'alcoholDegree',
  );
  @override
  late final GeneratedColumn<double> alcoholDegree = GeneratedColumn<double>(
    'alcohol_degree',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalScoreMeta = const VerificationMeta(
    'totalScore',
  );
  @override
  late final GeneratedColumn<double> totalScore = GeneratedColumn<double>(
    'total_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fermentationAgentMeta = const VerificationMeta(
    'fermentationAgent',
  );
  @override
  late final GeneratedColumn<String> fermentationAgent =
      GeneratedColumn<String>(
        'fermentation_agent',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    aroma,
    alcoholDegree,
    totalScore,
    equipment,
    fermentationAgent,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blind_taste_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlindTasteItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('aroma')) {
      context.handle(
        _aromaMeta,
        aroma.isAcceptableOrUnknown(data['aroma']!, _aromaMeta),
      );
    } else if (isInserting) {
      context.missing(_aromaMeta);
    }
    if (data.containsKey('alcohol_degree')) {
      context.handle(
        _alcoholDegreeMeta,
        alcoholDegree.isAcceptableOrUnknown(
          data['alcohol_degree']!,
          _alcoholDegreeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_alcoholDegreeMeta);
    }
    if (data.containsKey('total_score')) {
      context.handle(
        _totalScoreMeta,
        totalScore.isAcceptableOrUnknown(data['total_score']!, _totalScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_totalScoreMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    } else if (isInserting) {
      context.missing(_equipmentMeta);
    }
    if (data.containsKey('fermentation_agent')) {
      context.handle(
        _fermentationAgentMeta,
        fermentationAgent.isAcceptableOrUnknown(
          data['fermentation_agent']!,
          _fermentationAgentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fermentationAgentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlindTasteItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlindTasteItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      aroma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aroma'],
      )!,
      alcoholDegree: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alcohol_degree'],
      )!,
      totalScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_score'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      fermentationAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fermentation_agent'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BlindTasteItemsTable createAlias(String alias) {
    return $BlindTasteItemsTable(attachedDatabase, alias);
  }
}

class BlindTasteItem extends DataClass implements Insertable<BlindTasteItem> {
  final int id;
  final String name;
  final String aroma;
  final double alcoholDegree;
  final double totalScore;
  final String equipment;
  final String fermentationAgent;
  final DateTime createdAt;
  const BlindTasteItem({
    required this.id,
    required this.name,
    required this.aroma,
    required this.alcoholDegree,
    required this.totalScore,
    required this.equipment,
    required this.fermentationAgent,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['aroma'] = Variable<String>(aroma);
    map['alcohol_degree'] = Variable<double>(alcoholDegree);
    map['total_score'] = Variable<double>(totalScore);
    map['equipment'] = Variable<String>(equipment);
    map['fermentation_agent'] = Variable<String>(fermentationAgent);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BlindTasteItemsCompanion toCompanion(bool nullToAbsent) {
    return BlindTasteItemsCompanion(
      id: Value(id),
      name: Value(name),
      aroma: Value(aroma),
      alcoholDegree: Value(alcoholDegree),
      totalScore: Value(totalScore),
      equipment: Value(equipment),
      fermentationAgent: Value(fermentationAgent),
      createdAt: Value(createdAt),
    );
  }

  factory BlindTasteItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlindTasteItem(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      aroma: serializer.fromJson<String>(json['aroma']),
      alcoholDegree: serializer.fromJson<double>(json['alcoholDegree']),
      totalScore: serializer.fromJson<double>(json['totalScore']),
      equipment: serializer.fromJson<String>(json['equipment']),
      fermentationAgent: serializer.fromJson<String>(json['fermentationAgent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'aroma': serializer.toJson<String>(aroma),
      'alcoholDegree': serializer.toJson<double>(alcoholDegree),
      'totalScore': serializer.toJson<double>(totalScore),
      'equipment': serializer.toJson<String>(equipment),
      'fermentationAgent': serializer.toJson<String>(fermentationAgent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BlindTasteItem copyWith({
    int? id,
    String? name,
    String? aroma,
    double? alcoholDegree,
    double? totalScore,
    String? equipment,
    String? fermentationAgent,
    DateTime? createdAt,
  }) => BlindTasteItem(
    id: id ?? this.id,
    name: name ?? this.name,
    aroma: aroma ?? this.aroma,
    alcoholDegree: alcoholDegree ?? this.alcoholDegree,
    totalScore: totalScore ?? this.totalScore,
    equipment: equipment ?? this.equipment,
    fermentationAgent: fermentationAgent ?? this.fermentationAgent,
    createdAt: createdAt ?? this.createdAt,
  );
  BlindTasteItem copyWithCompanion(BlindTasteItemsCompanion data) {
    return BlindTasteItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      aroma: data.aroma.present ? data.aroma.value : this.aroma,
      alcoholDegree: data.alcoholDegree.present
          ? data.alcoholDegree.value
          : this.alcoholDegree,
      totalScore: data.totalScore.present
          ? data.totalScore.value
          : this.totalScore,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      fermentationAgent: data.fermentationAgent.present
          ? data.fermentationAgent.value
          : this.fermentationAgent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlindTasteItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('aroma: $aroma, ')
          ..write('alcoholDegree: $alcoholDegree, ')
          ..write('totalScore: $totalScore, ')
          ..write('equipment: $equipment, ')
          ..write('fermentationAgent: $fermentationAgent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    aroma,
    alcoholDegree,
    totalScore,
    equipment,
    fermentationAgent,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlindTasteItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.aroma == this.aroma &&
          other.alcoholDegree == this.alcoholDegree &&
          other.totalScore == this.totalScore &&
          other.equipment == this.equipment &&
          other.fermentationAgent == this.fermentationAgent &&
          other.createdAt == this.createdAt);
}

class BlindTasteItemsCompanion extends UpdateCompanion<BlindTasteItem> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> aroma;
  final Value<double> alcoholDegree;
  final Value<double> totalScore;
  final Value<String> equipment;
  final Value<String> fermentationAgent;
  final Value<DateTime> createdAt;
  const BlindTasteItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.aroma = const Value.absent(),
    this.alcoholDegree = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.equipment = const Value.absent(),
    this.fermentationAgent = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BlindTasteItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String aroma,
    required double alcoholDegree,
    required double totalScore,
    required String equipment,
    required String fermentationAgent,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       aroma = Value(aroma),
       alcoholDegree = Value(alcoholDegree),
       totalScore = Value(totalScore),
       equipment = Value(equipment),
       fermentationAgent = Value(fermentationAgent);
  static Insertable<BlindTasteItem> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? aroma,
    Expression<double>? alcoholDegree,
    Expression<double>? totalScore,
    Expression<String>? equipment,
    Expression<String>? fermentationAgent,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (aroma != null) 'aroma': aroma,
      if (alcoholDegree != null) 'alcohol_degree': alcoholDegree,
      if (totalScore != null) 'total_score': totalScore,
      if (equipment != null) 'equipment': equipment,
      if (fermentationAgent != null) 'fermentation_agent': fermentationAgent,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BlindTasteItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? aroma,
    Value<double>? alcoholDegree,
    Value<double>? totalScore,
    Value<String>? equipment,
    Value<String>? fermentationAgent,
    Value<DateTime>? createdAt,
  }) {
    return BlindTasteItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      aroma: aroma ?? this.aroma,
      alcoholDegree: alcoholDegree ?? this.alcoholDegree,
      totalScore: totalScore ?? this.totalScore,
      equipment: equipment ?? this.equipment,
      fermentationAgent: fermentationAgent ?? this.fermentationAgent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (aroma.present) {
      map['aroma'] = Variable<String>(aroma.value);
    }
    if (alcoholDegree.present) {
      map['alcohol_degree'] = Variable<double>(alcoholDegree.value);
    }
    if (totalScore.present) {
      map['total_score'] = Variable<double>(totalScore.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (fermentationAgent.present) {
      map['fermentation_agent'] = Variable<String>(fermentationAgent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlindTasteItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('aroma: $aroma, ')
          ..write('alcoholDegree: $alcoholDegree, ')
          ..write('totalScore: $totalScore, ')
          ..write('equipment: $equipment, ')
          ..write('fermentationAgent: $fermentationAgent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $BlindTasteItemsTable blindTasteItems = $BlindTasteItemsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    questions,
    blindTasteItems,
  ];
}

typedef $$QuestionsTableCreateCompanionBuilder =
    QuestionsCompanion Function({
      Value<int> id,
      required String questionText,
      required String options,
      required String type,
      required String correctAnswer,
      Value<String?> explanation,
      Value<String> category,
      Value<DateTime> createdAt,
    });
typedef $$QuestionsTableUpdateCompanionBuilder =
    QuestionsCompanion Function({
      Value<int> id,
      Value<String> questionText,
      Value<String> options,
      Value<String> type,
      Value<String> correctAnswer,
      Value<String?> explanation,
      Value<String> category,
      Value<DateTime> createdAt,
    });

class $$QuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestionsTable,
          Question,
          $$QuestionsTableFilterComposer,
          $$QuestionsTableOrderingComposer,
          $$QuestionsTableAnnotationComposer,
          $$QuestionsTableCreateCompanionBuilder,
          $$QuestionsTableUpdateCompanionBuilder,
          (Question, BaseReferences<_$AppDatabase, $QuestionsTable, Question>),
          Question,
          PrefetchHooks Function()
        > {
  $$QuestionsTableTableManager(_$AppDatabase db, $QuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questionText = const Value.absent(),
                Value<String> options = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> correctAnswer = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QuestionsCompanion(
                id: id,
                questionText: questionText,
                options: options,
                type: type,
                correctAnswer: correctAnswer,
                explanation: explanation,
                category: category,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questionText,
                required String options,
                required String type,
                required String correctAnswer,
                Value<String?> explanation = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QuestionsCompanion.insert(
                id: id,
                questionText: questionText,
                options: options,
                type: type,
                correctAnswer: correctAnswer,
                explanation: explanation,
                category: category,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestionsTable,
      Question,
      $$QuestionsTableFilterComposer,
      $$QuestionsTableOrderingComposer,
      $$QuestionsTableAnnotationComposer,
      $$QuestionsTableCreateCompanionBuilder,
      $$QuestionsTableUpdateCompanionBuilder,
      (Question, BaseReferences<_$AppDatabase, $QuestionsTable, Question>),
      Question,
      PrefetchHooks Function()
    >;
typedef $$BlindTasteItemsTableCreateCompanionBuilder =
    BlindTasteItemsCompanion Function({
      Value<int> id,
      required String name,
      required String aroma,
      required double alcoholDegree,
      required double totalScore,
      required String equipment,
      required String fermentationAgent,
      Value<DateTime> createdAt,
    });
typedef $$BlindTasteItemsTableUpdateCompanionBuilder =
    BlindTasteItemsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> aroma,
      Value<double> alcoholDegree,
      Value<double> totalScore,
      Value<String> equipment,
      Value<String> fermentationAgent,
      Value<DateTime> createdAt,
    });

class $$BlindTasteItemsTableFilterComposer
    extends Composer<_$AppDatabase, $BlindTasteItemsTable> {
  $$BlindTasteItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aroma => $composableBuilder(
    column: $table.aroma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alcoholDegree => $composableBuilder(
    column: $table.alcoholDegree,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fermentationAgent => $composableBuilder(
    column: $table.fermentationAgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlindTasteItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $BlindTasteItemsTable> {
  $$BlindTasteItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aroma => $composableBuilder(
    column: $table.aroma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alcoholDegree => $composableBuilder(
    column: $table.alcoholDegree,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fermentationAgent => $composableBuilder(
    column: $table.fermentationAgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlindTasteItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlindTasteItemsTable> {
  $$BlindTasteItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get aroma =>
      $composableBuilder(column: $table.aroma, builder: (column) => column);

  GeneratedColumn<double> get alcoholDegree => $composableBuilder(
    column: $table.alcoholDegree,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get fermentationAgent => $composableBuilder(
    column: $table.fermentationAgent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BlindTasteItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlindTasteItemsTable,
          BlindTasteItem,
          $$BlindTasteItemsTableFilterComposer,
          $$BlindTasteItemsTableOrderingComposer,
          $$BlindTasteItemsTableAnnotationComposer,
          $$BlindTasteItemsTableCreateCompanionBuilder,
          $$BlindTasteItemsTableUpdateCompanionBuilder,
          (
            BlindTasteItem,
            BaseReferences<
              _$AppDatabase,
              $BlindTasteItemsTable,
              BlindTasteItem
            >,
          ),
          BlindTasteItem,
          PrefetchHooks Function()
        > {
  $$BlindTasteItemsTableTableManager(
    _$AppDatabase db,
    $BlindTasteItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlindTasteItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlindTasteItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlindTasteItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> aroma = const Value.absent(),
                Value<double> alcoholDegree = const Value.absent(),
                Value<double> totalScore = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<String> fermentationAgent = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BlindTasteItemsCompanion(
                id: id,
                name: name,
                aroma: aroma,
                alcoholDegree: alcoholDegree,
                totalScore: totalScore,
                equipment: equipment,
                fermentationAgent: fermentationAgent,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String aroma,
                required double alcoholDegree,
                required double totalScore,
                required String equipment,
                required String fermentationAgent,
                Value<DateTime> createdAt = const Value.absent(),
              }) => BlindTasteItemsCompanion.insert(
                id: id,
                name: name,
                aroma: aroma,
                alcoholDegree: alcoholDegree,
                totalScore: totalScore,
                equipment: equipment,
                fermentationAgent: fermentationAgent,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlindTasteItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlindTasteItemsTable,
      BlindTasteItem,
      $$BlindTasteItemsTableFilterComposer,
      $$BlindTasteItemsTableOrderingComposer,
      $$BlindTasteItemsTableAnnotationComposer,
      $$BlindTasteItemsTableCreateCompanionBuilder,
      $$BlindTasteItemsTableUpdateCompanionBuilder,
      (
        BlindTasteItem,
        BaseReferences<_$AppDatabase, $BlindTasteItemsTable, BlindTasteItem>,
      ),
      BlindTasteItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$BlindTasteItemsTableTableManager get blindTasteItems =>
      $$BlindTasteItemsTableTableManager(_db, _db.blindTasteItems);
}
