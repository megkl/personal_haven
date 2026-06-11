import 'package:flutter/material.dart';
import 'package:personal_haven/data/data_sources/local/shared_prefs_helper.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:uuid/uuid.dart';

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
  MoodOption? _selectedMood;
  final _noteController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.currentMood != null) {
      _selectedMood = MoodOptions.getByEmoji(widget.currentMood!.moodEmoji);
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
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: MoodOptions.all.length,
              itemBuilder: (context, index) {
                final mood = MoodOptions.all[index];
                final isSelected = _selectedMood?.emoji == mood.emoji;

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedMood = mood;
                    });
                    if (_noteController.text.trim().isEmpty) {
                      await _saveMood();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? mood.color.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mood.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF2D3E40)
                                : const Color(0xFF9E9E9E),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Selected mood indicator
            if (_selectedMood != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedMood!.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedMood!.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Feeling ${_selectedMood!.label}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedMood!.color.withValues(alpha: 1),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Optional note
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Add a note about how you\'re feeling (optional)',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
                counterStyle: const TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMood != null ? _saveMood : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  disabledBackgroundColor:
                      const Color(0xFF4ECDC4).withValues(alpha: 0.5),
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

  Future<void> _saveMood() async {
    if (_selectedMood == null) return;

    final prefs = await SharedPrefsHelper.getInstance();
    final userId = prefs.getUserId();

    if (userId == null) {
      Navigator.pop(context);
      return;
    }

    final mood = MoodLog(
      id: _uuid.v4(),
      userId: userId,
      moodLevel: _selectedMood!.level,
      moodLabel: _selectedMood!.label,
      moodEmoji: _selectedMood!.emoji,
      timestamp: DateTime.now(),
      notes: _noteController.text.isNotEmpty ? _noteController.text.trim() : null,
    );

    Navigator.pop(context, mood);
  }
}