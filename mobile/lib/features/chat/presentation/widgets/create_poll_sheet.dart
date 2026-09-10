import 'package:flutter/material.dart';

class CreatePollSheet extends StatefulWidget {
  final Function(String question, List<String> options) onSubmit;

  const CreatePollSheet({super.key, required this.onSubmit});

  static void show(
    BuildContext context, {
    required Function(String question, List<String> options) onSubmit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => CreatePollSheet(
        onSubmit: (question, options) {
          Navigator.pop(ctx);
          onSubmit(question, options);
        },
      ),
    );
  }

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final _questionController = TextEditingController(text: 'What should be our priority for this sprint?');
  final List<TextEditingController> _optionControllers = [
    TextEditingController(text: 'UI Polish & Micro-interactions'),
    TextEditingController(text: 'WebRTC Video Calling'),
    TextEditingController(text: 'Payment Integrations'),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        final removed = _optionControllers.removeAt(index);
        removed.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.poll_rounded, color: Color(0xFF8B5CF6), size: 22),
              ),
              const SizedBox(width: 12),
              Text('Create Interactive Poll', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Poll Question',
              prefixIcon: Icon(Icons.help_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),

          Text('OPTIONS', style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1, color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 8),

          ..._optionControllers.asMap().entries.map((entry) {
            final idx = entry.key;
            final ctrl = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      decoration: InputDecoration(
                        hintText: 'Option ${idx + 1}',
                        prefixIcon: Icon(Icons.radio_button_unchecked_rounded, size: 18, color: cs.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => _removeOption(idx),
                    ),
                ],
              ),
            );
          }),

          if (_optionControllers.length < 6)
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Option'),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final question = _questionController.text.trim();
                final options = _optionControllers
                    .map((c) => c.text.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                if (question.isNotEmpty && options.length >= 2) {
                  widget.onSubmit(question, options);
                }
              },
              child: const Text('Create Poll', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
