import 'package:flutter/material.dart';

/// 主题预览页面 - 用于展示新的MD3配色体系
class ThemePreviewPage extends StatelessWidget {
  const ThemePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('MD3 主题预览'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 颜色调色板展示
            _buildColorPalette(context, colorScheme),
            
            const SizedBox(height: 24),
            
            // 组件展示
            _buildComponentShowcase(context),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPalette(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '配色调色板',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorChip('Primary', colorScheme.primary, colorScheme.onPrimary),
                _buildColorChip('Primary Container', colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
                _buildColorChip('Secondary', colorScheme.secondary, colorScheme.onSecondary),
                _buildColorChip('Secondary Container', colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                _buildColorChip('Tertiary', colorScheme.tertiary, colorScheme.onTertiary),
                _buildColorChip('Surface', colorScheme.surface, colorScheme.onSurface),
                _buildColorChip('Surface Container', colorScheme.surfaceContainer, colorScheme.onSurface),
                _buildColorChip('Error', colorScheme.error, colorScheme.onError),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(String label, Color backgroundColor, Color textColor) {
    return Container(
      width: 120,
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildComponentShowcase(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '组件展示',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        // 按钮展示
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('按钮', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Elevated Button'),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Outlined Button'),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Text Button'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 输入框展示
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('输入框', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                const TextField(
                  decoration: InputDecoration(
                    labelText: '标签文本',
                    hintText: '提示文本',
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chip展示
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chips', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('未选中'),
                      selected: false,
                      onSelected: (_) {},
                    ),
                    FilterChip(
                      label: const Text('已选中'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                    const Chip(
                      label: Text('普通 Chip'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
