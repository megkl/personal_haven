import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/data/models/event.dart';
import 'package:personal_haven/providers/event_provider.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(eventProvider.notifier).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildDatePicker(eventState),
          const SizedBox(height: 8),
          _buildEventsSection(eventState),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'rituals_events_add',
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDatePicker(EventState eventState) {
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );
    final weekDates = List.generate(
      7,
      (index) =>
          DateTime(weekStart.year, weekStart.month, weekStart.day + index),
    );
    final eventDates = eventState.events
        .map((event) => _dateKey(event.eventDate))
        .toSet();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous week',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  icon: Icon(Icons.chevron_left, size: 21),
                  onPressed: () => _shiftSelectedDate(-7),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next week',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  icon: Icon(Icons.chevron_right, size: 21),
                  onPressed: () => _shiftSelectedDate(7),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Today',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  icon: Icon(
                    Icons.today_outlined,
                    size: 19,
                    color: AppColors.primary,
                  ),
                  onPressed: () => setState(() {
                    _selectedDate = DateTime.now();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: weekDates.map((date) {
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final hasEvents = eventDates.contains(_dateKey(date));

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: DateFormat('EEEE, MMMM d').format(date),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(date).substring(0, 2),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.82)
                                  : context.colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: hasEvents
                                  ? isSelected
                                        ? Colors.white
                                        : AppColors.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _shiftSelectedDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Widget _buildEventsSection(EventState eventState) {
    final events =
        eventState.events
            .where((e) => _isSameDay(e.eventDate, _selectedDate))
            .toList()
          ..sort(
            (a, b) => (a.startTime ?? a.eventDate).compareTo(
              b.startTime ?? b.eventDate,
            ),
          );

    return Expanded(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM dd').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${events.length} event${events.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref.read(eventProvider.notifier).refresh(),
                child: eventState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : eventState.error != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 70),
                          Text(
                            eventState.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      )
                    : events.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 54),
                          Icon(
                            Icons.event_available_outlined,
                            size: 42,
                            color: context.colors.divider,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No events scheduled',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add an event',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _EventTile(
                            event: event,
                            onTap: () => _showEventOptions(event),
                            onDelete: () => _confirmDelete(event),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  void _showAddEventDialog(BuildContext context) => _showEventForm();

  void _showEventOptions(Event event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Icon(Icons.edit_outlined, color: AppColors.primary),
              title: Text('Edit event'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEventForm(event: event);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete event', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(event);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEventForm({Event? event}) {
    final isEditing = event != null;
    final titleController = TextEditingController(text: event?.title ?? '');
    final descController = TextEditingController(
      text: event?.description ?? '',
    );
    TimeOfDay? startTime = event?.startTime == null
        ? null
        : TimeOfDay.fromDateTime(event!.startTime!);
    final eventDate = event?.eventDate ?? _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Event' : 'Add Event',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
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
                  Icon(Icons.access_time, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: startTime ?? TimeOfDay.now(),
                        );
                        if (t != null) setModalState(() => startTime = t);
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          startTime == null
                              ? 'Set time (optional)'
                              : startTime!.format(ctx),
                        ),
                      ),
                    ),
                  ),
                  if (startTime != null)
                    IconButton(
                      tooltip: 'Remove time',
                      onPressed: () => setModalState(() => startTime = null),
                      icon: Icon(Icons.close, size: 18),
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
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    DateTime? start;
                    if (startTime != null) {
                      start = DateTime(
                        eventDate.year,
                        eventDate.month,
                        eventDate.day,
                        startTime!.hour,
                        startTime!.minute,
                      );
                    }
                    final description = descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim();
                    if (isEditing) {
                      await ref
                          .read(eventProvider.notifier)
                          .updateEvent(
                            Event(
                              id: event.id,
                              userId: event.userId,
                              title: titleController.text.trim(),
                              description: description,
                              eventDate: eventDate,
                              startTime: start,
                              endTime: event.endTime,
                              isAllDay: event.isAllDay,
                              location: event.location,
                              category: event.category,
                              color: event.color,
                              isRecurring: event.isRecurring,
                              recurrenceRule: event.recurrenceRule,
                              reminder: event.reminder,
                              createdAt: event.createdAt,
                              updatedAt: event.updatedAt,
                            ),
                          );
                    } else {
                      await ref
                          .read(eventProvider.notifier)
                          .addEvent(
                            title: titleController.text.trim(),
                            description: description,
                            eventDate: eventDate,
                            startTime: start,
                          );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(
                    isEditing ? 'Update Event' : 'Save Event',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Event event) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Delete Event?'),
            content: Text('Delete "${event.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(eventProvider.notifier).deleteEvent(event.id);
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Theme.of(context).scaffoldBackgroundColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

class _EventTile extends ConsumerWidget {
  final Event event;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;

  const _EventTile({
    required this.event,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = EventCategories.getByName(event.category);
    final color = cat != null ? Color(cat.colorValue) : AppColors.primary;

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Row(
                children: [
                  if (event.startTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.timeString,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  if (event.startTime != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        if (event.description != null)
                          Text(
                            event.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(cat?.emoji ?? '📅', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
