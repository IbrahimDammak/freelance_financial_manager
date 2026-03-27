// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 2;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..status = fields[2] as String
      ..type = fields[3] as String
      ..startDate = fields[4] as String
      ..deadline = fields[5] as String
      ..pricingType = fields[6] as String
      ..fixedPrice = fields[7] as double
      ..hourlyRate = fields[8] as double
      ..estimatedHours = fields[9] as double
      ..loggedHours = fields[10] as double
      ..upfront = fields[11] as double
      ..remaining = fields[12] as double
      ..maintenanceFee = fields[13] as double
      ..maintenanceActive = fields[14] as bool
      ..services = (fields[15] as List).cast<String>()
      ..sessions = (fields[16] as List).cast<WorkSession>()
      ..notes = fields[17] as String;
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.deadline)
      ..writeByte(6)
      ..write(obj.pricingType)
      ..writeByte(7)
      ..write(obj.fixedPrice)
      ..writeByte(8)
      ..write(obj.hourlyRate)
      ..writeByte(9)
      ..write(obj.estimatedHours)
      ..writeByte(10)
      ..write(obj.loggedHours)
      ..writeByte(11)
      ..write(obj.upfront)
      ..writeByte(12)
      ..write(obj.remaining)
      ..writeByte(13)
      ..write(obj.maintenanceFee)
      ..writeByte(14)
      ..write(obj.maintenanceActive)
      ..writeByte(15)
      ..write(obj.services)
      ..writeByte(16)
      ..write(obj.sessions)
      ..writeByte(17)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
