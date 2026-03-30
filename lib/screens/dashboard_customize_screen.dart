import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme.dart';
import '../widgets/section_label.dart';

class DashboardCustomizeScreen extends StatelessWidget {
  const DashboardCustomizeScreen({super.key});

  static const List<String> _allSections = [
    'active_projects',
    'client_strip',
    'owed_timer',
    'mrr_collected',
  ];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final enabled = settingsProvider.dashboardSections;
    final orderedSections = [
      ...enabled,
      ..._allSections.where((id) => !enabled.contains(id)),
    ];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Customize Dashboard'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(text: 'VISIBLE SECTIONS'),
              const SizedBox(height: 6),
              Text(
                'Drag to reorder. Tap toggle to show or hide.',
                style: kStyleBody,
              ),
              const SizedBox(height: 12),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: orderedSections.length,
                onReorder: (oldIndex, newIndex) async {
                  final moved = List<String>.from(orderedSections);
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = moved.removeAt(oldIndex);
                  moved.insert(newIndex, item);

                  final enabledSet = settingsProvider.dashboardSections.toSet();
                  final newEnabledOrder =
                      moved.where((id) => enabledSet.contains(id)).toList();
                  await settingsProvider.reorderSections(newEnabledOrder);
                },
                itemBuilder: (context, index) {
                  final sectionId = orderedSections[index];
                  return _SectionTile(
                    key: ValueKey(sectionId),
                    index: index,
                    sectionId: sectionId,
                    enabled: settingsProvider.isSectionEnabled(sectionId),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    super.key,
    required this.index,
    required this.sectionId,
    required this.enabled,
  });

  final int index;
  final String sectionId;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: kCardDecoration(radius: 16),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle_rounded, color: kTextMuted),
            ),
            const SizedBox(width: 8),
            Icon(_iconFor(sectionId), color: kTextSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _labelFor(sectionId),
                style: kStyleBodyBold,
              ),
            ),
            Switch(
              activeColor: kLime,
              value: enabled,
              onChanged: (_) async {
                final sections = settingsProvider.dashboardSections;
                if (enabled && sections.length == 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('At least one section must remain visible'),
                    ),
                  );
                  return;
                }
                await settingsProvider.toggleSection(sectionId);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String id) => switch (id) {
        'active_projects' => Icons.folder_open_rounded,
        'client_strip' => Icons.people_alt_rounded,
        'owed_timer' => Icons.account_balance_wallet_rounded,
        'mrr_collected' => Icons.bar_chart_rounded,
        _ => Icons.widgets_outlined,
      };

  String _labelFor(String id) => switch (id) {
        'active_projects' => 'Active Projects',
        'client_strip' => 'Client Overview',
        'owed_timer' => 'Money Owed & Today\'s Time',
        'mrr_collected' => 'Revenue Summary',
        _ => id,
      };
}
