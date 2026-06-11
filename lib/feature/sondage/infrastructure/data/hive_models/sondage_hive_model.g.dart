// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sondage_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SondageHiveModelAdapter extends TypeAdapter<SondageHiveModel> {
  @override
  final int typeId = 7;

  @override
  SondageHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SondageHiveModel(
      id: fields[0] as String,
      name: fields[1] as String,
      focus: fields[2] as String,
      status: fields[3] as String,
      responses: fields[4] as int,
      totalQuestions: fields[5] as int,
      createdDate: fields[6] as String,
      expiryDate: fields[7] as String?,
      color: fields[8] as int,
      createdByUserId: fields[9] as String?,
      teamId: fields[10] as String?,
      description: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SondageHiveModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.focus)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.responses)
      ..writeByte(5)
      ..write(obj.totalQuestions)
      ..writeByte(6)
      ..write(obj.createdDate)
      ..writeByte(7)
      ..write(obj.expiryDate)
      ..writeByte(8)
      ..write(obj.color)
      ..writeByte(9)
      ..write(obj.createdByUserId)
      ..writeByte(10)
      ..write(obj.teamId)
      ..writeByte(11)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SondageHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
