import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../sheets/add_project_sheet.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/progress_bar.dart';
import '../widgets/section_label.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final client = dataProvider.findClient(clientId);

    if (client == null) {
      return const Scaffold(body: Center(child: Text('Client not found')));
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('Client Profile'), leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: kCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClientAvatar(name: client.name, size: 64, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(client.name, style: kStyleHeadingSm),
                              if (client.company.trim().isNotEmpty)
                                Text(client.company, style: kStyleBody),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      (client.type == 'website' ? kBlue : kPink)
                                          .withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (client.type == 'website'
                                            ? kBlue
                                            : kPink)
                                        .withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  client.type == 'website'
                                      ? '🌐 WEBSITE'
                                      : '🎨 GRAPHIC DESIGN',
                                  style: kStyleCaption.copyWith(
                                    color: client.type == 'website'
                                        ? kBlue
                                        : kPink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (client.email.trim().isNotEmpty)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.email_outlined, color: kTextMuted),
                        title: Text(client.email, style: kStyleBody),
                        onTap: () =>
                            launchUrl(Uri.parse('mailto:${client.email}')),
                      ),
                    if (client.phone.trim().isNotEmpty)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.phone_outlined, color: kTextMuted),
                        title: Text(client.phone, style: kStyleBody),
                        onTap: () =>
                            launchUrl(Uri.parse('tel:${client.phone}')),
                      ),
                    if (client.notes.trim().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBgCardAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder),
                        ),
                        child: Text('“${client.notes}”',
                            style: kStyleBody.copyWith(
                                fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Paid',
                      value: fmtCurrency(client.totalPaid, settings.currency),
                      valueColor: kGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: 'Owed',
                      value: fmtCurrency(client.totalOwed, settings.currency),
                      valueColor: kYellow,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: 'Hours',
                      value: fmtDuration(client.totalMins),
                      valueColor: kBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: SectionLabel(text: 'Projects')),
                  TextButton(
                    onPressed: () =>
                        showAddProjectSheet(context, clientId: client.id),
                    child: const Text('+ Add'),
                  ),
                ],
              ),
              if (client.projects.isEmpty)
                Container(
                  width: double.infinity,
                  decoration: kCardDecoration(radius: 20),
                  child: EmptyState(
                    icon: Icons.folder_outlined,
                    message: 'No projects yet',
                    actionLabel: '+ Add project',
                    onAction: () =>
                        showAddProjectSheet(context, clientId: client.id),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: client.projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final project = client.projects[index];
                    final pct = progressPct(
                        project.loggedHours, project.estimatedHours);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        splashColor: kLime.withOpacity(0.10),
                        highlightColor: kLime.withOpacity(0.05),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/project',
                            arguments: {
                              'clientId': client.id,
                              'projectId': project.id
                            },
                          );
                        },
                        child: Container(
                          decoration: kCardDecoration(radius: 20),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(project.name,
                                          style: kStyleBodyBold)),
                                  StatusBadge(status: project.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomProgressBar(value: pct / 100),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${project.loggedHours.toStringAsFixed(1)}h / ${project.estimatedHours.toStringAsFixed(1)}h',
                                    style: kStyleCaption,
                                  ),
                                  Text(
                                      fmtCurrency(project.totalValue,
                                          settings.currency),
                                      style: kStyleBodyBold),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
