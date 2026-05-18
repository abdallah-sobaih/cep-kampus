import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/constants/ui_constants.dart';

typedef OnSpeechResult = void Function(String text);

class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.onResult,
    required this.onListeningChanged,
  });

  /// Fires once with the final recognised transcript.
  final OnSpeechResult onResult;

  /// Fires whenever the listening state changes so the parent
  /// input bar can disable the text field accordingly.
  final ValueChanged<bool> onListeningChanged;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final _speech = stt.SpeechToText();

  bool _isAvailable = false;
  bool _isListening = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initialiseSpeech();
  }

  Future<void> _initialiseSpeech() async {
    final available = await _speech.initialize(
      onError: (_) => _onSessionEnd(),
      onStatus: (status) {
        // The engine reports 'done' or 'notListening' when it stops
        // automatically after a pause — treat both as a clean end.
        if (status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) {
          _onSessionEnd();
        }
      },
    );
    if (mounted) setState(() => _isAvailable = available);
  }

  /// Tap handler — toggles between listening and idle.
  Future<void> _handleTap() async {
    if (!_isAvailable) return;

    if (_isListening) {
      await _speech.stop();
      _onSessionEnd();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    HapticFeedback.mediumImpact();
    setState(() => _isListening = true);
    widget.onListeningChanged(true);
    _pulseController.repeat(reverse: true);

    await _speech.listen(
      localeId: 'tr_TR',           // Strict Turkish locale per requirement.
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        // Only act on a finalised result so partial transcriptions
        // do not prematurely populate or submit the text field.
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          widget.onResult(result.recognizedWords);
          _onSessionEnd();
        }
      },
    );
  }

  /// Resets all state after a session ends, whether by tap, timeout,
  /// engine pause detection, or an error callback.
  void _onSessionEnd() {
    if (!mounted) return;
    _pulseController
      ..stop()
      ..reset();
    setState(() => _isListening = false);
    widget.onListeningChanged(false);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseScale,
      builder: (_, child) => Transform.scale(
        scale: _isListening ? _pulseScale.value : 1.0,
        child: child,
      ),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color:
                _isListening ? AppColors.micActive : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isListening
                  ? AppColors.micActive
                  : AppColors.divider,
            ),
            boxShadow: _isListening
                ? [
                    BoxShadow(
                      color: AppColors.micActive.withOpacity(0.38),
                      blurRadius: 14,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Icon(
            _isListening
                ? Icons.mic_rounded
                : Icons.mic_none_rounded,
            color:
                _isListening ? Colors.white : AppColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}