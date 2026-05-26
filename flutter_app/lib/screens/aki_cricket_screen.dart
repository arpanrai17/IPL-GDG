import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_widgets.dart';
import '../models/game_models.dart';
import '../services/api_service.dart';

// ──────────────────────────────────────────────────────────────────
// Aki-Cricket Screen
// ──────────────────────────────────────────────────────────────────
class AkiCricketScreen extends StatefulWidget {
  const AkiCricketScreen({super.key});
  @override
  State<AkiCricketScreen> createState() => _AkiCricketScreenState();
}

class _AkiCricketScreenState extends State<AkiCricketScreen> with TickerProviderStateMixin {
  // State
  AkiGame? _game;
  String _category  = 'player';
  bool _gameActive  = false;
  bool _waiting     = false;
  bool _gameOver    = false;
  String? _currentQ;
  String? _currentThought;
  Persona _persona  = Persona.confident;
  List<Map<String,dynamic>> _chat = [];
  List<Map<String, dynamic>> _leaderboard = [];

  // Timer
  int _timeLeft = 120;
  Timer? _timer;

  // Stats
  Map<String,dynamic> _stats = {'streak':0,'played':0,'wins':0,'losses':0};

  // Animations
  late final AnimationController _avatarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  late final AnimationController _ringCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final Animation<double>   _avatarAnim = Tween<double>(begin: 0.0, end: 8.0).animate(CurvedAnimation(parent: _avatarCtrl, curve: Curves.easeInOut));
  late final Animation<double>   _ringAnim   = Tween<double>(begin: 0.0, end: 1.0).animate(_ringCtrl);

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _stats      = session.stats;
    _leaderboard = session.leaderboard.toList();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _avatarCtrl.dispose();
    _ringCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Timer ────────────────────────────────────────────────────────
  void _startTimer() {
    _timeLeft = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { _timer?.cancel(); _endGame(timedOut: true); }
    });
  }

  String get _timerStr => '${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}';
  Color get _timerColor => _timeLeft <= 10 ? AppColors.coral : _timeLeft <= 30 ? Colors.orange : AppColors.blue;

  // ── Game Flow ─────────────────────────────────────────────────────
  Future<void> _startGame() async {
    setState(() {
      _gameActive = true; _waiting = true; _chat = [];
      _persona = Persona.confident; _currentQ = null; _currentThought = null;
    });
    _game = AkiGame(category: _category)..start();
    _startTimer();
    await _askNext();
  }

  Future<void> _askNext() async {
    if (_game!.questionCount >= AkiGame.maxQ) { await _makeGuess(); return; }
    setState(() => _waiting = true);
    try {
      final q = await _game!.nextQuestion();
      setState(() {
        _currentQ = q.question; _currentThought = q.thoughts; _persona = q.persona; _waiting = false;
        _chat.add({'role':'aki','text':q.question,'thought':q.thoughts,'persona':q.persona});
      });
      _scrollToBottom();
    } catch (_) {
      setState(() { _waiting = false; _currentQ = 'Is this person a batsman?'; });
    }
  }

  Future<void> _answer(bool yes) async {
    if (_currentQ == null || _waiting) return;
    _game!.recordAnswer(_currentQ!, yes);
    setState(() {
      _chat.add({'role':'user','text': yes ? '✅  YES' : '❌  NO'});
      _currentQ = null; _waiting = true;
    });
    _scrollToBottom();
    await _askNext();
  }

  Future<void> _makeGuess() async {
    setState(() => _waiting = true);
    final result = await _game!.makeGuess();
    _timer?.cancel();
    setState(() => _waiting = false);
    if (mounted) _showResultDialog(result);
  }

  void _endGame({bool timedOut = false}) {
    _timer?.cancel();
    if (timedOut) {
      _showResultDialog(AkiResult(guess: null, akiWon: true, questionsUsed: _game?.questionCount ?? 15, elapsed: 120));
    }
  }

  void _showResultDialog(AkiResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        result: result,
        onConfirm: (akiRight) => _finalizeResult(result, akiRight),
        onPlayAgain: _resetGame,
      ),
    );
  }

  void _finalizeResult(AkiResult result, bool akiRight) {
    // In-memory only — no database, no storage
    session.recordGame(
      userWon:   !akiRight,
      name:      'Player',
      questions: result.questionsUsed,
      elapsed:   result.elapsed,
    );
    _loadData();
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() { _gameActive = false; _chat = []; _currentQ = null; _waiting = false; _timeLeft = 120; });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  String get _personaEmoji => const {'confident':'😏','focused':'🧐','tense':'😰','dramatic':'😱','defeated':'😔'}[_persona.name] ?? '🧙';
  Color  get _personaColor => const {
    'confident': AppColors.blue, 'focused': AppColors.purple,
    'tense': Colors.orange, 'dramatic': AppColors.coral, 'defeated': Colors.grey,
  }[_persona.name] ?? AppColors.blue;

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        children: [
          // Background glow orbs
          _buildBgOrbs(),
          // Main content
          SafeArea(
            child: Column(children: [
              _buildHeroBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      if (!_gameActive) _buildPreGame() else _buildGamePanel(),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBgOrbs() {
    return Stack(children: [
      Positioned(top: -60, left: -60, child: Container(width: 220, height: 220,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.blue.withOpacity(0.06)), )),
      Positioned(bottom: -40, right: -40, child: Container(width: 180, height: 180,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(0.05)), )),
      Positioned(top: 200, right: -20, child: Container(width: 120, height: 120,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.purple.withOpacity(0.06)), )),
    ]);
  }

  Widget _buildHeroBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        // Animated Aki avatar
        AnimatedBuilder(
          animation: _avatarAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, -_avatarAnim.value / 3),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Spinning ring
                AnimatedBuilder(
                  animation: _ringAnim,
                  builder: (_, __) => Transform.rotate(
                    angle: _ringAnim.value * 6.28,
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _personaColor.withOpacity(0.4), width: 1.5, style: BorderStyle.solid),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_personaColor.withOpacity(0.2), Colors.transparent]),
                    border: Border.all(color: _personaColor, width: 2),
                    boxShadow: [BoxShadow(color: _personaColor.withOpacity(0.35), blurRadius: 12)],
                  ),
                  child: Center(child: Text(_personaEmoji, style: const TextStyle(fontSize: 22))),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GradText('Aki-Cricket', fontSize: 20, colors: [AppColors.blue, AppColors.purple]),
          Text(
            _gameActive ? '${_game?.questionCount ?? 0}/15 · ${_persona.name.toUpperCase()}' : 'AI IPL Akinator',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ])),
        if (_gameActive) _buildTimerChip(),
      ]),
    );
  }

  Widget _buildTimerChip() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _timerColor.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: _timerColor.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_rounded, color: _timerColor, size: 14),
        const SizedBox(width: 5),
        Text(_timerStr, style: TextStyle(color: _timerColor, fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'monospace')),
      ]),
    );
  }

  Widget _buildPreGame() {
    return Column(children: [
      const SizedBox(height: 16),
      // Aki image
      Center(
        child: AnimatedBuilder(
          animation: _avatarAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, -_avatarAnim.value),
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.blue.withOpacity(0.4), width: 2),
                boxShadow: [BoxShadow(color: AppColors.blue.withOpacity(0.3), blurRadius: 30)],
              ),
              child: ClipOval(child: Image.asset('assets/images/aki_character.png', fit: BoxFit.cover)),
            ),
          ),
        ),
      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 20),

      GradText(
        'Can you stump me?',
        fontSize: 26,
        colors: [AppColors.blue, AppColors.gold],
        textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 200.ms),

      const SizedBox(height: 8),
      Text('Think of an IPL player, team or match. I\'ll guess in ≤15 questions!',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13.5, height: 1.6),
      ).animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 24),

      // Category picker
      GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Choose Category', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(children: [
            _catBtn('🧑', 'Player', 'player'),
            const SizedBox(width: 10),
            _catBtn('🏟️', 'Team', 'team'),
            const SizedBox(width: 10),
            _catBtn('🏆', 'Match', 'match'),
          ]),
        ]),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
      const SizedBox(height: 16),

      // Stats row
      Row(children: [
        Expanded(child: _miniStat('${_stats['streak']}', 'Win Streak 🔥', AppColors.blue)),
        const SizedBox(width: 10),
        Expanded(child: _miniStat('${_stats['played']}', 'Games', AppColors.gold)),
        const SizedBox(width: 10),
        Expanded(child: _miniStat('${_stats['wins']}', 'I Won 🎉', AppColors.green)),
        const SizedBox(width: 10),
        Expanded(child: _miniStat('${_stats['losses']}', 'AI Won', AppColors.coral)),
      ]).animate().fadeIn(delay: 500.ms),
      const SizedBox(height: 16),

      AppButton(
        label: '🎮  Start Game',
        color: AppColors.blue,
        textColor: AppColors.navy,
        width: double.infinity,
        onTap: _startGame,
      ).animate().scale(delay: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 20),

      // Leaderboard
      if (_leaderboard.isNotEmpty) GlassCard(
        borderColor: AppColors.gold.withOpacity(0.2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('Firebase Leaderboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.white, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          ..._leaderboard.take(5).toList().asMap().entries.map((e) {
            final i = e.key; final item = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Text(i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i+1}.',
                  style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                Expanded(child: Text('${item['name'] ?? 'Anonymous'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                Text('${item['aki_won'] == true ? '🤖 AI' : '${item['questions']}Q'}', style: const TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            );
          }),
        ]),
      ).animate().fadeIn(delay: 700.ms),
    ]);
  }

  Widget _catBtn(String icon, String label, String val) {
    final active = _category == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _category = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.blue.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppColors.blue.withOpacity(0.5) : AppColors.border),
          ),
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? AppColors.blue : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget _miniStat(String val, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      borderColor: color.withOpacity(0.15),
      child: Column(children: [
        Text(val, style: GoogleFonts.outfit(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildGamePanel() {
    return Column(children: [
      const SizedBox(height: 12),
      // Q-progress dots
      _buildQDots(),
      const SizedBox(height: 14),

      // Chat area
      GlassCard(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 340,
          child: ListView.builder(
            controller: _scrollCtrl,
            itemCount: _chat.length + (_waiting ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _chat.length) {
                return Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.blue.withOpacity(0.1), border: Border.all(color: AppColors.blue.withOpacity(0.3))),
                    child: const Center(child: Text('😏', style: TextStyle(fontSize: 16)))),
                  const SizedBox(width: 10),
                  const ThinkingDots(),
                ]);
              }
              final msg = _chat[i];
              if (msg['role'] == 'user') {
                return ChatBubble(text: msg['text'], sender: 'You', avatar: '👤', isUser: true);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ChatBubble(text: msg['text'], sender: '🤖 Aki · Gemini Flash', avatar: _personaEmoji, accentColor: AppColors.blue),
                if ((msg['thought'] as String?)?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(left: 46, bottom: 4),
                    child: Text('💭 ${msg['thought']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
                  ),
              ]);
            },
          ),
        ),
      ),
      const SizedBox(height: 12),

      // YES / NO buttons
      if (_currentQ != null && !_waiting)
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => _answer(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.coral.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.coral.withOpacity(0.4)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('❌', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('NO', style: GoogleFonts.outfit(color: AppColors.coral, fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
            ),
          )).animate().slideX(begin: -0.2),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () => _answer(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.green.withOpacity(0.4)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('✅', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('YES', style: GoogleFonts.outfit(color: AppColors.green, fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
            ),
          )).animate().slideX(begin: 0.2),
        ]),

      const SizedBox(height: 12),
      AppButton(
        label: '🏳️  Give Up',
        color: AppColors.textMuted,
        textColor: Colors.white,
        width: double.infinity,
        outlined: true,
        onTap: () { _timer?.cancel(); _resetGame(); },
      ),
    ]);
  }

  Widget _buildQDots() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(children: [
        Expanded(
          child: Wrap(spacing: 6, children: List.generate(15, (i) {
            Color c = AppColors.border;
            final answered = i < (_game?.answers.length ?? 0);
            if (answered) {
              final a = _game!.answers[i];
              c = (a['answer'] == 'Yes') ? AppColors.green : AppColors.coral;
            } else if (i == (_game?.answers.length ?? 0)) {
              c = AppColors.blue;
            }
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withOpacity(0.8),
                boxShadow: c != AppColors.border ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 4)] : null,
              ),
            );
          })),
        ),
        const SizedBox(width: 10),
        Text('${_game?.questionCount ?? 0}/15',
          style: GoogleFonts.outfit(color: AppColors.blue, fontWeight: FontWeight.w800, fontSize: 15)),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Result Dialog
// ──────────────────────────────────────────────────────────────────
class _ResultDialog extends StatefulWidget {
  final AkiResult result;
  final void Function(bool akiRight) onConfirm;
  final VoidCallback onPlayAgain;
  const _ResultDialog({required this.result, required this.onConfirm, required this.onPlayAgain});
  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog> {
  bool _confirmed = false;
  bool _akiWon    = false;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.navyLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_confirmed ? (_akiWon ? '🧙' : '🎉') : '🤔', style: const TextStyle(fontSize: 52))
            .animate().scale(curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(height: 14),
          GradText(
            _confirmed
              ? (_akiWon ? 'Aki Wins!' : 'You Win!')
              : (widget.result.guess != null ? 'My Guess...' : "Time's Up!"),
            fontSize: 24, colors: [AppColors.blue, AppColors.gold],
          ),
          const SizedBox(height: 10),
          if (!_confirmed && widget.result.guess != null) ...[
            Text('Is it...', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 8),
            Text(widget.result.guess!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Text('Was I right?', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: AppButton(label: '✅  Yes, right!', color: AppColors.green, textColor: AppColors.navy, onTap: () { setState(() { _confirmed = true; _akiWon = true;  }); widget.onConfirm(true); })),
              const SizedBox(width: 12),
              Expanded(child: AppButton(label: '❌  Nope!', color: AppColors.coral, textColor: Colors.white, onTap: () { setState(() { _confirmed = true; _akiWon = false; }); widget.onConfirm(false); })),
            ]),
          ],
          if (_confirmed) ...[
            const SizedBox(height: 6),
            Text(
              _akiWon ? 'Gemini AI guessed in ${widget.result.questionsUsed} questions!' : 'You stumped Gemini! Amazing! 🔥',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Your name for Firebase leaderboard...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true, fillColor: AppColors.navyCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            AppButton(label: '💾  Save to Session', color: AppColors.gold, textColor: AppColors.navy, width: double.infinity, onTap: () {
              final name = _nameCtrl.text.trim().isEmpty ? 'Anonymous' : _nameCtrl.text.trim();
              session.recordGame(userWon: !_akiWon, name: name, questions: widget.result.questionsUsed, elapsed: widget.result.elapsed);
              if (mounted) { Navigator.pop(context); widget.onPlayAgain(); }
            }),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: () { Navigator.pop(context); widget.onPlayAgain(); },
            child: const Text('🔄  Play Again', style: TextStyle(color: AppColors.textMuted)),
          ),
        ]),
      ),
    );
  }
}
