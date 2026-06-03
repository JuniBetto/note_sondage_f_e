// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoleHiveModelAdapter extends TypeAdapter<RoleHiveModel> {
  @override
  final int typeId = 3;

  @override
  RoleHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoleHiveModel(
      id: fields[0] as String?,
      teamId: fields[1] as String,
      name: fields[2] as String,
      permissions: (fields[3] as List).cast<String>(),
      description: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RoleHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teamId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.permissions)
      ..writeByte(4)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
