import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';

Future<void> showAddProjectSheet(BuildContext context,
    {required String clientId}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddProjectSheetBody(clientId: clientId),
  );
}

class _AddProjectSheetBody extends StatefulWidget {
  const _AddProjectSheetBody({required this.clientId});

  final String clientId;

  @override
  State<_AddProjectSheetBody> createState() => _AddProjectSheetBodyState();
}

class _AddProjectSheetBodyState extends State<_AddProjectSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  final _fixedCtrl = TextEditingController();
  final _hourlyCtrl = TextEditingController();
  final _estCtrl = TextEditingController();
  final _upfrontCtrl = TextEditingController();
  final _remainingCtrl = TextEditingController();
  final _maintenanceCtrl = TextEditingController();
  final _servicesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _type = 'website';
  String _pricingType = 'fixed';
  bool _maintenanceActive = false;

  @override
  void initState() {
    super.initState();
    final hourly = context.read<SettingsProvider>().settings.hourlyRate;
    _hourlyCtrl.text = hourly.toStringAsFixed(0);
    _startCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _deadlineCtrl.dispose();
    _fixedCtrl.dispose();
    _hourlyCtrl.dispose();
    _estCtrl.dispose();
    _upfrontCtrl.dispose();
    _remainingCtrl.dispose();
    _maintenanceCtrl.dispose();
    _servicesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Add Project', style: kStyleHeadingSm),
                      const Spacer(),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close)),
                    ],
                  ),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'PROJECT NAME'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Project name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text('TYPE'.toUpperCase(), style: kStyleLabel),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'website', label: Text('🌐 Website')),
                      ButtonSegment(
                          value: 'graphic', label: Text('🎨 Graphic Design')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _startCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'START DATE', hintText: 'Select start date'),
                    onTap: () => _pickDate(_startCtrl),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _deadlineCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'DEADLINE', hintText: 'Select deadline'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Deadline is required'
                        : null,
                    onTap: () => _pickDate(_deadlineCtrl),
                  ),
                  const SizedBox(height: 12),
                  Text('PRICING'.toUpperCase(), style: kStyleLabel),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'fixed', label: Text('Fixed Price')),
                      ButtonSegment(
                          value: 'hourly', label: Text('Hourly Rate')),
                    ],
                    selected: {_pricingType},
                    onSelectionChanged: (s) =>
                        setState(() => _pricingType = s.first),
                  ),
                  const SizedBox(height: 10),
                  if (_pricingType == 'fixed')
                    TextFormField(
                      controller: _fixedCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'FIXED PRICE'),
                    )
                  else
                    TextFormField(
                      controller: _hourlyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'HOURLY RATE'),
                    ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _estCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'ESTIMATED HOURS'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _upfrontCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'UPFRONT PAID'),
                    onChanged: (_) => _autoFillRemaining(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _remainingCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'REMAINING'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _maintenanceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'MAINTENANCE /MO'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _maintenanceActive,
                        onChanged: (v) =>
                            setState(() => _maintenanceActive = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _servicesCtrl,
                    decoration: const InputDecoration(
                        labelText: 'SERVICES',
                        hintText: 'Logo Design, Brand Guide'),
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
                      child: const Text('Add Project'),
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

  void _autoFillRemaining() {
    if (_pricingType != 'fixed') return;
    final fixed = double.tryParse(_fixedCtrl.text.trim()) ?? 0;
    final upfront = double.tryParse(_upfrontCtrl.text.trim()) ?? 0;
    if (fixed > 0) {
      _remainingCtrl.text =
          (fixed - upfront).clamp(0, double.infinity).toStringAsFixed(0);
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    var selected = now;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: 320,
            height: 320,
            child: CalendarDatePicker(
              initialDate: now,
              firstDate: DateTime(now.year - 10),
              lastDate: DateTime(now.year + 10),
              onDateChanged: (d) => selected = d,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                ctrl.text = DateFormat('yyyy-MM-dd').format(selected);
                Navigator.pop(context);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final fixedPrice = double.tryParse(_fixedCtrl.text.trim()) ?? 0;
    final hourlyRate = double.tryParse(_hourlyCtrl.text.trim()) ?? 0;
    final estimated = double.tryParse(_estCtrl.text.trim()) ?? 0;
    final upfront = double.tryParse(_upfrontCtrl.text.trim()) ?? 0;
    final remaining = double.tryParse(_remainingCtrl.text.trim()) ?? 0;
    final maintenance = double.tryParse(_maintenanceCtrl.text.trim()) ?? 0;

    final project = Project()
      ..id = const Uuid().v4()
      ..name = _nameCtrl.text.trim()
      ..status = 'active'
      ..type = _type
      ..startDate = _startCtrl.text.trim()
      ..deadline = _deadlineCtrl.text.trim()
      ..pricingType = _pricingType
      ..fixedPrice = fixedPrice
      ..hourlyRate = hourlyRate
      ..estimatedHours = estimated
      ..loggedHours = 0
      ..upfront = upfront
      ..remaining = remaining
      ..maintenanceFee = maintenance
      ..maintenanceActive = _maintenanceActive
      ..services = _servicesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList()
      ..sessions = []
      ..notes = _notesCtrl.text.trim();

    await context.read<DataProvider>().addProject(widget.clientId, project);
    if (mounted) Navigator.pop(context);
  }
}
