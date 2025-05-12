import 'package:flutter/material.dart';
import 'package:flutter/services.dart';        // HapticFeedback
import 'package:provider/provider.dart';
import '../../providers/accessibility_provider.dart';

class BrailleInteractionOverlay extends StatefulWidget {
  /// Called when the user taps “Send”
  final ValueChanged<String> onSend;

  const BrailleInteractionOverlay({Key? key, required this.onSend})
      : super(key: key);

  @override
  _BrailleInteractionOverlayState createState() =>
      _BrailleInteractionOverlayState();
}

class _BrailleInteractionOverlayState
    extends State<BrailleInteractionOverlay> {
  static const int dotCount = 6;

  /// Tracks which of the 6 dots are “up”
  List<bool> _dots = List<bool>.filled(dotCount, false);

  String _braillePattern  = '';
  String _translatedText  = '';

  /// Uncontracted Grade-1 Braille map (6-bit string → character)
  static const Map<String, String> _brailleMap = {
    // A–Z
    '100000': 'A', '110000': 'B', '100100': 'C', '100110': 'D',
    '100010': 'E', '110100': 'F', '110110': 'G', '110010': 'H',
    '010100': 'I', '010110': 'J', '101000': 'K', '111000': 'L',
    '101100': 'M', '101110': 'N', '101010': 'O', '111100': 'P',
    '111110': 'Q', '111010': 'R', '011100': 'S', '011110': 'T',
    '101001': 'U', '111001': 'V', '010111': 'W', '101101': 'X',
    '101111': 'Y', '101011': 'Z',

    // Space & punctuation
    '000000': ' ',
    '010000': ',',  // comma
    '011000': ';',  // semicolon
    '010010': ':',  // colon
    '010011': '.',  // period
    '011010': '!',  // exclamation
    '010001': '?',  // question (dots 2+6)
    '001001': '-',  // hyphen
    '001000': '\'', // apostrophe
  };

  void _toggleDot(int i) {
    HapticFeedback.lightImpact();
    setState(() {
      _dots[i] = !_dots[i];
      _updateTranslation();
    });
  }

  void _updateTranslation() {
    final key = _dots.map((b) => b ? '1' : '0').join();
    _braillePattern = _dots.map((b) => b ? '●' : '○').join();
    _translatedText = _brailleMap[key] ?? '';
  }

  void _send() {
    if (_translatedText.isEmpty) return;
    widget.onSend(_translatedText);
    _clearAll();
  }

  void _clearAll() {
    HapticFeedback.vibrate();
    setState(() {
      _dots           = List<bool>.filled(dotCount, false);
      _braillePattern = '';
      _translatedText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccessibilityProvider>();
    if (!acc.isBrailleOn) return const SizedBox.shrink();
    final pc = Theme.of(context).primaryColor;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Material(
        elevation: 12,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Braille Input Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pc,
                  )),
              const SizedBox(height: 12),

              // The six dot buttons
              Wrap(
                spacing: 12, runSpacing: 12,
                children: List.generate(dotCount, (i) {
                  return GestureDetector(
                    onTap: () => _toggleDot(i),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: _dots[i] ? pc : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),
              Text('Pattern: $_braillePattern',
                  style: acc.getTextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Character: ${_translatedText.isNotEmpty ? _translatedText : '-'}',
                style: acc.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: pc,
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _translatedText.isEmpty ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pc,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Send',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAll,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}