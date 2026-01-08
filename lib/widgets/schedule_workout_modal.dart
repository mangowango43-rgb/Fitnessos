import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

/// Modal for scheduling a workout with alarm
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
  List<int> _selectedDays = [1, 3, 5]; // Mon, Wed, Fri by default

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Schedule for ${DateFormat('MMM d').format(widget.selectedDate)}',
                        style: const TextStyle(
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
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alarm toggle
                    _buildAlarmToggle(),
                    
                    const SizedBox(height: 24),
                    
                    // Time picker
                    if (_alarmEnabled) _buildTimePicker(),
                    
                    const SizedBox(height: 24),
                    
                    // Repeat days selector
                    if (_alarmEnabled) _buildRepeatDaysSelector(),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Primary button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, {
                          'time': _alarmEnabled ? _selectedTime : null,
                          'repeatDays': _alarmEnabled ? _selectedDays : <int>[],
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyberLime,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _alarmEnabled ? '⏰ Set Alarm & Choose Workout' : 'Choose Workout',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Secondary button
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'time': null,
                        'repeatDays': <int>[],
                      });
                    },
                    child: const Text(
                      'Skip Alarm',
                      style: TextStyle(
                        color: AppColors.white50,
                        fontSize: 14,
                      ),
                    ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.alarm, color: AppColors.cyberLime, size: 24),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Alarm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Get notified when it\'s workout time',
                    style: TextStyle(
                      color: AppColors.white50,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _alarmEnabled,
            onChanged: (value) {
              setState(() => _alarmEnabled = value);
              HapticFeedback.selectionClick();
            },
            activeColor: AppColors.cyberLime,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alarm Time',
            style: TextStyle(
              color: AppColors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
                HapticFeedback.selectionClick();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cyberLime, AppColors.electricCyan],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, color: Colors.black),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatDaysSelector() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repeat Days',
            style: TextStyle(
              color: AppColors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(index);
                    } else {
                      _selectedDays.add(index);
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cyberLime : AppColors.white10,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.cyberLime : AppColors.white20,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
