import 'package:flutter/material.dart';

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFE5F3E7),
    child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
  );
}
