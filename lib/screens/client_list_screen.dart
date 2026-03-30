import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../sheets/add_client_sheet.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_label.dart';

Color _categoryColor(String category) {
  const colors = [
    kBlue,
    kPink,
    kGreen,
    kOrange,
    kYellow,
    Color(0xFF8b5cf6),
    Color(0xFF06b6d4),
  ];
  return colors[category.hashCode.abs() % colors.length];
}

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final currency = context.watch<SettingsProvider>().settings.currency;
    _showErrorSnackIfNeeded(context, dataProvider);

    final clients = dataProvider.sortedClients;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel(text: 'DIRECTORY'),
                        const SizedBox(height: 4),
                        Text('Clients', style: kStyleHeading),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    child: ElevatedButton(
                      onPressed: () => showAddClientSheet(context),
                      child: const Text('+ New'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: clients.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.people_outline,
                          message:
                              'No clients yet · Tap + to add your first client',
                          actionLabel: '+ Add client',
                          onAction: () => showAddClientSheet(context),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Slidable(
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (_) =>
                                        _confirmDeleteClient(context, client),
                                    backgroundColor: kRed,
                                    icon: Icons.delete_outline,
                                    label: 'Delete',
                                  ),
                                ],
                              ),
                              child: _ClientListCard(
                                client: client,
                                currency: currency,
                                onTap: () {
                                  Navigator.of(context).pushNamed('/client',
                                      arguments: client.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackIfNeeded(BuildContext context, DataProvider provider) {
    if (!provider.hasError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => context.read<DataProvider>().reload(),
          ),
        ),
      );
    });
  }

  Future<void> _confirmDeleteClient(BuildContext context, Client client) async {
    await showConfirmDialog(
      context,
      title: 'Delete client?',
      message:
          'This will remove ${client.name} and all their projects and sessions.',
      confirmLabel: 'Delete',
      confirmColor: kRed,
      onConfirm: () async {
        await context.read<DataProvider>().deleteClient(client.id);
      },
    );
  }
}

class _ClientListCard extends StatelessWidget {
  const _ClientListCard(
      {required this.client, required this.currency, required this.onTap});

  final Client client;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(client.primaryCategory);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: kLime.withOpacity(0.10),
        highlightColor: kLime.withOpacity(0.05),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: kCardDecoration(radius: 20),
          child: Row(
            children: [
              ClientAvatar(name: client.name, size: 48, radius: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: kStyleBodyBold),
                    if (client.company.trim().isNotEmpty)
                      Text(client.company,
                          style: kStyleCaption,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: categoryColor.withOpacity(0.25)),
                          ),
                          child: Text(client.primaryCategory,
                              style:
                                  kStyleCaption.copyWith(color: categoryColor)),
                        ),
                        if (client.activeCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: kGreen.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: kGreen.withOpacity(0.25)),
                            ),
                            child: Text('${client.activeCount} active',
                                style: kStyleCaption.copyWith(color: kGreen)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmtCurrency(client.totalOwed, currency),
                      style: kStyleBodyBold.copyWith(color: kYellow)),
                  Text('${client.projects.length} projects',
                      style: kStyleCaption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
