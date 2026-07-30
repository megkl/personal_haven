import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// A compact speech-to-text control that writes partial and final results into
/// an existing text field without losing text that was already entered.
class VoiceDictationButton extends StatefulWidget {
  const VoiceDictationButton({
    super.key,
    required this.controller,
    this.separateParagraph = false,
    this.tooltip = 'Dictate with voice',
  });

  final TextEditingController controller;
  final bool separateParagraph;
  final String tooltip;

  @override
  State<VoiceDictationButton> createState() => _VoiceDictationButtonState();
}

class _VoiceDictationButtonState extends State<VoiceDictationButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechReady = false;
  String _textBeforeDictation = '';
  String _separator = '';

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    _speechReady =
        _speechReady ||
        await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
            }
          },
          onError: (error) {
            if (!mounted) return;
            setState(() => _isListening = false);
            final permissionDenied =
                error.errorMsg == 'error_permission' ||
                error.errorMsg == 'error_permission_denied';
            _showMessage(
              permissionDenied
                  ? 'Allow microphone and speech recognition access to use voice input.'
                  : 'Voice input could not start. Please try again.',
            );
          },
        );

    if (!_speechReady) {
      if (mounted) {
        _showMessage('Speech recognition is not available on this device.');
      }
      return;
    }

    _textBeforeDictation = widget.controller.text.trimRight();
    _separator = _textBeforeDictation.isEmpty
        ? ''
        : widget.separateParagraph
        ? '\n\n'
        : ' ';
    setState(() => _isListening = true);

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 4),
      ),
      onResult: (result) {
        if (!mounted) return;
        final spokenText = result.recognizedWords.trim();
        final text = spokenText.isEmpty
            ? _textBeforeDictation
            : '$_textBeforeDictation$_separator$spokenText';
        widget.controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _isListening
        ? AppColors.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: _isListening ? 'Stop voice dictation' : widget.tooltip,
      child: IconButton(
        tooltip: _isListening ? 'Stop listening' : widget.tooltip,
        onPressed: _toggleListening,
        style: IconButton.styleFrom(
          foregroundColor: color,
          backgroundColor: _isListening
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            _isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
            key: ValueKey(_isListening),
          ),
        ),
      ),
    );
  }
}
