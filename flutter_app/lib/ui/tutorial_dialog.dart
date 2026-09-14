import 'package:flutter/material.dart';

Future<void> showTutorial(BuildContext context) => showDialog<void>(
  context: context, barrierDismissible: false, builder: (_) => const _TutorialDialog());

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog();
  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}
class _TutorialDialogState extends State<_TutorialDialog> {
  int step = 0;
  static const steps = [
    ('Ketuk untuk menjatuhkan', 'Ketuk posisi di dalam papan. Buah langsung jatuh di posisi tersebut. Tunggu indikator siap sebelum mengetuk lagi.'),
    ('Gabungkan buah yang sama', 'Dua buah yang sama akan menjadi buah yang lebih besar. Lihat urutan buah di bawah papan dan buah berikutnya di atas.'),
    ('Jaga buah di bawah garis', 'Buah yang melewati garis bahaya terlalu lama mengakhiri permainan. Hitung mundur memberi waktu untuk menyelamatkan papan dengan merge.'),
  ];
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${step + 1}/3 • ${steps[step].$1}'),
    content: SingleChildScrollView(child: Text(steps[step].$2)),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Lewati')),
      TextButton(onPressed: () { if (step == 2) { Navigator.pop(context); } else { setState(() => step++); } }, child: Text(step == 2 ? 'Mulai' : 'Berikutnya'))],
  );
}
