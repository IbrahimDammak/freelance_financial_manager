import 'package:hive/hive.dart';

part 'work_session.g.dart';

@HiveType(typeId: 1)
class WorkSession extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String date;

  @HiveField(2)
  late int durationMins;

  @HiveField(3)
  late String note;
}
