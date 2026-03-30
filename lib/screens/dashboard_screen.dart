import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import '../screens/dashboard_customize_screen.dart';
import '../sheets/add_client_sheet.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/progress_bar.dart';
import '../widgets/section_label.dart';
import '../widgets/stat_card.dart';
import '../widgets/timer_display.dart';

String _categoryEmoji(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('web')) return '🌐';
  if (lower.contains('design') ||
      lower.contains('graphic') ||
      lower.contains('brand')) {
    return '🎨';
  }
  if (lower.contains('mobile') || lower.contains('app')) return '📱';
  if (lower.contains('video')) return '🎬';
  if (lower.contains('seo')) return '🔍';
  if (lower.contains('copy') || lower.contains('write')) return '✍️';
  if (lower.contains('photo')) return '📷';
  return '💼';
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenClient,
    required this.onOpenProject,
  });

  final ValueChanged<String> onOpenClient;
  final void Function(String clientId, String projectId) onOpenProject;

  @override
  Widget build(BuildContext context) {
    final sections = context.watch<SettingsProvider>().dashboardSections;
    final sectionWidgets = <Widget>[];
    for (final id in sections) {
      switch (id) {
        case 'active_projects':
          sectionWidgets.add(_buildActiveProjectsSection(context));
          break;
        case 'client_strip':
          sectionWidgets.add(_buildClientStripSection(context));
          break;
        case 'owed_timer':
          sectionWidgets.add(_buildOwedTimerSection(context));
          break;
        case 'mrr_collected':
          sectionWidgets.add(_buildMrrCollectedSection(context));
          break;
      }
    }

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              ...sectionWidgets,
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Consumer<SettingsProvider>(
              builder: (context, sp, _) {
                final name = sp.userName.isNotEmpty ? sp.userName : 'there';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting().toUpperCase(), style: kStyleLabel),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: kStyleHeading.copyWith(fontSize: 30),
                    ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Customize dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const DashboardCustomizeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 6),
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: ElevatedButton(
              onPressed: () => showAddClientSheet(context),
              child: const Text('+ Client'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProjectsSection(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final activeProjects = dataProvider.activeProjectsSorted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          SectionLabel(
            text: 'Active Projects',
            trailing:
                Text('${activeProjects.length} running', style: kStyleCaption),
          ),
          const SizedBox(height: 10),
          if (activeProjects.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Center(
                child: Text(
                  'No active projects · Add a client to get started',
                  style: kStyleBody.copyWith(color: kTextMuted),
                ),
              ),
            )
          else
            ...activeProjects.map((entry) {
              final project = entry.project;
              final client = entry.client;
              final urgency = urgencyFor(project.deadline);
              final dLeft = daysLeft(project.deadline);
              final pct =
                  progressPct(project.loggedHours, project.estimatedHours);
              final strip = urgencyStripColor(urgency);

              return GestureDetector(
                onTap: () => onOpenProject(client.id, project.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration:
                      kCardDecoration(borderColor: urgencyBorderColor(urgency)),
                  child: Stack(
                    children: [
                      if (strip != null)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: strip,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18)),
                            ),
                          ),
                        ),
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(project.name, style: kStyleBodyBold),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        ClientAvatar(
                                            name: client.name,
                                            size: 20,
                                            radius: 5),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            client.name,
                                            style: kStyleCaption,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('•', style: kStyleCaption),
                                        const SizedBox(width: 6),
                                        Text(_categoryEmoji(project.category),
                                          style: kStyleCaption),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      urgencyColor(urgency).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        urgencyColor(urgency).withOpacity(0.30),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      dLeft < 0 ? '${dLeft.abs()}' : '$dLeft',
                                      style: kStyleBodyBold.copyWith(
                                        color: urgencyColor(urgency),
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      dLeft < 0 ? 'OVERDUE' : 'DAYS',
                                      style: kStyleCaption.copyWith(
                                        color: urgencyColor(urgency),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomProgressBar(value: pct / 100),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Logged ${project.loggedHours.toStringAsFixed(1)}h',
                                  style: kStyleCaption),
                              Text('$pct%', style: kStyleCaption),
                              Text(
                                project.remaining > 0
                                    ? 'Owed ${fmtCurrency(project.remaining, settings.currency)}'
                                    : '✓ Paid',
                                style: kStyleCaption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildClientStripSection(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Column(
      children: [
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SectionLabel(text: 'Clients'),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
            itemCount: dataProvider.sortedClients.length + 1,
            itemBuilder: (context, index) {
              if (index == dataProvider.sortedClients.length) {
                return GestureDetector(
                  onTap: () => showAddClientSheet(context),
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: kLime),
                        const SizedBox(height: 4),
                        Text('New',
                            style: kStyleCaption.copyWith(color: kLime)),
                      ],
                    ),
                  ),
                );
              }

              final client = dataProvider.sortedClients[index];
              final firstName = client.name.split(' ').first;

              return GestureDetector(
                onTap: () => onOpenClient(client.id),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: kCardDecoration(radius: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClientAvatar(name: client.name, size: 40, radius: 12),
                      const SizedBox(height: 6),
                      Text(firstName,
                          style: kStyleBodyBold,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${_categoryEmoji(client.primaryCategory)} ${client.primaryCategory}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kStyleCaption.copyWith(fontSize: 10),
                      ),
                      if (client.activeCount > 0)
                        Text(
                          '${client.activeCount} active',
                          style: kStyleCaption.copyWith(color: kGreen),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOwedTimerSection(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final settings = context.watch<SettingsProvider>().settings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Owed',
              value: fmtCurrency(dataProvider.totalOwed, settings.currency),
              valueColor: dataProvider.totalOwed > 0 ? kYellow : kGreen,
              backgroundTint: dataProvider.totalOwed > 0
                  ? kYellow.withOpacity(0.08)
                  : kGreen.withOpacity(0.08),
              borderColor: dataProvider.totalOwed > 0
                  ? kYellow.withOpacity(0.25)
                  : kGreen.withOpacity(0.20),
              subtitle: dataProvider.totalOwed > 0
                  ? 'across ${dataProvider.activeProjectsSorted.length} projects'
                  : 'all settled ✓',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: kCardDecoration(
                radius: 20,
                background:
                    timerProvider.isRunning ? kLime.withOpacity(0.15) : kBgCard,
                borderColor:
                    timerProvider.isRunning ? kLime.withOpacity(0.40) : kBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timerProvider.isRunning
                        ? 'Timer Running'.toUpperCase()
                        : 'Today'.toUpperCase(),
                    style: kStyleLabel,
                  ),
                  const SizedBox(height: 8),
                  if (timerProvider.isRunning)
                    TimerDisplay(
                      elapsedSeconds: timerProvider.elapsedSeconds,
                      style: kStyleTimer.copyWith(color: kBlack),
                    )
                  else
                    Text(
                      fmtDuration(dataProvider.todayMinutes),
                      style: kStyleHeadingSm.copyWith(fontSize: 22),
                    ),
                  const SizedBox(height: 4),
                  if (timerProvider.isRunning)
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          foregroundColor: kWhite,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () async {
                          final cId = timerProvider.activeClientId;
                          final pId = timerProvider.activeProjectId;
                          if (cId == null || pId == null) return;
                          final session = timerProvider.stopTimer();
                          await dataProvider.addSession(cId, pId, session);
                        },
                        child: const Text('Stop & Save'),
                      ),
                    )
                  else
                    Text('logged today', style: kStyleCaption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMrrCollectedSection(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final settings = context.watch<SettingsProvider>().settings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: kCardDecoration(
                radius: 20,
                background: kBlue.withOpacity(0.06),
                borderColor: kBlue.withOpacity(0.25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Recurring', style: kStyleCaption),
                  Text(
                    '${fmtCurrency(dataProvider.totalMrr, settings.currency)}/mo',
                    style: kStyleBodyBold.copyWith(color: kBlue),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: kCardDecoration(
                radius: 20,
                background: kGreen.withOpacity(0.06),
                borderColor: kGreen.withOpacity(0.25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Collected', style: kStyleCaption),
                  Text(
                    fmtCurrency(dataProvider.totalCollected, settings.currency),
                    style: kStyleBodyBold.copyWith(color: kGreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
