import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/aki_cricket_screen.dart';
import 'screens/watch_party_screen.dart';
import 'widgets/app_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF060B18),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const IPLAISuiteApp());
}

class IPLAISuiteApp extends StatelessWidget {
  const IPLAISuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPL AI Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.navy,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.blue,
          secondary: AppColors.gold,
          surface: AppColors.navyLight,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SPLASH SCREEN
// ══════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1400),
  )..forward();
  late final AnimationController _orbitCtrl = AnimationController(
    vsync: this, duration: const Duration(seconds: 8),
  )..repeat();

  late final Animation<double> _scaleAnim = CurvedAnimation(
    parent: _scaleCtrl, curve: Curves.elasticOut,
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _scaleCtrl, curve: const Interval(0.0, 0.5),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim, child: child,
          ),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() { _scaleCtrl.dispose(); _orbitCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(children: [
        // Animated background orbs
        AnimatedBuilder(
          animation: _orbitCtrl,
          builder: (_, __) => Stack(children: [
            // Orbital glow 1
            Positioned(
              left: MediaQuery.of(context).size.width / 2 + 100 * cos(_orbitCtrl.value * 2 * pi) - 60,
              top:  MediaQuery.of(context).size.height / 2 + 80 * sin(_orbitCtrl.value * 2 * pi) - 60,
              child: Container(width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppColors.blue.withOpacity(0.1),
                  boxShadow: [BoxShadow(color: AppColors.blue.withOpacity(0.15), blurRadius: 40)])),
            ),
            // Orbital glow 2
            Positioned(
              left: MediaQuery.of(context).size.width / 2 + 130 * cos(_orbitCtrl.value * 2 * pi + pi) - 50,
              top:  MediaQuery.of(context).size.height / 2 + 100 * sin(_orbitCtrl.value * 2 * pi + pi) - 50,
              child: Container(width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.08),
                  boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.12), blurRadius: 30)])),
            ),
            // Orbital glow 3
            Positioned(
              left: MediaQuery.of(context).size.width / 2 + 80 * cos(_orbitCtrl.value * 2 * pi + pi / 2) - 40,
              top:  MediaQuery.of(context).size.height / 2 + 140 * sin(_orbitCtrl.value * 2 * pi + pi / 2) - 40,
              child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppColors.purple.withOpacity(0.1))),
            ),
          ]),
        ),

        // Static large ambient orbs
        Positioned(top: -100, left: -80, child: Container(width: 300, height: 300,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.blue.withOpacity(0.05)))),
        Positioned(bottom: -80, right: -60, child: Container(width: 260, height: 260,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(0.04)))),

        // Center content
        Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Glowing logo circle
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [AppColors.blue, AppColors.purple],
                    ),
                    boxShadow: [
                      BoxShadow(color: AppColors.blue.withOpacity(0.5), blurRadius: 50, spreadRadius: 10),
                      BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 30),
                    ],
                  ),
                  child: const Center(child: Text('🏏', style: TextStyle(fontSize: 58))),
                ),
                const SizedBox(height: 36),

                // App title with gradient
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.blue, AppColors.gold],
                  ).createShader(b),
                  child: Text('IPL AI Suite',
                    style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                ),
                const SizedBox(height: 10),

                Text('Powered by Gemini Flash & Firebase',
                  style: GoogleFonts.inter(color: AppColors.blue, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Text('GDG Hackathon 2026',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 52),

                // Loading bar
                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      backgroundColor: Color(0x22FFFFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
                      minHeight: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Initializing Gemini AI Engine...',
                  style: GoogleFonts.inter(color: AppColors.textMuted.withOpacity(0.6), fontSize: 11)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// HOME SCREEN
// ══════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentTab = 0;

  late final AnimationController _floatCtrl = AnimationController(
    vsync: this, duration: const Duration(seconds: 4),
  )..repeat(reverse: true);
  late final AnimationController _bgCtrl = AnimationController(
    vsync: this, duration: const Duration(seconds: 12),
  )..repeat();

  late final Animation<double> _floatAnim = Tween<double>(begin: 0, end: 14)
    .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

  @override
  void dispose() { _floatCtrl.dispose(); _bgCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: IndexedStack(
        index: _currentTab,
        children: const [
          _HomeTab(),
          AkiCricketScreen(),
          WatchPartyScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyLight,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded,     'Home'),
              _navItem(1, Icons.psychology_rounded,'Aki'),
              _navItem(2, Icons.mic_rounded,       'Party'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final active = _currentTab == idx;
    final colors = [AppColors.blue, AppColors.blue, AppColors.purple];
    final color  = colors[idx];
    return GestureDetector(
      onTap: () => setState(() => _currentTab = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: active ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? color : AppColors.textMuted, size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            color: active ? color : AppColors.textMuted,
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// HOME TAB
// ══════════════════════════════════════════════════════════════════
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with TickerProviderStateMixin {
  late final AnimationController _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  late final AnimationController _ringCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  late final Animation<double> _floatAnim   = Tween<double>(begin: 0, end: 16).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  late final Animation<double> _ringAnim    = Tween<double>(begin: 0, end: 1).animate(_ringCtrl);

  @override
  void dispose() { _floatCtrl.dispose(); _ringCtrl.dispose(); super.dispose(); }

  void _navigate(int tab) {
    final homeScreen = context.findAncestorStateOfType<_HomeScreenState>();
    homeScreen?.setState(() => homeScreen._currentTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(children: [
        // Ambient background orbs
        Positioned(top: -60, left: -40, child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.blue.withOpacity(0.06)))),
        Positioned(top: 200, right: -60, child: Container(width: 180, height: 180,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(0.05)))),
        Positioned(bottom: 100, left: -40, child: Container(width: 160, height: 160,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.purple.withOpacity(0.06)))),

        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              // ── GDG Banner ─────────────────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navyCard,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Row(children: const [
                    _GdgDot(color: Color(0xFF4285F4)),
                    SizedBox(width: 4),
                    _GdgDot(color: Color(0xFFEA4335)),
                    SizedBox(width: 4),
                    _GdgDot(color: Color(0xFFFBBC04)),
                    SizedBox(width: 4),
                    _GdgDot(color: Color(0xFF34A853)),
                  ]),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text('GDG Hackathon 2026 · PS1 & PS2 Solved',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ).animate().fadeIn(delay: 100.ms),

              // ── Hero Section ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  // Stadium image card without overlapping 3D elements in the center
                  Stack(alignment: Alignment.center, children: [
                    // Stadium image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(AppColors.navy.withOpacity(0.55), BlendMode.darken),
                        child: Image.asset('assets/images/ipl_stadium.png', height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ),
                    // Hero text overlay
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      GradText('IPL AI Suite', fontSize: 32, colors: [AppColors.blue, AppColors.gold], textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      const Text('Two AI experiences · One app',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ]).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 20),

                  // Tech badges
                  Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: const [
                    NeonBadge('✨ Gemini Flash', color: AppColors.blue),
                    NeonBadge('🔥 Firebase',     color: AppColors.gold),
                    NeonBadge('📱 Flutter',       color: AppColors.green),
                    NeonBadge('🏏 IPL',           color: AppColors.coral),
                  ]).animate().fadeIn(delay: 250.ms),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Stats Strip ────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: const [
                  _StatChip('1,247', 'Games Played'),
                  SizedBox(width: 10),
                  _StatChip('87%',   'AI Accuracy'),
                  SizedBox(width: 10),
                  _StatChip('15',    'Max Questions'),
                  SizedBox(width: 10),
                  _StatChip('8',     'Trivia Rounds'),
                  SizedBox(width: 10),
                  _StatChip('2 min', 'Timer'),
                ]),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),

              // ── PS1 Card ───────────────────────────────────────
              _PSCard(
                index: 1,
                title: 'Aki-Cricket',
                subtitle: 'The AI IPL Akinator',
                desc: 'Think of any IPL player, team or match. Gemini AI has exactly 15 Yes/No questions to read your mind. With adaptive questioning, dynamic persona and Firebase leaderboards.',
                imagePath: 'assets/images/aki_character.png',
                accentColor: AppColors.blue,
                tags: const ['🧠 Adaptive AI', '⏱️ 2 Min', '🏆 Leaderboard', '🎊 Confetti Win'],
                onTap: () => _navigate(1),
                ctaLabel: '🎮  Play Now',
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.15),
              const SizedBox(height: 16),

              // ── PS2 Card ───────────────────────────────────────
              _PSCard(
                index: 2,
                title: 'AI Watch Party',
                subtitle: 'Meet Aria, Your AI Host',
                desc: 'Aria is your Gemini-powered IPL watch party host. She delivers live commentary, runs trivia rounds, announces milestones, conducts giveaways and answers audience questions.',
                imagePath: 'assets/images/aria_host.png',
                accentColor: AppColors.purple,
                tags: const ['🎙️ Commentary', '🎯 Trivia', '📣 Milestones', '🎁 Giveaways', '💬 Chat'],
                onTap: () => _navigate(2),
                ctaLabel: '🎉  Start Party',
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15),
              const SizedBox(height: 24),

              // ── All Features Grid ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Text('All Features', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.55,
                    children: const [
                      _FeatureCard('🧠', 'Adaptive AI',       'Binary-search questioning strategy', AppColors.blue,   'PS1'),
                      _FeatureCard('😤', 'Live Persona',       '5 dynamic AI moods as Q count rises', AppColors.purple,'PS1'),
                      _FeatureCard('⏱️', '2-Min Timer',        'Animated countdown with color alerts', AppColors.coral, 'PS1'),
                      _FeatureCard('🏆', 'Leaderboard',        'Global Firebase win streak tracking', AppColors.gold,  'PS1'),
                      _FeatureCard('🎙️', 'Commentary',         'Streaming Harsha Bhogle-style narration', AppColors.blue,'PS2'),
                      _FeatureCard('🎯', 'IPL Trivia',         '8 rounds, 15 sec each, real scores', AppColors.green, 'PS2'),
                      _FeatureCard('📣', 'Milestones',         '8 milestone types — SIX, WICKET...', AppColors.gold,  'PS2'),
                      _FeatureCard('🎁', 'Giveaways',          'Dramatic AI winner selection', AppColors.coral,       'PS2'),
                      _FeatureCard('💬', 'Ask Aria',           'Live audience Q&A with AI host', AppColors.purple,    'PS2'),
                      _FeatureCard('📊', 'Stats Tracking',     'Wins, streaks, scores — all saved', AppColors.blue,   'Both'),
                      _FeatureCard('🗂️', 'Category Picker',    'Player / Team / Match categories', AppColors.green,   'PS1'),
                      _FeatureCard('📱', 'Native Flutter',     'Full native Android app, no WebView', AppColors.blue, 'App'),
                    ],
                  ),
                ]),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 32),

              // ── Footer ─────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.navyCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  GradText('🏏 IPL AI Suite', fontSize: 18, colors: [AppColors.blue, AppColors.gold]),
                  const SizedBox(height: 8),
                  const Text('Built for GDG Hackathon 2026', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    NeonBadge('✨ Gemini Flash', color: AppColors.blue),
                    SizedBox(width: 8),
                    NeonBadge('🔥 Firebase', color: AppColors.gold),
                  ]),
                ]),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════

class _GdgDot extends StatelessWidget {
  final Color color;
  const _GdgDot({required this.color});
  @override
  Widget build(BuildContext context) =>
    Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip(this.value, this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
    );
  }
}

class _PSCard extends StatefulWidget {
  final int index;
  final String title, subtitle, desc, imagePath, ctaLabel;
  final Color accentColor;
  final List<String> tags;
  final VoidCallback onTap;

  const _PSCard({
    required this.index, required this.title, required this.subtitle,
    required this.desc, required this.imagePath, required this.accentColor,
    required this.tags, required this.onTap, required this.ctaLabel,
  });
  @override State<_PSCard> createState() => _PSCardState();
}

class _PSCardState extends State<_PSCard> with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  late final Animation<double> _scaleAnim   = Tween<double>(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));

  @override
  void dispose() { _hoverCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) { _hoverCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.navyCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.accentColor.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: widget.accentColor.withOpacity(0.08), blurRadius: 24)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Image header
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(AppColors.navy.withOpacity(0.4), BlendMode.darken),
                  child: Image.asset(widget.imagePath, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
              // Gradient overlay
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.navyCard.withOpacity(0.9)]),
                ),
              ),
              // PS badge
              Positioned(top: 14, left: 14, child: NeonBadge('PS${widget.index}', color: widget.accentColor)),
              // Title in image
              Positioned(bottom: 14, left: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GradText(widget.title, fontSize: 22, colors: [widget.accentColor, widget.accentColor.withOpacity(0.7)]),
                Text(widget.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),

            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.desc, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, height: 1.65)),
                const SizedBox(height: 14),
                Wrap(spacing: 7, runSpacing: 7, children: widget.tags.map((t) => NeonBadge(t, color: widget.accentColor)).toList()),
                const SizedBox(height: 18),
                AppButton(
                  label: widget.ctaLabel,
                  color: widget.accentColor,
                  textColor: widget.accentColor == AppColors.blue ? AppColors.navy : Colors.white,
                  width: double.infinity,
                  onTap: widget.onTap,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon, title, desc, badge;
  final Color color;
  const _FeatureCard(this.icon, this.title, this.desc, this.color, this.badge);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(50), border: Border.all(color: color.withOpacity(0.25))),
            child: Text(badge, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Expanded(child: Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
