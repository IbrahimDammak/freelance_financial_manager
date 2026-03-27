import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/work_session.dart';
import '../providers/data_provider.dart';
import '../theme.dart';

Future<void> showLogSessionSheet(
  BuildContext context, {
  required String clientId,
  required String projectId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _LogSessionSheetBody(clientId: clientId, projectId: projectId),
  );
}

class _LogSessionSheetBody extends StatefulWidget {
  const _LogSessionSheetBody({required this.clientId, required this.projectId});

  final String clientId;
  final String projectId;

  @override
  State<_LogSessionSheetBody> createState() => _LogSessionSheetBodyState();
}

class _LogSessionSheetBodyState extends State<_LogSessionSheetBody> {
  final _dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _hoursCtrl = TextEditingController(text: '0');
  final _minsCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  String? _timeError;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _hoursCtrl.dispose();
    _minsCtrl.dispose();
    _noteCtrl.dispose();
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
            child: Column(
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
                    Text('Log Session', style: kStyleHeadingSm),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'DATE'),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _hoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'HOURS'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _minsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'MINUTES'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'NOTE'),
                ),
                if (_timeError != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_timeError!,
                        style: kStyleCaption.copyWith(color: kRed)),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Log Session'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    var selected = now;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 320,
          height: 320,
          child: CalendarDatePicker(
            initialDate: now,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 5),
            onDateChanged: (d) => selected = d,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _dateCtrl.text = DateFormat('yyyy-MM-dd').format(selected);
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final hours = int.tryParse(_hoursCtrl.text.trim()) ?? 0;
    final mins = int.tryParse(_minsCtrl.text.trim()) ?? 0;
    final total = (hours * 60) + mins;
    if (total <= 0) {
      setState(() => _timeError = 'Hours + minutes must be greater than 0');
      return;
    }

    final session = WorkSession()
      ..id = const Uuid().v4()
      ..date = _dateCtrl.text.trim()
      ..durationMins = total
      ..note = _noteCtrl.text.trim().isEmpty
          ? 'Manual session'
          : _noteCtrl.text.trim();

    await context
        .read<DataProvider>()
        .addSession(widget.clientId, widget.projectId, session);
    if (mounted) Navigator.pop(context);
  }
}
