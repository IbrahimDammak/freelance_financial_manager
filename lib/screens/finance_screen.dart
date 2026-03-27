import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/section_label.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final clients = dataProvider.sortedClients;

    final maxValue = clients.isEmpty
        ? 100.0
        : clients
            .map((c) => c.totalPaid + c.totalOwed)
            .reduce((a, b) => a > b ? a : b);
    final interval = (maxValue / 3).clamp(1, double.infinity).toDouble();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(text: 'OVERVIEW'),
              const SizedBox(height: 4),
              Text('Revenue', style: kStyleHeading),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kBlack,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL LIFETIME VALUE',
                      style: kStyleLabel.copyWith(color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fmtCurrency(
                          dataProvider.lifetimeValue, settings.currency),
                      style: kStyleDisplay.copyWith(color: kWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'incl. MRR annualized',
                      style: kStyleCaption.copyWith(color: Colors.white38),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _breakdownRow(Icons.south_west, 'Collected',
                  dataProvider.totalCollected, settings.currency, kGreen),
              _breakdownRow(Icons.schedule, 'Outstanding',
                  dataProvider.totalOwed, settings.currency, kYellow),
              _breakdownRow(Icons.repeat, 'Monthly Recurring',
                  dataProvider.totalMrr, settings.currency, kBlue),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, _, rod, __) {
                          final client = clients[group.x.toInt()];
                          return BarTooltipItem(
                            '${client.name}\n${fmtCurrency(rod.toY, settings.currency)}',
                            kStyleCaption.copyWith(
                                color: kTextPrimary,
                                fontWeight: FontWeight.w700),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= clients.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(clients[idx].name.split(' ').first,
                                  style: kStyleCaption),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: interval,
                          getTitlesWidget: (value, _) {
                            return Text(
                                fmtCurrency(
                                    value.toDouble(), settings.currency),
                                style: kStyleCaption);
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (v) =>
                          const FlLine(color: kBorder, strokeWidth: 0.5),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      for (var i = 0; i < clients.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: clients[i].totalPaid + clients[i].totalOwed,
                              width: 18,
                              color: avatarColorFor(clients[i].name),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SectionLabel(text: 'PER CLIENT'),
              const SizedBox(height: 8),
              ...clients.map((client) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: kCardDecoration(radius: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClientAvatar(name: client.name, size: 36, radius: 10),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(client.name, style: kStyleBodyBold)),
                          Text(
                            fmtCurrency(client.totalPaid + client.totalOwed,
                                settings.currency),
                            style: kStyleBodyBold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                              'Paid ${fmtCurrency(client.totalPaid, settings.currency)}',
                              style: kStyleCaption.copyWith(color: kGreen)),
                          const SizedBox(width: 10),
                          Text(
                              'Owed ${fmtCurrency(client.totalOwed, settings.currency)}',
                              style: kStyleCaption.copyWith(color: kYellow)),
                          const SizedBox(width: 10),
                          Text(
                              'MRR ${fmtCurrency(client.totalMrr, settings.currency)}',
                              style: kStyleCaption.copyWith(color: kBlue)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breakdownRow(IconData icon, String label, double amount,
      String currency, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: kCardDecoration(radius: 20),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: kStyleBody)),
          Text(fmtCurrency(amount, currency),
              style: kStyleBodyBold.copyWith(color: color)),
        ],
      ),
    );
  }
}
