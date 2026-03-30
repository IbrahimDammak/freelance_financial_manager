import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../theme.dart';
import '../utils.dart';

class RecordPaymentSheet extends StatefulWidget {
  const RecordPaymentSheet({
    super.key,
    required this.clientId,
    required this.projectId,
    required this.projectName,
    required this.currentRemaining,
    required this.currency,
  });

  final String clientId;
  final String projectId;
  final String projectName;
  final double currentRemaining;
  final String currency;

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final projectedRemaining =
        (widget.currentRemaining - amount).clamp(0.0, double.infinity);
    final overpay = amount > widget.currentRemaining;
    final previewColor = overpay
        ? kRed
        : (projectedRemaining == 0 ? kGreen : kYellow);

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
              left: 20,
              right: 20,
              top: 12,
              bottom: insets + 24,
            ),
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
                      Text('Record Payment', style: kStyleHeadingSm),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    widget.projectName,
                    style: kStyleCaption,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text('Currently owed', style: kStyleCaption),
                  const SizedBox(height: 2),
                  Text(
                    fmtCurrency(widget.currentRemaining, widget.currency),
                    style: kStyleHeadingSm.copyWith(
                      color: widget.currentRemaining > 0 ? kYellow : kGreen,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'AMOUNT RECEIVED *',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null) return 'Enter a valid amount';
                      if (parsed <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  ActionChip(
                    label: const Text('Pay in full'),
                    onPressed: () {
                      _amountController.text =
                          widget.currentRemaining.toStringAsFixed(3);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'DATE *'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Date is required'
                        : null,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'NOTE (OPTIONAL)',
                      hintText: 'e.g. Bank transfer, Cash, Cheque',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: kCardDecoration(
                      radius: 14,
                      borderColor: previewColor.withOpacity(0.35),
                      background: previewColor.withOpacity(0.08),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('After this payment:', style: kStyleCaption),
                        const SizedBox(height: 4),
                        Text(
                          'Remaining: ${fmtCurrency(projectedRemaining, widget.currency)}',
                          style: kStyleBodyBold.copyWith(color: previewColor),
                        ),
                        if (overpay)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Amount exceeds remaining balance. Extra will be recorded as advance payment.',
                              style: kStyleCaption.copyWith(color: kRed),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlack,
                        foregroundColor: kWhite,
                      ),
                      onPressed: _submit,
                      child: const Text('Record Payment'),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dateController.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    await context.read<DataProvider>().recordPayment(
          clientId: widget.clientId,
          projectId: widget.projectId,
          amount: amount,
          date: _dateController.text.trim(),
          note: _noteController.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }
}
