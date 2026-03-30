import 'package:hive/hive.dart';

import 'payment_record.dart';
import 'work_session.dart';

part 'project.g.dart';

@HiveType(typeId: 2)
class Project extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String status;

  @HiveField(3)
  late String category;

  @HiveField(4)
  late String startDate;

  @HiveField(5)
  late String deadline;

  @HiveField(6)
  late String pricingType;

  @HiveField(7)
  late double fixedPrice;

  @HiveField(8)
  late double hourlyRate;

  @HiveField(9)
  late double estimatedHours;

  @HiveField(10)
  late double loggedHours;

  @HiveField(11)
  late double upfront;

  @HiveField(12)
  late double remaining;

  @HiveField(13)
  late double maintenanceFee;

  @HiveField(14)
  late bool maintenanceActive;

  @HiveField(15)
  late List<String> services;

  @HiveField(16)
  late List<WorkSession> sessions;

  @HiveField(17)
  late String notes;

  @HiveField(18)
  List<PaymentRecord> payments = [];

  void recomputeLoggedHours() {
    loggedHours =
        sessions.fold(0.0, (sum, session) => sum + session.durationMins / 60.0);
  }

  double get totalValue => upfront + remaining;
}
