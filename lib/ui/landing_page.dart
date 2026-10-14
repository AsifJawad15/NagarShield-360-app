import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({
    super.key,
    required this.bangla,
    required this.configured,
    required this.onLanguageChange,
    required this.onPublic,
    required this.onOfficial,
    required this.onDemo,
  });

  final bool bangla;
  final bool configured;
  final ValueChanged<bool> onLanguageChange;
  final VoidCallback onPublic;
  final VoidCallback onOfficial;
  final VoidCallback onDemo;

  String t(String en, String bn) => bangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        const _BrandMark(),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Nagar Shield 360',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF173F35),
                            ),
                          ),
                        ),
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 6),
                            ),
                          ),
                          segments: const [
                            ButtonSegment(value: true, label: Text('বাংলা')),
                            ButtonSegment(value: false, label: Text('EN')),
                          ],
                          selected: {bangla},
                          onSelectionChanged: (value) =>
                              onLanguageChange(value.first),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173F35),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(
                            'A clearer way to care for our streets',
                            'পাড়ার সমস্যা, সমাধানের খবর—এক জায়গায়',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFC8E6AF),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          t(
                            'See a problem? Help get it fixed.',
                            'সমস্যা চোখে পড়েছে? জানান, তারপর কী হলো দেখুন।',
                          ),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          t(
                            'Report a blocked drain, standing water, waste or an unsafe walkway. City staff review reports, assign work and record the result.',
                            'ড্রেন বন্ধ, পানি জমে আছে, ময়লা পড়ে আছে বা হাঁটার পথে বাধা? ছবি ও জায়গা দিয়ে জানান। দায়িত্বপ্রাপ্ত কর্মীরা দেখে কাজের ব্যবস্থা নেবেন।',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFD3E5DA),
                            fontSize: 15,
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onPublic,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFC9E9A5),
                              foregroundColor: const Color(0xFF173F35),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: Text(t('Report a problem', 'সমস্যা জানান')),
                          ),
                        ),
                        const SizedBox(height: 9),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onOfficial,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF9BBDAA)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.badge_outlined),
                            label: Text(
                              t('Official sign in', 'কর্মকর্তা হিসেবে সাইন ইন'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _MapIllustration(bangla: bangla),
                        const SizedBox(height: 8),
                        Text(
                          t(
                            'Illustrative demo view · No live AI detection',
                            'ডেমোর নমুনা দৃশ্য · সরাসরি AI শনাক্তকরণ নয়',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFB5C9BC),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('How it works', 'যেভাবে কাজ হয়'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF173F35),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t(
                            'From a report to a verified result.',
                            'সমস্যা জানানোর পর থেকে কাজ শেষ হওয়া পর্যন্ত প্রতিটি ধাপ দেখা যায়।',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF5D7569),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StepCard(
                          number: t('01', '০১'),
                          icon: Icons.camera_alt_outlined,
                          title: t('Send a report', 'সমস্যা জানান'),
                          body: t(
                            'Choose the issue, mark the location and add a photo if you have one.',
                            'কী সমস্যা, কোথায় হয়েছে, সঙ্গে ছবি থাকলে সেটিও দিন।',
                          ),
                        ),
                        _StepCard(
                          number: t('02', '০২'),
                          icon: Icons.fact_check_outlined,
                          title: t('Staff review it', 'কর্মকর্তারা যাচাই করেন'),
                          body: t(
                            'An authorised official checks the report before assigning any work.',
                            'কাজ দেওয়ার আগে দায়িত্বপ্রাপ্ত কর্মকর্তা প্রতিবেদনটি যাচাই করেন।',
                          ),
                        ),
                        _StepCard(
                          number: t('03', '০৩'),
                          icon: Icons.construction_outlined,
                          title: t(
                            'Work is recorded',
                            'কাজের অগ্রগতি দেখা যায়',
                          ),
                          body: t(
                            'Field staff submit after-work evidence; supervisors review the result.',
                            'মাঠকর্মী কাজের পরের ছবি দেন। তদারককারী কাজটি দেখে অনুমোদন করেন।',
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1E5),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('Explore the prototype', 'ডেমোটি ঘুরে দেখুন'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF173F35),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t(
                                  'The local demo shows the complete work cycle, even without internet. Its records are separate from live reports.',
                                  'ইন্টারনেট না থাকলেও স্থানীয় ডেমোয় পুরো কাজের ধাপ দেখা যাবে। ডেমোর তথ্য আসল প্রতিবেদন থেকে আলাদা।',
                                ),
                                style: const TextStyle(
                                  height: 1.5,
                                  color: Color(0xFF466456),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: onDemo,
                                icon: const Icon(Icons.play_circle_outline),
                                label: Text(
                                  t('Open local demo', 'স্থানীয় ডেমো খুলুন'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          configured
                              ? t(
                                  'Connected reports are shared with the official web system.',
                                  'ইন্টারনেট থাকলে প্রতিবেদন ওয়েবের কর্মকর্তাদের কাছেও পৌঁছায়।',
                                )
                              : t(
                                  'Shared data is unavailable. The local demo still works.',
                                  'ওয়েবের সঙ্গে সংযোগ নেই। স্থানীয় ডেমো ব্যবহার করতে পারবেন।',
                                ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF657B6E),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 39,
    height: 39,
    decoration: BoxDecoration(
      color: const Color(0xFF173F35),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.shield_outlined, color: Color(0xFFC9E9A5)),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });
  final String number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE8DB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F2DF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF287456)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number  $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF173F35),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF5D7569),
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapIllustration extends StatelessWidget {
  const _MapIllustration({required this.bangla});
  final bool bangla;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: 188,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StreetPainter()),
          Positioned(
            top: 13,
            left: 14,
            child: _MapTag(bangla ? 'নমুনা এলাকা' : 'Sample area'),
          ),
          const Positioned(
            top: 63,
            left: 90,
            child: Icon(Icons.location_on, size: 35, color: Color(0xFFE8A451)),
          ),
          const Positioned(
            top: 35,
            right: 75,
            child: Icon(Icons.location_on, size: 34, color: Color(0xFFD77C65)),
          ),
          const Positioned(
            bottom: 28,
            right: 96,
            child: Icon(Icons.location_on, size: 33, color: Color(0xFF4D9E7D)),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 18,
                    color: Color(0xFFB87D34),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      bangla
                          ? 'জমে থাকা পানি · যাচাইয়ের অপেক্ষায়'
                          : 'Standing water · awaiting review',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF365749),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapTag extends StatelessWidget {
  const _MapTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        color: Color(0xFF365749),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _StreetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE4EDE4),
    );
    final block = Paint()..color = const Color(0xFFD3E3D5);
    for (final rect in [
      Rect.fromLTWH(10, 12, size.width * .23, 52),
      Rect.fromLTWH(size.width * .37, 9, size.width * .2, 44),
      Rect.fromLTWH(size.width * .69, 11, size.width * .28, 63),
      Rect.fromLTWH(10, 93, size.width * .27, 55),
      Rect.fromLTWH(size.width * .43, 106, size.width * .24, 56),
      Rect.fromLTWH(size.width * .74, 95, size.width * .2, 57),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        block,
      );
    }
    final roadBorder = Paint()
      ..color = const Color(0xFFC4D7C9)
      ..strokeWidth = 34
      ..style = PaintingStyle.stroke;
    final road = Paint()
      ..color = const Color(0xFFFCFDF8)
      ..strokeWidth = 25
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(-15, size.height * .43)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .34,
        size.width + 15,
        size.height * .59,
      );
    canvas.drawPath(path, roadBorder);
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
