import 'package:flutter/material.dart';
import '../models/blind_taste_model.dart';
import '../utils/haptic_manager.dart';

/// 酒度选择组件
class AlcoholSectionWidget extends StatelessWidget {
  final double? selectedAlcoholDegree;
  final Function(double) onAlcoholChanged;
  final bool? lastResult;

  const AlcoholSectionWidget({
    super.key,
    required this.selectedAlcoholDegree,
    required this.onAlcoholChanged,
    this.lastResult,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '酒度',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (lastResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: lastResult!
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lastResult! ? '正确' : '错误',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 0),
            Wrap(
              spacing: 6,
              runSpacing: -6,
              children: BlindTasteOptions.alcoholDegrees.map((degree) {
                final isSelected = selectedAlcoholDegree == degree;
                return FilterChip(
                  label: Text('${degree.toInt()}°'),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticManager.medium();
                    onAlcoholChanged(degree);
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 总分调整组件
class TotalScoreSectionWidget extends StatelessWidget {
  final double selectedTotalScore;
  final Function(double) onScoreChanged;
  final bool? lastResult;

  const TotalScoreSectionWidget({
    super.key,
    required this.selectedTotalScore,
    required this.onScoreChanged,
    this.lastResult,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '总分',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (lastResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: lastResult!
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lastResult! ? '正确' : '错误',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 0),
            Row(
              children: [
                // 减分按钮
                IconButton(
                  onPressed: selectedTotalScore > 87.0
                      ? () {
                          HapticManager.medium();
                          final newScore = (selectedTotalScore - 0.2).clamp(
                            87.0,
                            95.0,
                          );
                          onScoreChanged(newScore);
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  selectedTotalScore.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Slider(
                    value: selectedTotalScore.clamp(87.0, 95.0),
                    min: 87.0,
                    max: 95.0,
                    divisions: 40, // (95.0 - 87.0) / 0.2 = 40 divisions
                    onChanged: (value) {
                      HapticManager.selection();
                      onScoreChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 2),
                // 加分按钮
                IconButton(
                  onPressed: selectedTotalScore < 95.0
                      ? () {
                          HapticManager.medium();
                          final newScore = (selectedTotalScore + 0.2).clamp(
                            87.0,
                            95.0,
                          );
                          onScoreChanged(newScore);
                        }
                      : null,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 设备选择组件
class EquipmentSectionWidget extends StatelessWidget {
  final List<String> selectedEquipment;
  final Function(String) onEquipmentToggled;
  final bool? lastResult;

  const EquipmentSectionWidget({
    super.key,
    required this.selectedEquipment,
    required this.onEquipmentToggled,
    this.lastResult,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '设备',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (lastResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: lastResult!
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lastResult! ? '正确' : '错误',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 0),
            Wrap(
              spacing: 6,
              runSpacing: -6,
              children: BlindTasteOptions.equipmentTypes.map((equipment) {
                final isSelected = selectedEquipment.contains(equipment);
                return FilterChip(
                  label: Text(equipment),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticManager.medium();
                    onEquipmentToggled(equipment);
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 发酵剂选择组件
class FermentationAgentSectionWidget extends StatelessWidget {
  final List<String> selectedFermentationAgent;
  final Function(String) onFermentationAgentToggled;
  final bool? lastResult;

  const FermentationAgentSectionWidget({
    super.key,
    required this.selectedFermentationAgent,
    required this.onFermentationAgentToggled,
    this.lastResult,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '发酵剂',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (lastResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: lastResult!
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lastResult! ? '正确' : '错误',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 0),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: BlindTasteOptions.fermentationAgents.map((agent) {
                final isSelected = selectedFermentationAgent.contains(agent);
                return FilterChip(
                  label: Text(agent),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticManager.medium();
                    onFermentationAgentToggled(agent);
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
