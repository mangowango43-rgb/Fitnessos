import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class WorkoutDateStrip extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Color? accentColor;
  
  const WorkoutDateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.accentColor,
  });

  @override
  State<WorkoutDateStrip> createState() => _WorkoutDateStripState();
}

class _WorkoutDateStripState extends State<WorkoutDateStrip> {
  late ScrollController _scrollController;
  late List<DateTime> _dates;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateDates();
    
    // Scroll to selected date after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _generateDates() {
    final now = DateTime.now();
    // 30 days back, 365 days forward (so user can schedule way ahead)
    final startDate = DateTime(now.year, now.month, now.day - 30);
    
    _dates = List.generate(395, (index) { // 30 + 365 = 395 days
      return startDate.add(Duration(days: index));
    });
  }
  
  void _scrollToSelectedDate() {
    final selectedIndex = _dates.indexWhere((date) => 
        _isSameDay(date, widget.selectedDate));
    
    if (selectedIndex != -1 && _scrollController.hasClients) {
      final scrollOffset = (selectedIndex * 56.0) - 
          (MediaQuery.of(context).size.width / 2) + 28;
      final max = _scrollController.position.maxScrollExtent;
      final clamped = scrollOffset.isFinite
          ? scrollOffset.clamp(0.0, max)
          : 0.0;
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }
  
  void _navigateDate(int direction) {
    final newDate = widget.selectedDate.add(Duration(days: direction));
    widget.onDateSelected(newDate);
    
    // Update dates list if needed
    if (!_dates.any((date) => _isSameDay(date, newDate))) {
      _generateDates();
      setState(() {});
    }
    
    // Scroll to new date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppColors.cyberLime;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with selected date info and navigation arrows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(widget.selectedDate),
                    style: TextStyle(
                      color: AppColors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _navigateDate(-1),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.white20),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 16,
                        color: AppColors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _navigateDate(1),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.white20),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Calendar jump button
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: widget.selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: accentColor,
                                surface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        widget.onDateSelected(picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.white20),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: AppColors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Scrollable date strip
        SizedBox(
          height: 64,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _dates.length,
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected = _isSameDay(date, widget.selectedDate);
              final isToday = _isToday(date);
              
              return GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 56,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? LinearGradient(
                            colors: [accentColor, accentColor.withOpacity(0.8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: isSelected ? null : AppColors.white5,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? accentColor 
                          : isToday
                              ? accentColor.withOpacity(0.5)
                              : AppColors.white10,
                      width: isToday && !isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected 
                        ? [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.black 
                              : AppColors.white90,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEE').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.black.withOpacity(0.7) 
                              : AppColors.white50,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

