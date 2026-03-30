import 'package:hive/hive.dart';

part 'payment_record.g.dart';

@HiveType(typeId: 4)
class PaymentRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String date;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late String note;
}
