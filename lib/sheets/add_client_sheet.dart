import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/client.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/category_selector.dart';
import '../widgets/section_label.dart';

Future<void> showAddClientSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddClientSheetBody(),
  );
}

class _AddClientSheetBody extends StatefulWidget {
  const _AddClientSheetBody();

  @override
  State<_AddClientSheetBody> createState() => _AddClientSheetBodyState();
}

class _AddClientSheetBodyState extends State<_AddClientSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final categories = settingsProvider.serviceCategories;
    _selectedCategory ??= categories.first;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(bottom: insets),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
                bottom: insets + 24, left: 20, right: 20, top: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kBorder,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Add Client', style: kStyleHeadingSm),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'FULL NAME'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _companyCtrl,
                    decoration: const InputDecoration(labelText: 'COMPANY'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'EMAIL'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'PHONE'),
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel(text: 'Primary Service *'),
                  const SizedBox(height: 8),
                  CategorySelector(
                    categories: categories,
                    selected: _selectedCategory,
                    onSelected: (cat) =>
                        setState(() => _selectedCategory = cat),
                    onAddCustom: (newCat) async {
                      await settingsProvider.addServiceCategory(newCat);
                      if (!mounted) return;
                      setState(() => _selectedCategory = newCat);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'NOTES'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Add Client'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();

    final client = Client()
      ..id = const Uuid().v4()
      ..name = name
      ..company = _companyCtrl.text.trim()
      ..email = _emailCtrl.text.trim()
      ..phone = _phoneCtrl.text.trim()
      ..primaryCategory = _selectedCategory ?? 'Web Development'
      ..avatar = initialsFrom(name)
      ..createdAt = todayStr()
      ..notes = _notesCtrl.text.trim()
      ..projects = [];

    await context.read<DataProvider>().addClient(client);
    if (mounted) Navigator.pop(context);
  }
}
