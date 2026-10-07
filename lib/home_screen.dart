import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _ink = Color(0xFF173B36);
const _deep = Color(0xFF143E35);
const _mint = Color(0xFFBDE998);
const _muted = Color(0xFF6F887B);
const _paper = Color(0xFFF6F8F3);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _approachKey = GlobalKey();
  final _pilotKey = GlobalKey();

  void _showSection(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _paper,
      ),
      child: Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _HomeHeader(),
                      const SizedBox(height: 27),
                      _HeroCard(
                        onApproach: () => _showSection(_approachKey),
                        onPilot: () => _showSection(_pilotKey),
                      ),
                      const SizedBox(height: 18),
                      const _MapPreviewCard(),
                      const SizedBox(height: 24),
                      const _OverviewMetrics(),
                      const SizedBox(height: 52),
                      _ApproachSection(key: _approachKey),
                      const SizedBox(height: 50),
                      const _WorkflowSection(),
                      const SizedBox(height: 50),
                      _PilotSection(key: _pilotKey),
                      const SizedBox(height: 38),
                      const _HomeFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 41,
        height: 41,
        decoration: BoxDecoration(
          color: _deep,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.verified_user_outlined, color: _mint, size: 25),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'Nagar Shield 360',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ),
      if (MediaQuery.sizeOf(context).width >= 370)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F1E2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'পাইলট ধারণা',
            style: TextStyle(
              color: Color(0xFF4B8962),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ],
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onApproach, required this.onPilot});

  final VoidCallback onApproach;
  final VoidCallback onPilot;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5544), Color(0xFF113B34), Color(0xFF0D302D)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -90,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x3349A483), width: 25),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            right: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1011BC88),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow(label: 'বাংলাদেশের নগরের জন্য', light: true),
                const SizedBox(height: 22),
                const Text(
                  'প্রতিটি রাস্তার',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'আরও পরিষ্কার চিত্র।',
                  style: TextStyle(
                    color: _mint,
                    fontSize: 31,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'দৃশ্যমান সমস্যাগুলো মানচিত্রে দেখুন, মাঠপর্যায়ে যাচাই করুন এবং কাজের ফল বুঝুন।',
                  style: TextStyle(
                    color: Color(0xFFD0E3D6),
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 25),
                Wrap(
                  spacing: 8,
                  runSpacing: 9,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: onApproach,
                      style: FilledButton.styleFrom(
                        backgroundColor: _mint,
                        foregroundColor: _deep,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text(
                        'পদ্ধতি দেখুন',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: onPilot,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('পাইলটের পরিধি'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE3EBE2)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1636634D),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        SizedBox(
          height: 252,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _StreetMapPainter()),
                ),
                Positioned(
                  left: 15,
                  top: 15,
                  child: _MapLabel(
                    icon: Icons.layers_outlined,
                    text: 'ধারণামূলক মানচিত্র',
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * .32,
                  top: 74,
                  child: const _MapDot(color: Color(0xFFE6A84B)),
                ),
                Positioned(
                  left: constraints.maxWidth * .66,
                  top: 100,
                  child: const _MapDot(color: Color(0xFFE07C69)),
                ),
                Positioned(
                  left: constraints.maxWidth * .77,
                  top: 48,
                  child: const _MapDot(color: Color(0xFF54AA82)),
                ),
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 15,
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26395D47),
                          blurRadius: 16,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        _ObservationIcon(),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'যাচাইয়ের জন্য',
                                style: TextStyle(
                                  color: Color(0xFFB48B50),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'জমে থাকা পানি',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'নমুনা তথ্য',
                          style: TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Wrap(
            spacing: 16,
            runSpacing: 9,
            children: [
              _LegendDot(color: Color(0xFFE6A84B), text: 'পানি'),
              _LegendDot(color: Color(0xFFE07C69), text: 'বর্জ্য'),
              _LegendDot(color: Color(0xFF54AA82), text: 'ড্রেনের পথ'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF5D9377), size: 14),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: _ink,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _MapDot extends StatelessWidget {
  const _MapDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 25,
    height: 25,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x4D2B5141),
          blurRadius: 9,
          offset: Offset(0, 3),
        ),
      ],
    ),
  );
}

class _ObservationIcon extends StatelessWidget {
  const _ObservationIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 35,
    height: 35,
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1DD),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.water_drop_outlined,
      color: Color(0xFFC88C39),
      size: 20,
    ),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: _muted, fontSize: 11)),
    ],
  );
}

class _OverviewMetrics extends StatelessWidget {
  const _OverviewMetrics();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: _Metric(value: '৬', label: 'পর্যবেক্ষণের বিষয়'),
      ),
      SizedBox(width: 8),
      Expanded(
        child: _Metric(value: '৩০০–৫০০', label: 'মিটার পাইলট'),
      ),
      SizedBox(width: 8),
      Expanded(
        child: _Metric(value: 'মানুষ', label: 'চূড়ান্ত যাচাই'),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 116,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F0E5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF438765),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 10,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ApproachSection extends StatelessWidget {
  const _ApproachSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow(label: 'আমাদের পদ্ধতি'),
      const SizedBox(height: 12),
      const Text(
        'সঠিক সিদ্ধান্তের শুরু\nপ্রাসঙ্গিক তথ্য থেকে।',
        style: _sectionTitle,
      ),
      const SizedBox(height: 12),
      const Text(
        'একটি রাস্তার একাধিক সমস্যা একসঙ্গে দেখা গেলে কোন স্থান আগে পরিদর্শন করা দরকার, তা বোঝা সহজ হয়।',
        style: _sectionBody,
      ),
      const SizedBox(height: 23),
      const _FeatureCard(
        icon: Icons.center_focus_strong_outlined,
        number: '০১',
        title: 'দৃশ্যমান সমস্যা শনাক্ত',
        body:
            'অনুমোদিত উৎসের ছবি থেকে পানি, বর্জ্য, ড্রেন ও চলাচলের বাধা দেখুন।',
      ),
      const SizedBox(height: 11),
      const _FeatureCard(
        icon: Icons.layers_outlined,
        number: '০২',
        title: 'এক এলাকার তথ্য একসঙ্গে',
        body: 'কাছাকাছি পর্যবেক্ষণগুলো যুক্ত করে রাস্তার পরিস্থিতি বুঝুন।',
      ),
      const SizedBox(height: 11),
      const _FeatureCard(
        icon: Icons.verified_outlined,
        number: '০৩',
        title: 'কাজের ফল যাচাই',
        body: 'মাঠকর্মীর সিদ্ধান্ত এবং কাজের আগে ও পরের প্রমাণ নথিবদ্ধ করুন।',
      ),
    ],
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.number,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE7EDE5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2E5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF559774), size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          number,
          style: const TextStyle(
            color: Color(0xFFAAC6AD),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(23, 27, 23, 25),
    decoration: BoxDecoration(
      color: _deep,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(label: 'কাজের ধাপ', light: true),
        SizedBox(height: 12),
        Text(
          'দেখুন। যাচাই করুন।\nউন্নতি আনুন।',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'প্রতিটি ধাপে নগর কর্তৃপক্ষের সিদ্ধান্তই মুখ্য।',
          style: TextStyle(color: Color(0xFFB4CFBE), fontSize: 13, height: 1.7),
        ),
        SizedBox(height: 18),
        _WorkflowStep(
          number: '০১',
          title: 'শনাক্ত ও মানচিত্রায়ন',
          body: 'দৃশ্যমান সমস্যার অবস্থান চিহ্নিত করুন।',
        ),
        _WorkflowStep(
          number: '০২',
          title: 'যাচাই ও পদক্ষেপ',
          body: 'মাঠকর্মী তথ্য যাচাই করে করণীয় ঠিক করেন।',
        ),
        _WorkflowStep(
          number: '০৩',
          title: 'ফল পুনরায় যাচাই',
          body: 'পরের তথ্য আগের সঙ্গে তুলনা করুন।',
          last: true,
        ),
      ],
    ),
  );
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.number,
    required this.title,
    required this.body,
    this.last = false,
  });
  final String number;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0x335F9A77))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: _mint,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFFABC9B7),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PilotSection extends StatelessWidget {
  const _PilotSection({super.key});

  static const categories = [
    'জমে থাকা পানি',
    'ড্রেন ও পানিনিষ্কাশন মুখ',
    'দৃশ্যমান বর্জ্য',
    'পানি জমার পাত্র',
    'রাস্তার পাশের বাধা',
    'চলাচলে বাধা',
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow(label: 'ছোট পরিসরে শুরু'),
      const SizedBox(height: 12),
      const Text('বাংলাদেশের জন্য\nসুনির্দিষ্ট পাইলট।', style: _sectionTitle),
      const SizedBox(height: 11),
      const Text(
        'প্রস্তাবিত ৩০০–৫০০ মিটার এলাকায় কাজের ধাপ পরীক্ষা ও স্থানীয় তথ্য সংগ্রহ করা যাবে।',
        style: _sectionBody,
      ),
      const SizedBox(height: 21),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3EBE2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'প্রাথমিক পর্যবেক্ষণের ৬টি বিষয়',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map(
                    (category) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F6EC),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Color(0xFF3B7757),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 17),
            const Text(
              'দৃশ্যমান সমস্যাগুলো পরিদর্শনের সম্ভাব্য স্থান নির্দেশ করে। প্রতিটি সিদ্ধান্তে মানুষের যাচাই প্রয়োজন।',
              style: TextStyle(color: _muted, fontSize: 11, height: 1.7),
            ),
          ],
        ),
      ),
    ],
  );
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Icon(Icons.verified_user_outlined, color: Color(0xFF6CA378), size: 24),
      SizedBox(height: 8),
      Text(
        'Nagar Shield 360',
        style: TextStyle(
          color: _ink,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      SizedBox(height: 3),
      Text(
        'নিরাপদ ও সুস্থ নগরের পথে',
        style: TextStyle(color: _muted, fontSize: 11),
      ),
    ],
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label, this.light = false});
  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 17,
        height: 2,
        color: light ? _mint : const Color(0xFF76B486),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            color: light ? _mint : const Color(0xFF4D956B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

const _sectionTitle = TextStyle(
  color: _ink,
  fontSize: 27,
  height: 1.28,
  fontWeight: FontWeight.w800,
);
const _sectionBody = TextStyle(color: _muted, fontSize: 13, height: 1.75);

class _StreetMapPainter extends CustomPainter {
  const _StreetMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 252);
    canvas.drawColor(const Color(0xFFEAF1E9), BlendMode.src);

    final block = Paint()..color = const Color(0xFFD3E3D7);
    for (final rect in [
      const Rect.fromLTWH(10, 13, 92, 67),
      const Rect.fromLTWH(132, 8, 105, 64),
      const Rect.fromLTWH(15, 105, 103, 70),
      const Rect.fromLTWH(142, 106, 99, 60),
      const Rect.fromLTWH(282, 15, 106, 68),
      const Rect.fromLTWH(293, 113, 96, 55),
      const Rect.fromLTWH(25, 198, 95, 41),
      const Rect.fromLTWH(145, 204, 112, 37),
      const Rect.fromLTWH(289, 201, 96, 41),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        block,
      );
    }

    final horizontal = Path()
      ..moveTo(-25, 192)
      ..cubicTo(95, 147, 181, 185, 250, 157)
      ..cubicTo(312, 133, 365, 137, 425, 95);
    final vertical = Path()
      ..moveTo(255, -30)
      ..cubicTo(248, 80, 267, 136, 264, 280);
    final edge = Paint()
      ..color = const Color(0xFFD5E2D7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 47;
    final road = Paint()
      ..color = const Color(0xFFFFFDF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36;
    canvas.drawPath(horizontal, edge);
    canvas.drawPath(horizontal, road);
    canvas.drawPath(vertical, edge);
    canvas.drawPath(vertical, road);

    final route = Path()
      ..moveTo(57, 179)
      ..cubicTo(151, 149, 203, 169, 262, 156)
      ..cubicTo(318, 144, 336, 138, 361, 123);
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0x8852A780)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StreetMapPainter oldDelegate) => false;
}
