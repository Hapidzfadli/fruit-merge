import 'package:flutter/material.dart';

Future<void> showTutorial(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const _TutorialDialog(),
);

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog();
  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  int step = 0;
  static const steps = [
    (
      'Tap to drop',
      'Tap a position inside the board to drop a fruit there. Wait for the Ready indicator before tapping again.',
    ),
    (
      'Merge matching fruits',
      'Two matching fruits merge into a larger one. Check the fruit sequence below the board and the next fruit above it.',
    ),
    (
      'Keep fruits below the line',
      'The game ends if a fruit stays above the danger line too long. Use the countdown to make a merge and save your board.',
    ),
  ];
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${step + 1}/3 • ${steps[step].$1}'),
    content: SingleChildScrollView(child: Text(steps[step].$2)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Skip'),
      ),
      TextButton(
        onPressed: () {
          if (step == 2) {
            Navigator.pop(context);
          } else {
            setState(() => step++);
          }
        },
        child: Text(step == 2 ? 'Start' : 'Next'),
      ),
    ],
  );
}
