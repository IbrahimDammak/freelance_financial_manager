import 'package:flutter/material.dart';

import '../theme.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.onAddCustom,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onAddCustom;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  bool _addingCustom = false;
  final TextEditingController _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.categories.map(_buildCategoryChip),
            _buildCustomChip(),
          ],
        ),
        if (_addingCustom) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter custom category',
                  ),
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: (_) => _submitCustom(),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _submitCustom,
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    final selected = widget.selected == category;
    return GestureDetector(
      onTap: () => widget.onSelected(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kBlack : kBgCardAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : kBorder),
        ),
        child: Text(
          category,
          style: kStyleCaption.copyWith(
            color: selected ? kWhite : kTextSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomChip() {
    return GestureDetector(
      onTap: () => setState(() => _addingCustom = !_addingCustom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kLime.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kLime),
        ),
        child: Text(
          '+ Custom',
          style: kStyleCaption.copyWith(
            color: kBlack,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _submitCustom() {
    final value = _customCtrl.text.trim();
    if (value.isEmpty) return;
    widget.onAddCustom(value);
    widget.onSelected(value);
    _customCtrl.clear();
    setState(() => _addingCustom = false);
  }
}
