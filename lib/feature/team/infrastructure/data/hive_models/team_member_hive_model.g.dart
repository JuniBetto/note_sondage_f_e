// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_member_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TeamMemberHiveModelAdapter extends TypeAdapter<TeamMemberHiveModel> {
  @override
  final int typeId = 5;

  @override
  TeamMemberHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TeamMemberHiveModel(
      id: fields[0] as String?,
      userEmail: fields[1] as String,
      teamId: fields[2] as String,
      status: fields[3] as String,
      roleId: fields[4] as String,
      imageUrl: fields[5] as String?,
      fileName: fields[6] as String?,
      initialName: fields[7] as String?,
      userId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TeamMemberHiveModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userEmail)
      ..writeByte(2)
      ..write(obj.teamId)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.roleId)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.fileName)
      ..writeByte(7)
      ..write(obj.initialName)
      ..writeByte(8)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMemberHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
