import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../theme.dart';
import '../widgets/section_label.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isLoading = false;
  String _buttonLabel = 'Download Excel File';

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final clients = dataProvider.clients;

    final totalProjects =
        clients.fold<int>(0, (sum, client) => sum + client.projects.length);
    final totalSessions = clients.fold<int>(
      0,
      (sum, client) =>
          sum + client.projects.fold<int>(0, (s, p) => s + p.sessions.length),
    );

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('Export Data')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: kCardDecoration(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SectionLabel(text: 'WHAT GETS EXPORTED'),
                    const SizedBox(height: 12),
                    _ExportStat(
                      icon: Icons.people_alt_rounded,
                      label: 'Clients',
                      value: '${clients.length}',
                    ),
                    _ExportStat(
                      icon: Icons.folder_open_rounded,
                      label: 'Projects',
                      value: '$totalProjects',
                    ),
                    _ExportStat(
                      icon: Icons.timer_outlined,
                      label: 'Work Sessions',
                      value: '$totalSessions',
                    ),
                    const _ExportStat(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Financial Records',
                      value: 'Full breakdown',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: kCardDecoration(),
                padding: const EdgeInsets.all(20),
                child: const Column(
                  children: [
                    SectionLabel(text: 'EXCEL SHEETS INCLUDED'),
                    SizedBox(height: 12),
                    _SheetPreviewTile(
                      number: '1',
                      name: 'Summary',
                      desc: 'KPIs, totals, export metadata',
                    ),
                    _SheetPreviewTile(
                      number: '2',
                      name: 'Clients',
                      desc: 'All client contact and profile info',
                    ),
                    _SheetPreviewTile(
                      number: '3',
                      name: 'Projects',
                      desc: 'All projects with financial details',
                    ),
                    _SheetPreviewTile(
                      number: '4',
                      name: 'Work Sessions',
                      desc: 'Every logged session with duration',
                    ),
                    _SheetPreviewTile(
                      number: '5',
                      name: 'Financial',
                      desc: 'Per-client revenue breakdown plus totals',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleExport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: kWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _buttonLabel,
                    style: kStyleBodyBold.copyWith(
                      color: _buttonLabel.contains('failed') ? kRed : kWhite,
                    ),
                  ),
                ),
              ),
              if (settingsProvider.lastExportDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text(
                      'Last exported: ${DateFormat('MMM d, yyyy - HH:mm').format(settingsProvider.lastExportDate!)}',
                      style: kStyleCaption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() {
      _isLoading = true;
      _buttonLabel = 'Generating...';
    });

    try {
      final dataProvider = context.read<DataProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      final file = await ExportService().exportAllData(
        clients: dataProvider.clients,
        currency: settingsProvider.settings.currency,
        userName: settingsProvider.userName,
      );

      await settingsProvider.updateLastExportDate(DateTime.now());

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          )
        ],
        subject: 'FreelanceHub Export',
        text:
            'My FreelanceHub data export - ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _buttonLabel = 'File Ready';
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        _buttonLabel = 'Download Excel File';
      });
    } on ExportException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _buttonLabel = 'Export failed - Try again';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export error: ${e.message}'),
          backgroundColor: kRed,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _buttonLabel = 'Export failed - Try again';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error. Please try again.'),
          backgroundColor: kRed,
        ),
      );
    }
  }
}

class _ExportStat extends StatelessWidget {
  const _ExportStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: kTextSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: kStyleBody)),
          Text(value, style: kStyleBodyBold),
        ],
      ),
    );
  }
}

class _SheetPreviewTile extends StatelessWidget {
  const _SheetPreviewTile({
    required this.number,
    required this.name,
    required this.desc,
  });

  final String number;
  final String name;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: kLime.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: kLime.withOpacity(0.35)),
            ),
            alignment: Alignment.center,
            child: Text(number, style: kStyleCaption.copyWith(color: kBlack)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: kStyleBodyBold),
                const SizedBox(height: 2),
                Text(desc, style: kStyleCaption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
