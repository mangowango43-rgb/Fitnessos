// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutScheduleAdapter extends TypeAdapter<WorkoutSchedule> {
  @override
  final int typeId = 1;

  @override
  WorkoutSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSchedule(
      id: fields[0] as String,
      workoutId: fields[1] as String,
      workoutName: fields[2] as String,
      scheduledDate: fields[3] as DateTime,
      scheduledTime: fields[4] as String?,
      hasAlarm: fields[5] as bool,
      isCompleted: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      repeatDays: (fields[8] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSchedule obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workoutId)
      ..writeByte(2)
      ..write(obj.workoutName)
      ..writeByte(3)
      ..write(obj.scheduledDate)
      ..writeByte(4)
      ..write(obj.scheduledTime)
      ..writeByte(5)
      ..write(obj.hasAlarm)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.repeatDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
