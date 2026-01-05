import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

/// Modal for scheduling a workout on a specific date
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
  TimeOfDay? _selectedTime;
  bool _hasAlarm = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(widget.selectedDate);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Schedule Workout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Date display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white5,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.cyberLime, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Time picker
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white5,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.electricCyan, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime == null
                            ? 'Set Time (Optional)'
                            : _selectedTime!.format(context),
                        style: TextStyle(
                          color: _selectedTime == null ? AppColors.white50 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.white40,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Alarm toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasAlarm ? AppColors.cyberLime.withOpacity(0.1) : AppColors.white5,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hasAlarm ? AppColors.cyberLime : AppColors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: _hasAlarm ? AppColors.cyberLime : AppColors.white50,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set Alarm',
                            style: TextStyle(
                              color: _hasAlarm ? AppColors.cyberLime : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _selectedTime == null
                                ? 'Set time first'
                                : 'Get notified at workout time',
                            style: TextStyle(
                              color: AppColors.white50,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _hasAlarm,
                      onChanged: _selectedTime == null
                          ? null
                          : (value) {
                              setState(() {
                                _hasAlarm = value;
                              });
                              HapticFeedback.selectionClick();
                            },
                      activeColor: AppColors.cyberLime,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue button
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context, {
                    'time': _selectedTime,
                    'hasAlarm': _hasAlarm,
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.electricCyan, AppColors.cyberLime],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricCyan.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Choose Workout',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.cyberLime,
              surface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      HapticFeedback.mediumImpact();
    }
  }
}

