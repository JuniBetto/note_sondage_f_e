// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskHiveModelAdapter extends TypeAdapter<TaskHiveModel> {
  @override
  final int typeId = 9;

  @override
  TaskHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskHiveModel(
      id: fields[0] as String,
      teamId: fields[1] as String?,
      title: fields[2] as String,
      description: fields[3] as String?,
      status: fields[4] as String,
      priority: fields[5] as String,
      startAt: fields[6] as String?,
      dueAt: fields[7] as String?,
      assigneeUserId: fields[8] as String?,
      assigneeDisplayName: fields[9] as String?,
      createdByUserId: fields[10] as String,
      createdByDisplayName: fields[11] as String?,
      workflowMetadataJson: fields[12] as String?,
      completedAt: fields[13] as String?,
      archivedAt: fields[14] as String?,
      createdAt: fields[15] as String,
      updatedAt: fields[16] as String,
      reminderOffsetsCsv: fields[17] as String?,
      reminderAnchor: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskHiveModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teamId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.startAt)
      ..writeByte(7)
      ..write(obj.dueAt)
      ..writeByte(8)
      ..write(obj.assigneeUserId)
      ..writeByte(9)
      ..write(obj.assigneeDisplayName)
      ..writeByte(10)
      ..write(obj.createdByUserId)
      ..writeByte(11)
      ..write(obj.createdByDisplayName)
      ..writeByte(12)
      ..write(obj.workflowMetadataJson)
      ..writeByte(13)
      ..write(obj.completedAt)
      ..writeByte(14)
      ..write(obj.archivedAt)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.reminderOffsetsCsv)
      ..writeByte(18)
      ..write(obj.reminderAnchor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
