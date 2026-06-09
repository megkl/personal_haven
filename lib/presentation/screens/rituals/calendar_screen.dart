import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/data/models/event.dart';
import 'package:personal_haven/providers/event_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildCalendarGrid(eventState),
          const SizedBox(height: 16),
          _buildEventsSection(eventState),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month - 1);
            }),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedMonth),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month + 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(EventState eventState) {
    final firstDay =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;

    // Dates that have events this month
    final datesWithEvents = eventState.events
        .where((e) =>
            e.eventDate.year == _focusedMonth.year &&
            e.eventDate.month == _focusedMonth.month)
        .map((e) => e.eventDate.day)
        .toSet();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayNumber = index - startWeekday + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }
              final date = DateTime(
                  _focusedMonth.year, _focusedMonth.month, dayNumber);
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _isSameDay(date, _selectedDate);
              final hasEvents = datesWithEvents.contains(dayNumber);

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : null,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasEvents)
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection(EventState eventState) {
    final events = eventState.events
        .where((e) => _isSameDay(e.eventDate, _selectedDate))
        .toList()
      ..sort((a, b) =>
          (a.startTime ?? a.eventDate).compareTo(b.startTime ?? b.eventDate));

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM dd').format(_selectedDate),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${events.length} events',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: eventState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : events.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available,
                                  size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No events scheduled',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) =>
                              _EventTile(event: events[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay? startTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Event',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: _inputDec('Title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: _inputDec('Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.now());
                      if (t != null) setModalState(() => startTime = t);
                    },
                    child: Text(startTime == null
                        ? 'Set time (optional)'
                        : startTime!.format(ctx)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    DateTime? start;
                    if (startTime != null) {
                      start = DateTime(_selectedDate.year, _selectedDate.month,
                          _selectedDate.day, startTime!.hour, startTime!.minute);
                    }
                    await ref.read(eventProvider.notifier).addEvent(
                          title: titleController.text.trim(),
                          description: descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          eventDate: _selectedDate,
                          startTime: start,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Event',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );
}

class _EventTile extends ConsumerWidget {
  final Event event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = EventCategories.getByName(event.category);
    final color = cat != null ? Color(cat.colorValue) : AppColors.primary;

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          ref.read(eventProvider.notifier).deleteEvent(event.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            if (event.startTime != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.timeString,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
            if (event.startTime != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  if (event.description != null)
                    Text(event.description!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(cat?.emoji ?? '📅',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
