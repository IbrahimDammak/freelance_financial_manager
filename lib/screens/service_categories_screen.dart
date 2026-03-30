import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/section_label.dart';

class ServiceCategoriesScreen extends StatefulWidget {
  const ServiceCategoriesScreen({super.key});

  @override
  State<ServiceCategoriesScreen> createState() =>
      _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState extends State<ServiceCategoriesScreen> {
  String? _editingName;
  final TextEditingController _renameCtrl = TextEditingController();

  @override
  void dispose() {
    _renameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final categories = settingsProvider.serviceCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Service Categories')),
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(text: 'YOUR CATEGORIES'),
              const SizedBox(height: 4),
              Text(
                'These appear when adding clients and projects.',
                style: kStyleCaption,
              ),
              const SizedBox(height: 12),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                onReorder: (oldIndex, newIndex) =>
                    _reorderCategory(context, categories, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final editing = _editingName == category;
                  return Container(
                    key: ValueKey(category),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: kCardDecoration(radius: 16),
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle_rounded),
                      ),
                      title: editing
                          ? TextField(
                              controller: _renameCtrl,
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                              onSubmitted: (_) =>
                                  _confirmRename(context, category),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Rename category',
                              ),
                            )
                          : Text(category, style: kStyleBodyBold),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: editing
                            ? [
                                IconButton(
                                  onPressed: () =>
                                      _confirmRename(context, category),
                                  icon: const Icon(Icons.check_rounded),
                                ),
                                IconButton(
                                  onPressed: _cancelRename,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ]
                            : [
                                IconButton(
                                  onPressed: () => _startRename(category),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _confirmDelete(context, category),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add New Category'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kBlack,
                  side: const BorderSide(color: kLime, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reorderCategory(
    BuildContext context,
    List<String> categories,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = [...categories];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    await context.read<SettingsProvider>().reorderServiceCategories(reordered);
  }

  void _startRename(String category) {
    setState(() {
      _editingName = category;
      _renameCtrl.text = category;
    });
  }

  void _cancelRename() {
    setState(() {
      _editingName = null;
      _renameCtrl.clear();
    });
  }

  Future<void> _confirmRename(BuildContext context, String oldName) async {
    final newName = _renameCtrl.text.trim();
    if (newName.isNotEmpty) {
      await context.read<SettingsProvider>().renameServiceCategory(
            oldName,
            newName,
          );
    }
    _cancelRename();
  }

  Future<void> _confirmDelete(BuildContext context, String name) async {
    final provider = context.read<SettingsProvider>();
    if (provider.serviceCategories.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must have at least one service category.')),
      );
      return;
    }

    await showConfirmDialog(
      context,
      title: 'Delete category?',
      message: 'This removes "$name" from your service categories list.',
      confirmLabel: 'Delete',
      confirmColor: kRed,
      onConfirm: () async {
        await context.read<SettingsProvider>().removeServiceCategory(name);
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('New Category'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Motion Design'),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) async {
              await settingsProvider.addServiceCategory(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await settingsProvider.addServiceCategory(ctrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
