// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_entitie.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThemeEntitieAdapter extends TypeAdapter<ThemeEntitie> {
  @override
  final int typeId = 0;

  @override
  ThemeEntitie read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThemeEntitie(
      themeName: fields[0] as ThemeModeType,
    );
  }

  @override
  void write(BinaryWriter writer, ThemeEntitie obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.themeName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeEntitieAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
