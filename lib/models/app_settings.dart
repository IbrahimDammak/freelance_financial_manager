import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 0)
class AppSettings extends HiveObject {
  @HiveField(0)
  double hourlyRate = 50.0;

  @HiveField(1)
  String currency = 'TND';

  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'NGN',
    'TND',
    'CAD'
  ];
}
