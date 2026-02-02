import 'package:flutter/material.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodSelectionDialog extends StatefulWidget {
  final MoodLog? currentMood;

  const MoodSelectionDialog({
    super.key,
    this.currentMood,
  });

  @override
  State<MoodSelectionDialog> createState() => _MoodSelectionDialogState();
}

class _MoodSelectionDialogState extends State<MoodSelectionDialog> {
  String? _selectedEmoji;
  String? _selectedLabel;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.currentMood != null) {
      _selectedEmoji = widget.currentMood!.moodEmoji;
      //_selectedLabel = widget.currentMood!.label;
      _noteController.text = widget.currentMood!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'How are you feeling?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3E40),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the emoji that best describes your mood',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),

            // Mood Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: MoodOptions.all.length,
              itemBuilder: (context, index) {
                final mood = MoodOptions.all[index];
                final isSelected = _selectedEmoji == mood.emoji;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = mood.emoji;
                      _selectedLabel = mood.label;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? mood.color.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? mood.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mood.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF2D3E40)
                                : const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Optional note
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedEmoji != null ? _saveMood : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  disabledBackgroundColor:
                      const Color(0xFF4ECDC4).withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Mood',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMood() async {
    if (_selectedEmoji == null || _selectedLabel == null) return;
final prefs = await SharedPreferences.getInstance();
    final mood = MoodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: prefs.getString('current_user_id') ?? 
      '',
      moodEmoji: _selectedEmoji!,
      moodLevel: MoodOptions.all
          .firstWhere((m) => m.emoji == _selectedEmoji!)
          .label
          .hashCode,
      //label: _selectedLabel!,
      timestamp: DateTime.now(),
      notes: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    Navigator.pop(context, mood);
  }
}