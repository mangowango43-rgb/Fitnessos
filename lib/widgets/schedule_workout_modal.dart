import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

/// Modal for scheduling a workout with alarm
/// Features a VISIBLE Cupertino-style time picker wheel
class ScheduleWorkoutModal extends StatefulWidget {
  final DateTime selectedDate;
  
  const ScheduleWorkoutModal({
    super.key,
    required this.selectedDate,
  });

  @override
  State<ScheduleWorkoutModal> createState() => _ScheduleWorkoutModalState();
}

class _ScheduleWorkoutModalState extends State<ScheduleWorkoutModal> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool _alarmEnabled = true;

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 ScheduleWorkoutModal: Building for date: ${widget.selectedDate}');
    debugPrint('   - Alarm enabled: $_alarmEnabled');
    debugPrint('   - Selected time: $_selectedTime');

    final dateStr = DateFormat('EEEE, MMM d').format(widget.selectedDate);
    final isToday = widget.selectedDate.year == DateTime.now().year &&
                    widget.selectedDate.month == DateTime.now().month &&
                    widget.selectedDate.day == DateTime.now().day;
    
    return Container(
      // Taller to fit the time picker wheel
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.cyberBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.cyberLime.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⏰ SET ALARM',
                        style: TextStyle(
                          color: AppColors.cyberLime,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isToday ? 'Today' : dateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      debugPrint('❌ ScheduleWorkoutModal: CLOSED via X button (returning null)');
                      Navigator.pop(context);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAlarmToggle(),
                    const SizedBox(height: 24),
                    if (_alarmEnabled) ...[
                      _buildTimePickerWheel(),
                      const SizedBox(height: 16),
                      _buildSelectedTimeDisplay(),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cyberBlack,
                border: Border(top: BorderSide(color: AppColors.white10, width: 1)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        final result = {
                          'time': _alarmEnabled ? _selectedTime : null,
                          'repeatDays': <int>[],
                        };
                        debugPrint('🔙 ScheduleWorkoutModal: Returning result: $result');
                        Navigator.pop(context, result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyberLime,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_alarmEnabled ? Icons.alarm_on : Icons.fitness_center, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            _alarmEnabled ? 'SET ALARM & CHOOSE WORKOUT' : 'CHOOSE WORKOUT',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final result = {'time': null, 'repeatDays': <int>[]};
                      debugPrint('🔙 ScheduleWorkoutModal: SKIP ALARM - Returning result: $result');
                      Navigator.pop(context, result);
                    },
                    child: const Text('Skip Alarm', style: TextStyle(color: AppColors.white50, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _alarmEnabled = !_alarmEnabled);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _alarmEnabled ? AppColors.cyberLime.withOpacity(0.1) : AppColors.white5,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _alarmEnabled ? AppColors.cyberLime.withOpacity(0.5) : AppColors.white10,
            width: _alarmEnabled ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _alarmEnabled ? AppColors.cyberLime.withOpacity(0.2) : AppColors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.alarm, color: _alarmEnabled ? AppColors.cyberLime : AppColors.white50, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Workout Alarm', style: TextStyle(color: _alarmEnabled ? Colors.white : AppColors.white70, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_alarmEnabled ? 'Get reminded when it\'s time to train' : 'No reminder set', style: const TextStyle(color: AppColors.white50, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: _alarmEnabled,
              onChanged: (value) {
                setState(() => _alarmEnabled = value);
                HapticFeedback.selectionClick();
              },
              activeColor: AppColors.cyberLime,
              activeTrackColor: AppColors.cyberLime.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VISIBLE TIME PICKER WHEEL (Cupertino Style)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTimePickerWheel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyberLime.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.cyberLime, size: 18),
                const SizedBox(width: 8),
                const Text('SELECT TIME', style: TextStyle(color: AppColors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ],
            ),
          ),
          
          // 🔥 CUPERTINO TIME PICKER WHEEL - VISIBLE AND SCROLLABLE
          SizedBox(
            height: 180,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute),
                use24hFormat: false,
                onDateTimeChanged: (DateTime dateTime) {
                  setState(() {
                    _selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
                  });
                  HapticFeedback.selectionClick();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTimeDisplay() {
    final hour = _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.cyberLime.withOpacity(0.2), AppColors.electricCyan.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyberLime.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.alarm_on, color: AppColors.cyberLime, size: 28),
          const SizedBox(width: 12),
          Text('$hour:$minute', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.cyberLime, borderRadius: BorderRadius.circular(6)),
            child: Text(period, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
