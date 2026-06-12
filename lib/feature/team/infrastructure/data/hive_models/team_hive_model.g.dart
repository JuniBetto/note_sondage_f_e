// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TeamHiveModelAdapter extends TypeAdapter<TeamHiveModel> {
  @override
  final int typeId = 4;

  @override
  TeamHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TeamHiveModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      description: fields[2] as String,
      createdByUserId: fields[3] as String,
      createdAt: fields[4] as String,
      color: fields[5] as String?,
      clockingRequired: fields[6] as bool? ?? false,
      clockingReminderTime: fields[7] as String?,
      clockingMissingAlertTime: fields[8] as String?,
      clockingOpenAlertTime: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TeamHiveModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdByUserId)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.clockingRequired)
      ..writeByte(7)
      ..write(obj.clockingReminderTime)
      ..writeByte(8)
      ..write(obj.clockingMissingAlertTime)
      ..writeByte(9)
      ..write(obj.clockingOpenAlertTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
