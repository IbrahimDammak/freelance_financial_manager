import 'package:hive/hive.dart';

import 'project.dart';

part 'client.g.dart';

@HiveType(typeId: 3)
class Client extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String company;

  @HiveField(3)
  late String email;

  @HiveField(4)
  late String phone;

  @HiveField(5)
    late String primaryCategory;

  @HiveField(6)
  late String avatar;

  @HiveField(7)
  late String createdAt;

  @HiveField(8)
  late String notes;

  @HiveField(9)
  late List<Project> projects;

  double get totalPaid =>
      projects.fold(0, (sum, project) => sum + project.upfront);

  double get totalOwed =>
      projects.fold(0, (sum, project) => sum + project.remaining);

  double get totalMrr => projects
      .where((project) => project.maintenanceActive)
      .fold(0, (sum, project) => sum + project.maintenanceFee);

  int get totalMins => projects
      .expand((project) => project.sessions)
      .fold(0, (sum, session) => sum + session.durationMins);

  int get activeCount =>
      projects.where((project) => project.status == 'active').length;
}
