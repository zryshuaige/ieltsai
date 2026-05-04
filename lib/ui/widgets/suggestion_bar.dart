import 'package:flutter/material.dart';
import 'package:ieltsai/ui/widgets/glass_panel.dart';

class SuggestionBar extends StatelessWidget {
  const SuggestionBar({
    super.key,
    required this.suggestions,
    required this.selectedIndex,
    required this.streaming,
    required this.onAccept,
    required this.onAcceptWord,
    required this.onDismiss,
    required this.onRegenerate,
    required this.onSelectIndex,
  });

  final List<String> suggestions;
  final int selectedIndex;
  final bool streaming;
  final VoidCallback onAccept;
  final VoidCallback onAcceptWord;
  final VoidCallback onDismiss;
  final VoidCallback onRegenerate;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSuggestion = suggestions.isNotEmpty;
    if (!hasSuggestion) {
      return GlassPanel(
        radius: 22,
        child: SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: Color(0xFF5E7BFF),
              ),
              const SizedBox(width: 8),
              Text(
                'No suggestion • Ctrl+R 手动生成',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = selectedIndex.clamp(0, suggestions.length - 1);
    return GlassPanel(
      radius: 22,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  streaming ? Icons.bolt : Icons.auto_awesome_rounded,
                  size: 18,
                  color: const Color(0xFF4F69F0),
                ),
                const SizedBox(width: 8),
                Text(
                  streaming ? 'AI 正在补全...' : 'AI 双建议（Tab 采纳最佳，↑/↓切换）',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(suggestions.length, (index) {
              final isSelected = index == safeIndex;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == suggestions.length - 1 ? 0 : 8,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelectIndex(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isSelected
                          ? const Color(0xFF6C86FF).withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.45),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5A74F4).withValues(alpha: 0.75)
                            : const Color(0xFF9FB0ED).withValues(alpha: 0.45),
                        width: isSelected ? 1.2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          index == 0 ? '最佳建议' : '次优建议',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? const Color(0xFF3F56C4)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestions[index],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.92,
                            ),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.keyboard_tab, size: 16),
                  label: const Text('接受当前建议 (Tab)'),
                ),
                FilledButton.tonal(
                  onPressed: onAcceptWord,
                  child: const Text('接受一个词 (Ctrl+→)'),
                ),
                TextButton(
                  onPressed: onRegenerate,
                  child: const Text('换一个 (Ctrl+R)'),
                ),
                TextButton(onPressed: onDismiss, child: const Text('忽略 (Esc)')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
