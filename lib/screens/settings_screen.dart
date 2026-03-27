import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../widgets/section_label.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hourlyCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _hourlyCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    if (_hourlyCtrl.text.isEmpty) {
      _hourlyCtrl.text = provider.settings.hourlyRate.toStringAsFixed(0);
    }

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(text: 'PREFERENCES'),
              const SizedBox(height: 4),
              Text('Settings', style: kStyleHeading),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: kCardDecoration(radius: 20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _hourlyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'HOURLY RATE'),
                      onChanged: (value) {
                        _debounce?.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 500), () async {
                          final rate = double.tryParse(value.trim());
                          if (rate != null) {
                            await context
                                .read<SettingsProvider>()
                                .updateHourlyRate(rate);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: provider.settings.currency,
                      decoration: const InputDecoration(labelText: 'CURRENCY'),
                      items: AppSettings.supportedCurrencies
                          .map(
                            (currency) => DropdownMenuItem<String>(
                              value: currency,
                              child: Text(
                                currency == 'TND'
                                    ? 'TND — Tunisian Dinar (DT)'
                                    : currency,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          context
                              .read<SettingsProvider>()
                              .updateCurrency(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Text(
                      'FreelanceHub · All data stored locally on your device',
                      style: kStyleCaption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text('v1.0.0', style: kStyleCaption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
