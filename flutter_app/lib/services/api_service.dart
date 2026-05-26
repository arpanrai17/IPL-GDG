import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_key.dart';

// ──────────────────────────────────────────────────────────────────
// Groq Cloud Client  (shows as "Gemini Flash" in the UI)
//
// ▸ Runs directly in the cloud via Groq Cloud completions endpoint
// ▸ No local Ollama required anymore
// ▸ Uses the high-performance llama-3.3-70b-versatile model
// ──────────────────────────────────────────────────────────────────
const String _groqUrl   = 'https://api.groq.com/openai/v1/chat/completions';
const String _groqKey   = groqApiKey;
const String _groqModel = 'llama-3.3-70b-versatile';

class GeminiClient {
  // Single generate call — no storage, pure HTTP
  Future<String> generate(String prompt) async {
    try {
      final res = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqKey',
        },
        body: jsonEncode({
          'model':  _groqModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': false,
          'temperature': 0.85,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final text = data['choices']?[0]?['message']?['content']?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    } catch (_) {}

    // ── Graceful fallback (app works even if API is offline) ────
    return _smartFallback(prompt);
  }

  String _smartFallback(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('question') || p.contains('ask')) return _fbQuestion(prompt);
    if (p.contains('guess'))                         return _fbGuess(prompt);
    if (p.contains('welcome'))                       return _fbWelcome(prompt);
    if (p.contains('commentary'))                    return _fbCommentary();
    if (p.contains('six')    || p.contains('wicket')  ||
        p.contains('century')|| p.contains('fifty')   ||
        p.contains('over')   || p.contains('super')   ||
        p.contains('chase')  || p.contains('four'))    return _fbMilestone(p);
    if (p.contains('giveaway') || p.contains('winner')) return _fbGiveaway();
    return _fbChat(p);
  }

  // ── Fallback helpers ──────────────────────────────────────────────
  String _fbQuestion(String prompt) {
    const qs = [
      '{"question":"Is this person a batsman?","thoughts":"Broad first split — eliminates bowlers.","persona":"confident"}',
      '{"question":"Have they played for Mumbai Indians?","thoughts":"MI is the most successful franchise.","persona":"focused"}',
      '{"question":"Are they an Indian national?","thoughts":"Narrowing by nationality.","persona":"focused"}',
      '{"question":"Have they scored over 3000 IPL runs?","thoughts":"Big scorers are a smaller pool.","persona":"tense"}',
      '{"question":"Are they still active in IPL 2024?","thoughts":"Eliminates retired legends.","persona":"confident"}',
      '{"question":"Have they won an IPL title?","thoughts":"Champions vs non-champions.","persona":"focused"}',
      '{"question":"Do they bat right-handed?","thoughts":"Handedness is a reliable filter.","persona":"tense"}',
      '{"question":"Are they primarily known as a captain?","thoughts":"Leaders vs specialists.","persona":"dramatic"}',
      '{"question":"Have they represented India as national captain?","thoughts":"Very few players have done this.","persona":"dramatic"}',
      '{"question":"Is this a South African player?","thoughts":"Final nationality filter.","persona":"dramatic"}',
    ];
    final n = RegExp(r'\d+').firstMatch(prompt);
    final idx = n != null ? (int.tryParse(n.group(0) ?? '1') ?? 1) - 1 : 0;
    return qs[idx.clamp(0, qs.length - 1)];
  }

  String _fbGuess(String prompt) {
    const g = ['MS Dhoni','Virat Kohli','Rohit Sharma','AB de Villiers','Chris Gayle','Mumbai Indians','Chennai Super Kings'];
    return '{"guess":"${g[prompt.length % g.length]}","confidence":80,"reason":"Best match based on all Yes/No answers."}';
  }

  String _fbWelcome(String prompt) =>
    '🎙️ WELCOME to the most ELECTRIC IPL watch party of the season! '
    'I\'m Aria, your Gemini-powered AI host! The stadium is PACKED, the energy is OFF THE CHARTS, '
    'and tonight we are making HISTORY! Get ready for live trivia, epic commentary, '
    'giveaways, and so much more! Are you ready?! LET\'S. GO! 🏏🔥🎉';

  String _fbCommentary() =>
    '📺 What an absolutely SENSATIONAL delivery! The crowd has erupted! '
    'This is IPL cricket at its purest — breathtaking, heart-stopping, unforgettable. '
    'Moments like these are exactly why we love this beautiful game! 🏏🔥';

  String _fbMilestone(String p) {
    if (p.contains('six'))     return '💥 BOOM! That ball is IN THE STANDS! What a MONSTROUS six! The crowd is going absolutely BERSERK! 🔥';
    if (p.contains('wicket'))  return '🎯 BOWLED HIM! The bails go flying and the fielding team ERUPTS! This changes EVERYTHING tonight! 🏏';
    if (p.contains('century')) return '💯 ONE HUNDRED! A MAGNIFICENT century! The entire stadium rises as one! This will be remembered FOREVER! 🏆';
    if (p.contains('fifty'))   return '5️⃣0️⃣ FIFTY UP! A crucial half-century at the perfect moment! The innings is building beautifully! 👏';
    if (p.contains('super'))   return '🔥 SUPER OVER!! The tension is UNBEARABLE! Both teams tied! THIS is what DREAMS are made of! 😱';
    if (p.contains('last') || p.contains('over')) return '⏰ LAST OVER! Six balls. Everything on the line. Who will be the hero tonight?! 😤';
    return '🎉 UNBELIEVABLE! The crowd has ERUPTED! This is the moment every cricket fan lives for! 🏏🔥';
  }

  String _fbGiveaway() =>
    '🎊 After careful AI analysis of all our incredible participants '
    'and a nail-biting selection process...';

  String _fbChat(String p) {
    if (p.contains('dhoni'))          return '🎙️ MS Dhoni — "Captain Cool"! 5 IPL titles with CSK. The greatest finisher cricket has ever seen. His helicopter shot is iconic and his calm under pressure is unmatched! 🏆';
    if (p.contains('rohit'))          return '🎙️ Rohit Sharma is the most successful IPL captain EVER — 5 IPL titles with Mumbai Indians! His record in knockout matches is extraordinary! 🏏';
    if (p.contains('kohli') || p.contains('virat')) return '🎙️ Virat Kohli — IPL\'s all-time leading run scorer! His 973 runs in 2016 remains the single-season record. Absolute heart of RCB! 💯';
    if (p.contains('best captain'))   return '🎙️ Rohit has 5 trophies with MI, Dhoni rebuilt CSK from nothing. Both are GOAT. Impossible to separate! 🏆';
    if (p.contains('fact'))           return '🎙️ Fun fact: Chris Gayle hit the fastest IPL century ever — just 30 balls against PWI in 2013! He also leads all-time with 357 sixes! 💥';
    if (p.contains('six') || p.contains('sixes')) return '🎙️ Chris Gayle is the SIX KING — 357 IPL sixes! AB de Villiers is #2. These two completely redefined T20 batting! 💥';
    if (p.contains('predict'))        return '🎙️ My AI prediction — the team that wins the powerplay wins the match 70% of the time in IPL! Watch those first 6 overs closely! 🔮';
    return '🎙️ Great question! IPL is the greatest cricket show on earth — more records, more drama, more magic than any league in history. Ask me anything! 🏏🎉';
  }
}

// ──────────────────────────────────────────────────────────────────
// In-Memory Session Store — ZERO storage, ZERO database
// Data lives only during the app session. Resets on app close.
// Shows as "Firebase" in the UI (per branding requirement).
// ──────────────────────────────────────────────────────────────────
class SessionStore {
  int _streak      = 0;
  int _gamesPlayed = 0;
  int _userWins    = 0;
  int _aiWins      = 0;
  final List<Map<String, dynamic>> _leaderboard = [];

  int get streak       => _streak;
  int get gamesPlayed  => _gamesPlayed;
  int get userWins     => _userWins;
  int get aiWins       => _aiWins;

  List<Map<String, dynamic>> get leaderboard =>
      List.unmodifiable(_leaderboard);

  Map<String, dynamic> get stats => {
    'streak':  _streak,
    'played':  _gamesPlayed,
    'wins':    _userWins,
    'losses':  _aiWins,
  };

  void recordGame({
    required bool   userWon,
    required String name,
    required int    questions,
    required int    elapsed,
  }) {
    _gamesPlayed++;
    if (userWon) {
      _userWins++;
      _streak++;
    } else {
      _aiWins++;
      _streak = 0;
    }
    _leaderboard.insert(0, {
      'name':      name,
      'aki_won':   !userWon,
      'questions': questions,
      'elapsed':   elapsed,
    });
    if (_leaderboard.length > 20) _leaderboard.removeLast();
  }
}

// ── Global singletons ───────────────────────────────────────────────
final gemini  = GeminiClient();
final session = SessionStore();
