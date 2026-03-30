import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'models/client.dart';
import 'models/project.dart';
import 'models/work_session.dart';

void seedIfNeeded(Box settingsBox, Box clientsBox) {
  if (settingsBox.get('seeded_v1') == true) return;

  final now = DateTime.now();
  final fmt = DateFormat('yyyy-MM-dd');

  final activeDeadline = fmt.format(now.add(const Duration(days: 18)));
  final activeStart = fmt.format(now.subtract(const Duration(days: 45)));
  final completedDeadline = fmt.format(now.subtract(const Duration(days: 60)));
  final completedStart = fmt.format(now.subtract(const Duration(days: 130)));
  final session1Date = fmt.format(now.subtract(const Duration(days: 30)));
  final session2Date = fmt.format(now.subtract(const Duration(days: 15)));
  final session3Date = fmt.format(now.subtract(const Duration(days: 100)));
  final session4Date = fmt.format(now.subtract(const Duration(days: 80)));

  final clients = [
    Client()
      ..id = const Uuid().v4()
      ..name = 'Sarah Mitchell'
      ..company = 'Bloom Studio'
      ..primaryCategory = 'Web Development'
      ..email = 'sarah@bloom.co'
      ..phone = '+1 555-0101'
      ..avatar = 'SM'
      ..createdAt = fmt.format(now.subtract(const Duration(days: 90)))
      ..notes = 'Prefers communication via email. Very detail-oriented.'
      ..projects = [
        Project()
          ..id = const Uuid().v4()
          ..name = 'Portfolio Redesign'
          ..status = 'active'
          ..category = 'Web Development'
          ..startDate = activeStart
          ..deadline = activeDeadline
          ..pricingType = 'fixed'
          ..fixedPrice = 2400
          ..hourlyRate = 0
          ..estimatedHours = 40
          ..loggedHours = 7.0
          ..upfront = 1200
          ..remaining = 1200
          ..maintenanceFee = 120
          ..maintenanceActive = true
          ..services = ['UI Design', 'Development', 'SEO Setup']
          ..notes = 'Client wants minimalist look. Figma file shared.'
          ..sessions = [
            WorkSession()
              ..id = const Uuid().v4()
              ..date = session1Date
              ..durationMins = 180
              ..note = 'Wireframes',
            WorkSession()
              ..id = const Uuid().v4()
              ..date = session2Date
              ..durationMins = 240
              ..note = 'Homepage build',
          ],
      ],
    Client()
      ..id = const Uuid().v4()
      ..name = 'James Okafor'
      ..company = 'Kafor Brands'
      ..primaryCategory = 'Graphic Design'
      ..email = 'james@kafor.ng'
      ..phone = '+234 812 000 1234'
      ..avatar = 'JO'
      ..createdAt = fmt.format(now.subtract(const Duration(days: 200)))
      ..notes = 'Quick to respond. Lagos based.'
      ..projects = [
        Project()
          ..id = const Uuid().v4()
          ..name = 'Brand Identity Pack'
          ..status = 'completed'
          ..category = 'Graphic Design'
          ..startDate = completedStart
          ..deadline = completedDeadline
          ..pricingType = 'fixed'
          ..fixedPrice = 1800
          ..hourlyRate = 0
          ..estimatedHours = 30
          ..loggedHours = 12.0 + 8.0
          ..upfront = 1800
          ..remaining = 0
          ..maintenanceFee = 0
          ..maintenanceActive = false
          ..services = ['Logo Design', 'Brand Guidelines', 'Social Kit']
          ..notes = 'Delivered all files in AI, PDF, PNG formats.'
          ..sessions = [
            WorkSession()
              ..id = const Uuid().v4()
              ..date = session3Date
              ..durationMins = 300
              ..note = 'Logo concepts',
            WorkSession()
              ..id = const Uuid().v4()
              ..date = session4Date
              ..durationMins = 480
              ..note = 'Full brand guide',
          ],
      ],
  ];

  clientsBox.put('all', clients);
  settingsBox.put('seeded_v1', true);
}
