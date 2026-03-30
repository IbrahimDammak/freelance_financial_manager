// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 0;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings()
      ..hourlyRate = fields[0] as double
      ..currency = fields[1] as String
      ..userName = fields[2] as String
      ..onboardingDone = fields[3] as bool
      ..dashboardSections = (fields[4] as List).cast<String>()
      ..showActiveProjects = fields[5] as bool
      ..showClientStrip = fields[6] as bool
      ..showOwedTimer = fields[7] as bool
      ..showMrrCollected = fields[8] as bool
      ..notificationsEnabled = fields[9] as bool
      ..notifyDailyLog = fields[10] as bool
      ..dailyReminderHour = fields[11] as int
      ..dailyReminderMinute = fields[12] as int
      ..notifyDeadline7Days = fields[13] as bool
      ..notifyDeadline1Day = fields[14] as bool
      ..notifyDeadlineDay = fields[15] as bool
      ..notifyOverdue = fields[16] as bool
      ..notifyWeeklyDigest = fields[17] as bool
      ..notifyOutstandingWeekly = fields[18] as bool
      ..notifyMaintenanceMonthly = fields[19] as bool
      ..notifyNoIncome = fields[20] as bool
      ..notifyNewProjectIdle = fields[21] as bool
      ..notifyIdleProject = fields[22] as bool
      ..notifyProjectComplete = fields[23] as bool
      ..notifyClientAnniversary = fields[24] as bool
      ..lastExportDate = fields[25] as String?
      ..serviceCategories = (fields[26] as List).cast<String>();
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.hourlyRate)
      ..writeByte(1)
      ..write(obj.currency)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.onboardingDone)
      ..writeByte(4)
      ..write(obj.dashboardSections)
      ..writeByte(5)
      ..write(obj.showActiveProjects)
      ..writeByte(6)
      ..write(obj.showClientStrip)
      ..writeByte(7)
      ..write(obj.showOwedTimer)
      ..writeByte(8)
      ..write(obj.showMrrCollected)
      ..writeByte(9)
      ..write(obj.notificationsEnabled)
      ..writeByte(10)
      ..write(obj.notifyDailyLog)
      ..writeByte(11)
      ..write(obj.dailyReminderHour)
      ..writeByte(12)
      ..write(obj.dailyReminderMinute)
      ..writeByte(13)
      ..write(obj.notifyDeadline7Days)
      ..writeByte(14)
      ..write(obj.notifyDeadline1Day)
      ..writeByte(15)
      ..write(obj.notifyDeadlineDay)
      ..writeByte(16)
      ..write(obj.notifyOverdue)
      ..writeByte(17)
      ..write(obj.notifyWeeklyDigest)
      ..writeByte(18)
      ..write(obj.notifyOutstandingWeekly)
      ..writeByte(19)
      ..write(obj.notifyMaintenanceMonthly)
      ..writeByte(20)
      ..write(obj.notifyNoIncome)
      ..writeByte(21)
      ..write(obj.notifyNewProjectIdle)
      ..writeByte(22)
      ..write(obj.notifyIdleProject)
      ..writeByte(23)
      ..write(obj.notifyProjectComplete)
      ..writeByte(24)
      ..write(obj.notifyClientAnniversary)
      ..writeByte(25)
      ..write(obj.lastExportDate)
      ..writeByte(26)
      ..write(obj.serviceCategories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
