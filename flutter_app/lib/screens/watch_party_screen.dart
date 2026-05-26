import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_widgets.dart';
import '../models/game_models.dart';

// ──────────────────────────────────────────────────────────────────
// Watch Party Screen
// ──────────────────────────────────────────────────────────────────
class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});
  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> with TickerProviderStateMixin {
  final _host = WatchPartyHost();
  bool _partyStarted = false;

  // Aria float animation
  late final AnimationController _ariaCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  late final Animation<double> _ariaAnim = Tween<double>(begin: 0.0, end: 12.0).animate(CurvedAnimation(parent: _ariaCtrl, curve: Curves.easeInOut));

  // Tab controller (6 sections)
  late final TabController _tabCtrl = TabController(length: 6, vsync: this);

  @override
  void dispose() { _ariaCtrl.dispose(); _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(children: [
        // BG
        Positioned(top: -80, right: -60, child: Container(width: 250, height: 250,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.purple.withOpacity(0.06)))),
        Positioned(bottom: -50, left: -50, child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(0.05)))),
        // Content
        SafeArea(child: Column(children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: TabBarView(
            controller: _tabCtrl,
            physics: const BouncingScrollPhysics(),
            children: [
              _WelcomeTab(host: _host, partyStarted: _partyStarted, onStart: () => setState(() => _partyStarted = true), ariaAnim: _ariaAnim, ariaCtrl: _ariaCtrl),
              _TriviaTab(host: _host),
              _CommentaryTab(host: _host),
              _MilestoneTab(host: _host),
              _GiveawayTab(host: _host),
              _ChatTab(host: _host),
            ],
          )),
        ])),
      ]),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppColors.purple, AppColors.blue]),
            boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 12)],
          ),
          child: const Center(child: Text('🎙️', style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GradText('AI Watch Party', fontSize: 20, colors: [AppColors.purple, AppColors.blue]),
          Text('Aria · Gemini Flash AI', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
        const Spacer(),
        if (_partyStarted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.12),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.coral.withOpacity(0.4)),
            ),
            child: Row(children: [
              PulsingDot(color: AppColors.coral),
              const SizedBox(width: 5),
              const Text('LIVE', style: TextStyle(color: AppColors.coral, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 38,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.purple,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.purple,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.purple.withOpacity(0.12),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.purple.withOpacity(0.3)),
        ),
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: const [
          Tab(text: '🎙️ Welcome'),
          Tab(text: '🎯 Trivia'),
          Tab(text: '📺 Commentary'),
          Tab(text: '📣 Milestones'),
          Tab(text: '🎁 Giveaway'),
          Tab(text: '💬 Ask Aria'),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// 1. Welcome Tab
// ──────────────────────────────────────────────────────────────────
class _WelcomeTab extends StatefulWidget {
  final WatchPartyHost host;
  final bool partyStarted;
  final VoidCallback onStart;
  final Animation<double> ariaAnim;
  final AnimationController ariaCtrl;
  const _WelcomeTab({required this.host, required this.partyStarted, required this.onStart, required this.ariaAnim, required this.ariaCtrl});
  @override State<_WelcomeTab> createState() => _WelcomeTabState();
}

class _WelcomeTabState extends State<_WelcomeTab> {
  bool _loading = false;
  String _welcomeText = '';
  final _venueCtrl = TextEditingController(text: 'GDG IPL Night');

  Future<void> _start() async {
    widget.onStart();
    setState(() { _loading = true; _welcomeText = ''; });
    try {
      final text = await widget.host.welcome(_venueCtrl.text.trim().isEmpty ? 'our party' : _venueCtrl.text.trim());
      setState(() { _welcomeText = text; _loading = false; });
    } catch (_) {
      setState(() { _welcomeText = '🎙️ Welcome to the most electric IPL watch party of the season! I\'m Aria, your Gemini AI host! The crowd is roaring, the atmosphere is ELECTRIC, and tonight we make history! Let\'s GO! 🏏🔥'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Aria image floating
        AnimatedBuilder(
          animation: widget.ariaAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, -widget.ariaAnim.value),
            child: Container(
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 30)]),
              child: Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/images/aria_host.png', fit: BoxFit.cover, width: double.infinity)),
                // Glow overlay
                Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.navy.withOpacity(0.8)]))),
                // LIVE badge
                Positioned(top: 12, left: 12, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.coral.withOpacity(0.9), borderRadius: BorderRadius.circular(50)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    PulsingDot(color: Colors.white), const SizedBox(width: 5),
                    const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ]),
                )),
                // Name
                Positioned(bottom: 14, left: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GradText('Aria', fontSize: 22, colors: [AppColors.purple, AppColors.blue]),
                  const Text('Your AI Watch Party Host', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ])),
              ]),
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),

        // Venue input
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Venue Name', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _venueCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. GDG IPL Night 2026',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.navyCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.purple)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: _loading ? '⏳  Aria is preparing...' : '🎉  Start Watch Party',
            color: AppColors.purple, textColor: Colors.white, width: double.infinity,
            onTap: _loading ? null : _start,
          ),
        ])).animate().fadeIn(delay: 200.ms),

        if (_loading) ...[const SizedBox(height: 20), const ThinkingDots()],

        if (_welcomeText.isNotEmpty) ...[
          const SizedBox(height: 16),
          GlassCard(
            borderColor: AppColors.purple.withOpacity(0.25),
            glowColor: AppColors.purple,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [PulsingDot(color: AppColors.purple), const SizedBox(width: 8),
                Text('Aria · Gemini Flash', style: GoogleFonts.outfit(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5))]),
              const SizedBox(height: 12),
              Text(_welcomeText, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.7)),
            ]),
          ).animate().fadeIn().slideY(begin: 0.2),
        ],
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// 2. Trivia Tab
// ──────────────────────────────────────────────────────────────────
class _TriviaTab extends StatefulWidget {
  final WatchPartyHost host;
  const _TriviaTab({required this.host});
  @override State<_TriviaTab> createState() => _TriviaTabState();
}

class _TriviaTabState extends State<_TriviaTab> with TickerProviderStateMixin {
  bool _started = false, _done = false;
  int _timeLeft = 15;
  Timer? _timer;
  bool _answered = false;
  bool? _lastCorrect;
  int _sessionScore = 0;

  late final AnimationController _timerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..addListener(() { setState(() {}); });

  @override
  void dispose() { _timer?.cancel(); _timerCtrl.dispose(); super.dispose(); }

  void _start() {
    widget.host.triviaIndex = 0; widget.host.correct = 0; widget.host.wrong = 0;
    setState(() { _started = true; _done = false; _sessionScore = 0; });
    _nextQ();
  }

  void _nextQ() {
    setState(() { _answered = false; _lastCorrect = null; _timeLeft = 15; });
    _timerCtrl.reset(); _timerCtrl.forward();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { _timer?.cancel(); _timeOut(); }
    });
  }

  void _answer(String opt) {
    if (_answered) return;
    _timer?.cancel(); _timerCtrl.stop();
    final correct = widget.host.answerTrivia(opt);
    if (correct) _sessionScore += 100;
    setState(() { _answered = true; _lastCorrect = correct; });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (widget.host.triviaComplete) setState(() => _done = true);
      else _nextQ();
    });
  }

  void _timeOut() {
    widget.host.wrong++;
    widget.host.triviaIndex++;
    setState(() { _answered = true; _lastCorrect = false; });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (widget.host.triviaComplete) setState(() => _done = true);
      else _nextQ();
    });
  }

  Color get _timerColor => _timeLeft <= 5 ? AppColors.coral : _timeLeft <= 10 ? Colors.orange : AppColors.blue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Score strip
        Row(children: [
          Expanded(child: GlassCard(padding: const EdgeInsets.all(14), borderColor: AppColors.green.withOpacity(0.2),
            child: Column(children: [Text('${widget.host.correct}', style: GoogleFonts.outfit(color: AppColors.green, fontSize: 26, fontWeight: FontWeight.w900)), const Text('Correct', style: TextStyle(color: AppColors.textMuted, fontSize: 10))]))),
          const SizedBox(width: 10),
          Expanded(child: GlassCard(padding: const EdgeInsets.all(14), borderColor: AppColors.coral.withOpacity(0.2),
            child: Column(children: [Text('${widget.host.wrong}', style: GoogleFonts.outfit(color: AppColors.coral, fontSize: 26, fontWeight: FontWeight.w900)), const Text('Wrong', style: TextStyle(color: AppColors.textMuted, fontSize: 10))]))),
          const SizedBox(width: 10),
          Expanded(child: GlassCard(padding: const EdgeInsets.all(14), borderColor: AppColors.gold.withOpacity(0.2),
            child: Column(children: [Text('$_sessionScore', style: GoogleFonts.outfit(color: AppColors.gold, fontSize: 26, fontWeight: FontWeight.w900)), const Text('Score', style: TextStyle(color: AppColors.textMuted, fontSize: 10))]))),
        ]),
        const SizedBox(height: 16),

        if (!_started) _buildReadyCard(),
        if (_started && !_done) _buildQuestion(),
        if (_done) _buildDoneCard(),
      ]),
    );
  }

  Widget _buildReadyCard() {
    return GlassCard(
      child: Column(children: [
        const Text('🎯', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        GradText('IPL Trivia', fontSize: 22, colors: [AppColors.gold, AppColors.blue]),
        const SizedBox(height: 8),
        const Text('8 rounds · 15 seconds each\nHow well do you know IPL?', textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.6)),
        const SizedBox(height: 20),
        AppButton(label: '▶️  Start Trivia', color: AppColors.gold, textColor: AppColors.navy, width: 200, onTap: _start),
      ]),
    ).animate().scale(curve: Curves.elasticOut);
  }

  Widget _buildQuestion() {
    final q = widget.host.currentTrivia;
    return Column(children: [
      // Big timer
      AnimatedBuilder(
        animation: _timerCtrl,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          SizedBox(width: 80, height: 80,
            child: CircularProgressIndicator(value: 1 - _timerCtrl.value, strokeWidth: 5, color: _timerColor, backgroundColor: _timerColor.withOpacity(0.15))),
          Text('$_timeLeft', style: TextStyle(color: _timerColor, fontSize: 26, fontWeight: FontWeight.w900)),
        ]),
      ),
      const SizedBox(height: 16),

      // Q# progress
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        NeonBadge('Q${widget.host.triviaIndex + 1} / ${triviaPool.length}', color: AppColors.purple),
      ]),
      const SizedBox(height: 12),

      GlassCard(child: Text(q['q'] as String,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.45))).animate().fadeIn(),
      const SizedBox(height: 12),

      // Options
      ...(q['opts'] as List).asMap().entries.map((e) {
        final opt = e.value as String;
        final label = ['A', 'B', 'C', 'D'][e.key];
        Color color = AppColors.border;
        Color textColor = Colors.white;
        if (_answered) {
          final isCorrect = (q['a'] as String).toLowerCase().contains(opt.toLowerCase());
          if (isCorrect)     { color = AppColors.green;  textColor = AppColors.green; }
          else if (_lastCorrect == false) { color = AppColors.coral.withOpacity(0.3); }
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: _answered ? null : () => _answer(opt),
            child: AnimatedContainer(duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                color: color == AppColors.border ? AppColors.navyCard : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color, width: color == AppColors.border ? 1 : 2),
              ),
              child: Row(children: [
                Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.blue.withOpacity(0.15)),
                  child: Center(child: Text(label, style: const TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 12),
                Expanded(child: Text(opt, style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
        );
      }),

      if (_answered)
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (_lastCorrect == true ? AppColors.green : AppColors.coral).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: (_lastCorrect == true ? AppColors.green : AppColors.coral).withOpacity(0.3)),
          ),
          child: Text('✅ Answer: ${q['a']}', style: TextStyle(color: _lastCorrect == true ? AppColors.green : Colors.white70, fontSize: 13)),
        ).animate().fadeIn(),
    ]);
  }

  Widget _buildDoneCard() {
    final pct = (widget.host.correct / triviaPool.length * 100).round();
    return GlassCard(
      borderColor: AppColors.gold.withOpacity(0.3),
      glowColor: AppColors.gold,
      child: Column(children: [
        const Text('🏆', style: TextStyle(fontSize: 52)).animate().scale(curve: Curves.elasticOut),
        const SizedBox(height: 12),
        GradText('Round Complete!', fontSize: 22, colors: [AppColors.gold, AppColors.blue]),
        const SizedBox(height: 8),
        Text('${widget.host.correct}/${triviaPool.length} correct ($pct%)',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(pct >= 75 ? '🏆 Cricket Expert!' : pct >= 50 ? '👏 Good effort!' : '📚 Keep watching!',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        AppButton(label: '🔄  Play Again', color: AppColors.gold, textColor: AppColors.navy, onTap: _start),
      ]),
    ).animate().scale(curve: Curves.elasticOut);
  }
}

// ──────────────────────────────────────────────────────────────────
// 3. Commentary Tab
// ──────────────────────────────────────────────────────────────────
class _CommentaryTab extends StatefulWidget {
  final WatchPartyHost host;
  const _CommentaryTab({required this.host});
  @override State<_CommentaryTab> createState() => _CommentaryTabState();
}

class _CommentaryTabState extends State<_CommentaryTab> {
  final _ctrl = TextEditingController(text: 'Last over, CSK needs 12 runs, Dhoni on strike');
  bool _loading = false;
  String _output = '';

  static const quickPrompts = [
    ('⚡ Six!',      'Rohit Sharma hits a massive six over mid-wicket into the crowd'),
    ('🎯 Wicket!',   'Bumrah bowls a perfect yorker, clean bowled for a wicket'),
    ('💯 Century!',  'Virat Kohli reaches his century with a magnificent cover drive'),
    ('🔥 Super Over!','It\'s a SUPER OVER! Both teams are tied after 20 overs!'),
    ('🚁 Finish!',   'Dhoni finishes it with a helicopter shot for a six!'),
  ];

  Future<void> _generate([String? sit]) async {
    final situation = sit ?? _ctrl.text.trim();
    if (situation.isEmpty) return;
    setState(() { _loading = true; _output = ''; });
    try {
      final text = await widget.host.commentary(situation);
      setState(() { _output = text; _loading = false; });
    } catch (_) {
      setState(() { _output = '📺 What a spectacular moment! The crowd erupts as the ball flies to the boundary! This is IPL cricket at its very finest — pure magic!'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Match Situation', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Describe the match situation...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.navyCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(label: _loading ? '⏳  On Air...' : '📺  Commentate', color: AppColors.blue, textColor: AppColors.navy, width: double.infinity, onTap: _loading ? null : () => _generate()),
        ])),
        const SizedBox(height: 12),

        // Quick prompts
        Wrap(spacing: 8, runSpacing: 8, children: quickPrompts.map((p) =>
          GestureDetector(
            onTap: () { _ctrl.text = p.$2; _generate(p.$2); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: AppColors.navyCard, borderRadius: BorderRadius.circular(50), border: Border.all(color: AppColors.border)),
              child: Text(p.$1, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ).toList()),
        const SizedBox(height: 16),

        if (_loading) const ThinkingDots(),

        if (_output.isNotEmpty)
          GlassCard(
            borderColor: AppColors.blue.withOpacity(0.25),
            glowColor: AppColors.blue,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [PulsingDot(), const SizedBox(width: 8),
                Text('Aria · Live Commentary', style: GoogleFonts.outfit(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w700))]),
              const SizedBox(height: 12),
              Text(_output, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.75)),
            ]),
          ).animate().fadeIn().slideY(begin: 0.15),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// 4. Milestones Tab
// ──────────────────────────────────────────────────────────────────
class _MilestoneTab extends StatefulWidget {
  final WatchPartyHost host;
  const _MilestoneTab({required this.host});
  @override State<_MilestoneTab> createState() => _MilestoneTabState();
}

class _MilestoneTabState extends State<_MilestoneTab> {
  bool _loading = false;
  String _response = '';
  String _lastMilestone = '';

  static const milestones = [
    ('💥', 'six',        'SIX!',       AppColors.blue),
    ('🎯', 'wicket',     'WICKET!',    AppColors.coral),
    ('5️⃣0️⃣', 'fifty',    'FIFTY!',     AppColors.gold),
    ('💯', 'century',    'CENTURY!',   AppColors.gold),
    ('🏃', 'boundary',   'FOUR!',      AppColors.green),
    ('⏰', 'last_over',  'LAST OVER',  Colors.orange),
    ('🎯', 'chase',      'CHASE ON!',  AppColors.purple),
    ('🔥', 'super over', 'SUPER OVER!',AppColors.coral),
  ];

  Future<void> _trigger(String type) async {
    setState(() { _loading = true; _response = ''; _lastMilestone = type; });
    try {
      final text = await widget.host.announce(type);
      setState(() { _response = text; _loading = false; });
    } catch (_) {
      setState(() { _response = '🎉 UNBELIEVABLE! The crowd has ERUPTED! This is the moment every cricket fan lives for! 🏏🔥'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Text('Tap a milestone — Aria reacts!',
          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 14),

        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
          children: milestones.map((m) {
            final active = _lastMilestone == m.$2;
            return GestureDetector(
              onTap: () => _trigger(m.$2),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: active ? m.$4.withOpacity(0.12) : AppColors.navyCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: active ? m.$4.withOpacity(0.5) : AppColors.border, width: active ? 2 : 1),
                  boxShadow: active ? [BoxShadow(color: m.$4.withOpacity(0.2), blurRadius: 16)] : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(m.$1, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(m.$3, style: GoogleFonts.outfit(color: active ? m.$4 : Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        if (_loading) const ThinkingDots(),
        if (_response.isNotEmpty)
          GlassCard(
            borderColor: AppColors.gold.withOpacity(0.25),
            glowColor: AppColors.gold,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [PulsingDot(color: AppColors.gold), const SizedBox(width: 8),
                Text('Aria · Gemini Flash', style: GoogleFonts.outfit(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700))]),
              const SizedBox(height: 10),
              Text(_response, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.7)),
            ]),
          ).animate().scale(begin: const Offset(0.95, 0.95)).fadeIn(),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// 5. Giveaway Tab
// ──────────────────────────────────────────────────────────────────
class _GiveawayTab extends StatefulWidget {
  final WatchPartyHost host;
  const _GiveawayTab({required this.host});
  @override State<_GiveawayTab> createState() => _GiveawayTabState();
}

class _GiveawayTabState extends State<_GiveawayTab> {
  final _prizeCtrl = TextEditingController(text: 'Signed IPL Jersey');
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _runGiveaway() async {
    setState(() { _loading = true; _result = null; });
    try {
      final r = await widget.host.giveaway(_prizeCtrl.text.trim().isEmpty ? 'an amazing prize' : _prizeCtrl.text.trim());
      setState(() { _result = r; _loading = false; });
    } catch (_) {
      setState(() {
        _result = {'winner': 'Rahul S.', 'prize': _prizeCtrl.text, 'participants': 312, 'text': '🎊 After careful AI analysis of all participants...'};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Aria image
        Container(
          height: 160,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.coral.withOpacity(0.2), blurRadius: 20)]),
          child: Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/aria_host.png', fit: BoxFit.cover, width: double.infinity)),
            Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.navy.withOpacity(0.9)]))),
            const Positioned(bottom: 12, left: 0, right: 0,
              child: Center(child: Text('🎁 Giveaway Time!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)))),
          ]),
        ).animate().fadeIn(),
        const SizedBox(height: 16),

        GlassCard(
          borderColor: AppColors.coral.withOpacity(0.2),
          child: Column(children: [
            const Text('🎁', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            GradText('Conduct a Giveaway', fontSize: 18, colors: [AppColors.coral, AppColors.gold]),
            const SizedBox(height: 16),
            TextField(
              controller: _prizeCtrl,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter the prize...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true, fillColor: AppColors.navyCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.coral)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            AppButton(label: _loading ? '🎰  Picking Winner...' : '🎉  Pick Winner & Announce', color: AppColors.coral, textColor: Colors.white, width: double.infinity, onTap: _loading ? null : _runGiveaway),
          ]),
        ),

        if (_loading) ...[const SizedBox(height: 20), const ThinkingDots()],

        if (_result != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            borderColor: AppColors.gold.withOpacity(0.4),
            glowColor: AppColors.gold,
            child: Column(children: [
              if ((_result!['text'] as String?)?.isNotEmpty == true)
                Text(_result!['text'] as String, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.6)),
              const SizedBox(height: 14),
              const Text('🎊 AND THE WINNER IS...', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [AppColors.gold, AppColors.coral]).createShader(b),
                child: Text(_result!['winner'] as String, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              ).animate().scale(curve: Curves.elasticOut),
              const SizedBox(height: 8),
              Text('Selected from ${_result!['participants']} participants 🎊',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ).animate().scale(begin: const Offset(0.85, 0.85)).fadeIn(),
        ],
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// 6. Ask Aria Tab
// ──────────────────────────────────────────────────────────────────
class _ChatTab extends StatefulWidget {
  final WatchPartyHost host;
  const _ChatTab({required this.host});
  @override State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _messages = <Map<String, dynamic>>[];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;

  static const quickQs = [
    'Best IPL captain ever?',
    'Tonight match prediction?',
    'Fun IPL fact!',
    'Most sixes in IPL?',
    'Dhoni vs Rohit as captain?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({'role': 'ai', 'text': 'Hey cricket lover! 🏏 I\'m Aria, your AI watch party host. Ask me anything — IPL records, player stats, match predictions, or just chat! Let\'s make this party unforgettable! 🎉'});
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send([String? q]) async {
    final text = q ?? _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() { _messages.add({'role': 'user', 'text': text}); _loading = true; });
    _scrollToBottom();
    try {
      final reply = await widget.host.ask(text);
      setState(() { _messages.add({'role': 'ai', 'text': reply}); _loading = false; });
    } catch (_) {
      setState(() { _messages.add({'role': 'ai', 'text': '🎙️ Great question! As your Gemini-powered IPL AI, I\'m here to make this match unforgettable! IPL is cricket at its finest.'}); _loading = false; });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: 300.ms, curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Chat list
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          itemCount: _messages.length + (_loading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _messages.length) {
              return Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.purple.withOpacity(0.1), border: Border.all(color: AppColors.purple.withOpacity(0.3))),
                    child: const Center(child: Text('🎙️', style: TextStyle(fontSize: 16)))),
                  const SizedBox(width: 10), const ThinkingDots(),
                ]));
            }
            final msg = _messages[i];
            return ChatBubble(
              text: msg['text'] as String,
              sender: '🎙️ Aria · Gemini Flash',
              avatar: '🎙️',
              isUser: msg['role'] == 'user',
              accentColor: AppColors.purple,
            ).animate().fadeIn(delay: 50.ms);
          },
        ),
      ),

      // Quick chips
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: quickQs.map((q) =>
          GestureDetector(
            onTap: () => _send(q),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: AppColors.navyCard, borderRadius: BorderRadius.circular(50), border: Border.all(color: AppColors.border)),
              child: Text(q, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ),
        ).toList()),
      ),

      // Input
      Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask Aria anything about IPL...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true, fillColor: AppColors.navyCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.purple)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.purple, AppColors.blue]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 10)],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    ]);
  }
}
