import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import 'service_categories_screen.dart';
import 'dashboard_customize_screen.dart';
import 'export_screen.dart';
import 'notification_settings_screen.dart';
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
              const SectionLabel(text: 'DATA'),
              Container(
                decoration: kCardDecoration(radius: 20),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download_rounded,
                          color: kTextSecondary),
                      title: Text('Export Data', style: kStyleBodyBold),
                      subtitle: Text(
                        'Download all data as Excel (.xlsx)',
                        style: kStyleBody,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: kTextMuted),
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute<void>(
                          builder: (_) => const ExportScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const SectionLabel(text: 'YOUR SERVICES'),
              Container(
                decoration: kCardDecoration(radius: 20),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_rounded,
                          color: kTextSecondary),
                      title: Text('Service Categories', style: kStyleBodyBold),
                      subtitle: Text(
                        'Manage the types of work you offer',
                        style: kStyleBody,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: kTextMuted),
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute<void>(
                          builder: (_) => const ServiceCategoriesScreen(),
                        ),
                      ),
                    ),
                    const Divider(color: kBorder, height: 1),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const SectionLabel(text: 'DASHBOARD'),
              Container(
                decoration: kCardDecoration(radius: 20),
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.tune_rounded, color: kTextSecondary),
                      title: Text('Customize Dashboard', style: kStyleBodyBold),
                      subtitle: Text(
                        'Reorder and show/hide sections',
                        style: kStyleBody,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: kTextMuted),
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute<void>(
                          builder: (_) => const DashboardCustomizeScreen(),
                        ),
                      ),
                    ),
                    const Divider(color: kBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined,
                          color: kTextSecondary),
                      title: Text('Notifications', style: kStyleBodyBold),
                      subtitle: Text(
                        'Deadlines and payment reminders',
                        style: kStyleBody,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: kTextMuted),
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute<void>(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
