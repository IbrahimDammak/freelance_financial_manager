import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import '../sheets/log_session_sheet.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/progress_bar.dart';
import '../widgets/section_label.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/timer_display.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({
    super.key,
    required this.clientId,
    required this.projectId,
  });

  final String clientId;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final client = dataProvider.findClient(clientId);

    Project? project;
    if (client != null) {
      for (final p in client.projects) {
        if (p.id == projectId) {
          project = p;
          break;
        }
      }
    }

    if (client == null || project == null) {
      return const Scaffold(body: Center(child: Text('Project not found')));
    }
    final currentProject = project;

    final isOwnRunning = timerProvider.isRunning &&
        timerProvider.isTimerForProject(currentProject.id);
    final isOtherRunning = timerProvider.isRunning &&
        !timerProvider.isTimerForProject(currentProject.id);
    final pct =
        progressPct(currentProject.loggedHours, currentProject.estimatedHours);
    final urgency = urgencyFor(currentProject.deadline);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentProject.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: StatusBadge(status: currentProject.status)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _timeTrackerCard(
                context,
                currentProject,
                timerProvider,
                dataProvider,
                isOwnRunning,
                isOtherRunning,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: kCardDecoration(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 2.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        StatCard(
                          label: 'Project Value',
                          value: fmtCurrency(
                              currentProject.totalValue, settings.currency),
                          valueColor: kLime,
                        ),
                        StatCard(
                          label: 'Upfront Paid',
                          value: fmtCurrency(
                              currentProject.upfront, settings.currency),
                          valueColor: kGreen,
                        ),
                        StatCard(
                          label: 'Remaining',
                          value: fmtCurrency(
                              currentProject.remaining, settings.currency),
                          valueColor: kYellow,
                        ),
                        StatCard(
                          label: 'Maintenance',
                          value: currentProject.maintenanceActive
                              ? fmtCurrency(currentProject.maintenanceFee,
                                  settings.currency)
                              : '—',
                          valueColor: kBlue,
                        ),
                      ],
                    ),
                    if (currentProject.pricingType == 'hourly') ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kLime.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kLime.withOpacity(0.25)),
                        ),
                        child: Text(
                          '@ ${fmtCurrency(currentProject.hourlyRate, settings.currency)}/hr · Est. max: ${fmtCurrency(currentProject.estimatedHours * currentProject.hourlyRate, settings.currency)}',
                          style: kStyleCaption.copyWith(color: kLime),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: kCardDecoration(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SectionLabel(
                      text: 'PROGRESS',
                      trailing: Text(
                        '${daysLeft(currentProject.deadline)} days',
                        style: kStyleCaption.copyWith(
                            color: urgencyColor(urgency)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomProgressBar(value: pct / 100, height: 8),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Logged ${currentProject.loggedHours.toStringAsFixed(1)}h',
                            style: kStyleCaption),
                        Text('$pct%', style: kStyleCaption),
                        Text(
                            'Estimated ${currentProject.estimatedHours.toStringAsFixed(1)}h',
                            style: kStyleCaption),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: kCardDecoration(),
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentProject.services
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: kLime.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kLime.withOpacity(0.20)),
                          ),
                          child: Text(s,
                              style: kStyleCaption.copyWith(color: kLime)),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: kCardDecoration(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                            child: SectionLabel(text: 'Work Sessions')),
                        TextButton(
                          onPressed: () => showLogSessionSheet(
                            context,
                            clientId: client.id,
                            projectId: currentProject.id,
                          ),
                          child: const Text('+ Manual'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentProject.sessions.length > 5
                          ? 5
                          : currentProject.sessions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: kBorder),
                      itemBuilder: (context, index) {
                        final reversed =
                            currentProject.sessions.reversed.toList();
                        final s = reversed[index];
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.note, style: kStyleBodyBold),
                                  Text(s.date, style: kStyleCaption),
                                ],
                              ),
                            ),
                            Text(fmtDuration(s.durationMins),
                                style: kStyleBodyBold.copyWith(color: kBlue)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (currentProject.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: kCardDecoration(),
                  padding: const EdgeInsets.all(12),
                  child: Text(currentProject.notes, style: kStyleBody),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (currentProject.status != 'completed')
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kGreen),
                          foregroundColor: kGreen,
                        ),
                        onPressed: () async {
                          await showConfirmDialog(
                            context,
                            title: 'Mark as complete?',
                            message:
                                "This will set '${currentProject.name}' to completed. You can still view it in the client profile.",
                            confirmLabel: 'Mark complete',
                            confirmColor: kGreen,
                            onConfirm: () async {
                              await dataProvider.updateProjectStatus(
                                  client.id, currentProject.id, 'completed');
                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                        child: const Text('✓ Mark Complete'),
                      ),
                    ),
                  if (currentProject.status != 'completed')
                    const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kRed),
                      foregroundColor: kRed,
                    ),
                    onPressed: () async {
                      await showConfirmDialog(
                        context,
                        title: 'Delete project?',
                        message:
                            "All sessions and financial data for '${currentProject.name}' will be permanently deleted.",
                        confirmLabel: 'Delete',
                        confirmColor: kRed,
                        onConfirm: () async {
                          await dataProvider.deleteProject(
                              client.id, currentProject.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                    child: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeTrackerCard(
    BuildContext context,
    Project project,
    TimerProvider timerProvider,
    DataProvider dataProvider,
    bool isOwnRunning,
    bool isOtherRunning,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: kCardDecoration(
        borderColor: isOwnRunning ? kGreen.withOpacity(0.3) : kBorder,
        background: isOwnRunning ? kGreen.withOpacity(0.06) : kBgCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOwnRunning ? '⏱ RUNNING' : 'TIME TRACKER',
            style:
                kStyleLabel.copyWith(color: isOwnRunning ? kGreen : kTextMuted),
          ),
          const SizedBox(height: 8),
          if (isOwnRunning)
            TimerDisplay(elapsedSeconds: timerProvider.elapsedSeconds)
          else
            Text(
              fmtDuration((project.loggedHours * 60).round()),
              style: kStyleHeadingSm.copyWith(fontSize: 24),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isOwnRunning ? kRed : kBlack,
              foregroundColor: kWhite,
            ),
            onPressed: () async {
              if (isOwnRunning) {
                final cId = timerProvider.activeClientId;
                final pId = timerProvider.activeProjectId;
                if (cId == null || pId == null) return;
                final session = timerProvider.stopTimer();
                await dataProvider.addSession(cId, pId, session);
                return;
              }

              if (isOtherRunning) {
                try {
                  timerProvider.startTimer('', project.id, project.name);
                } on TimerConflictException catch (e) {
                  await showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Timer already running'),
                        content: Text(
                          'A timer is already running on "${e.projectName}". Stop it first?',
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kOrange, foregroundColor: kBg),
                            onPressed: () async {
                              final oldClientId = timerProvider.activeClientId;
                              final oldProjectId =
                                  timerProvider.activeProjectId;
                              if (oldClientId != null && oldProjectId != null) {
                                final oldSession = timerProvider.stopTimer();
                                await dataProvider.addSession(
                                    oldClientId, oldProjectId, oldSession);
                              } else {
                                timerProvider.discardTimer();
                              }
                              timerProvider.startTimer(
                                  clientId, project.id, project.name);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text('Stop & Switch'),
                          ),
                        ],
                      );
                    },
                  );
                }
                return;
              }

              timerProvider.startTimer(clientId, project.id, project.name);
            },
            child: Text(isOwnRunning ? 'Stop & Save' : '▶ Start'),
          ),
        ],
      ),
    );
  }
}
