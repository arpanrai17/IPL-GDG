import 'dart:convert';
import '../services/api_service.dart';

// ──────────────────────────────────────────────────────────────────
// IPL Trivia Pool
// ──────────────────────────────────────────────────────────────────
const triviaPool = [
  {
    'q': 'Which team has won the most IPL titles?',
    'a': 'Mumbai Indians (5 titles)',
    'opts': ['Mumbai Indians', 'Chennai Super Kings', 'Kolkata Knight Riders', 'Sunrisers Hyderabad'],
  },
  {
    'q': 'Who holds the record for most runs in a single IPL season?',
    'a': 'Virat Kohli — 973 runs in 2016',
    'opts': ['Virat Kohli', 'David Warner', 'KL Rahul', 'Jos Buttler'],
  },
  {
    'q': 'Who has taken the most wickets in IPL history?',
    'a': 'Yuzvendra Chahal (205+ wickets)',
    'opts': ['Yuzvendra Chahal', 'Lasith Malinga', 'Dwayne Bravo', 'Amit Mishra'],
  },
  {
    'q': 'Which player has hit the most sixes in IPL history?',
    'a': 'Chris Gayle (357 sixes)',
    'opts': ['Chris Gayle', 'AB de Villiers', 'MS Dhoni', 'Rohit Sharma'],
  },
  {
    'q': 'Who won the Orange Cap in IPL 2023?',
    'a': 'Shubman Gill — 890 runs',
    'opts': ['Shubman Gill', 'Faf du Plessis', 'Yashasvi Jaiswal', 'Devon Conway'],
  },
  {
    'q': 'What is the highest team total in IPL history?',
    'a': '287/2 by RCB in 2013',
    'opts': ['287/2 RCB', '263/5 MI', '277/4 CSK', '248/3 KKR'],
  },
  {
    'q': 'Who has captained the most IPL matches?',
    'a': 'MS Dhoni',
    'opts': ['MS Dhoni', 'Rohit Sharma', 'Virat Kohli', 'Suresh Raina'],
  },
  {
    'q': 'Which IPL team is known as the "Yellow Army"?',
    'a': 'Chennai Super Kings',
    'opts': ['Chennai Super Kings', 'Sunrisers Hyderabad', 'Gujarat Titans', 'Kolkata Knight Riders'],
  },
];

// ──────────────────────────────────────────────────────────────────
// Aki-Cricket Game Engine
// ──────────────────────────────────────────────────────────────────
enum Persona { confident, focused, tense, dramatic, defeated }

class AkiQuestion {
  final String question;
  final String thoughts;
  final Persona persona;
  AkiQuestion({required this.question, required this.thoughts, required this.persona});
}

class AkiResult {
  final String? guess;
  final bool akiWon;
  final int questionsUsed;
  final int elapsed;
  AkiResult({this.guess, required this.akiWon, required this.questionsUsed, required this.elapsed});
}

class AkiGame {
  final String category;
  final List<Map<String, dynamic>> answers = [];
  int questionCount = 0;
  static const maxQ = 15;
  DateTime? _startTime;

  AkiGame({required this.category});

  void start() => _startTime = DateTime.now();

  int get elapsed => _startTime == null ? 0 : DateTime.now().difference(_startTime!).inSeconds;

  Persona _getPersona() {
    final q = questionCount;
    if (q >= 13) return Persona.dramatic;
    if (q >= 10) return Persona.tense;
    if (q >= 6)  return Persona.focused;
    return Persona.confident;
  }

  Future<AkiQuestion> nextQuestion() async {
    questionCount++;
    final hist = answers.map((a) => 'Q${a["q"]}: ${a["question"]} → ${a["answer"]}').join('\n');
    final prompt = '''You are Aki, an expert IPL AI oracle. The user is thinking of an IPL $category.
History of Q&A so far:
$hist
Ask question #$questionCount (max 15) that best narrows down the $category. Be strategic.
Respond ONLY in JSON: {"question":"...","thoughts":"...","persona":"confident|focused|tense|dramatic"}''';

    final raw = await gemini.generate(prompt);
    try {
      final json = jsonDecode(raw.replaceAll(RegExp(r'```json?|```'), '').trim());
      final p = _personaFrom(json['persona'] ?? 'confident');
      return AkiQuestion(
        question: json['question'] ?? 'Is this player still active in IPL?',
        thoughts: json['thoughts'] ?? '',
        persona: p,
      );
    } catch (_) {
      return AkiQuestion(
        question: _fallbackQ(questionCount),
        thoughts: 'Narrowing down the possibilities...',
        persona: _getPersona(),
      );
    }
  }

  Future<AkiResult> makeGuess() async {
    final hist = answers.map((a) => 'Q${a["q"]}: ${a["question"]} → ${a["answer"]}').join('\n');
    final prompt = '''Based on these IPL $category clues, make your best guess:
$hist
Respond ONLY in JSON: {"guess":"...","confidence":85,"reason":"..."}''';

    final raw = await gemini.generate(prompt);
    try {
      final json = jsonDecode(raw.replaceAll(RegExp(r'```json?|```'), '').trim());
      final guess = json['guess']?.toString() ?? 'Virat Kohli';
      return AkiResult(
        guess: guess,
        akiWon: false,
        questionsUsed: questionCount,
        elapsed: elapsed,
      );
    } catch (_) {
      return AkiResult(
        guess: _fallbackGuess(),
        akiWon: false,
        questionsUsed: questionCount,
        elapsed: elapsed,
      );
    }
  }

  void recordAnswer(String question, bool yes) {
    answers.add({
      'q': questionCount,
      'question': question,
      'answer': yes ? 'Yes' : 'No',
    });
  }

  Persona _personaFrom(String s) {
    switch (s) {
      case 'focused':   return Persona.focused;
      case 'tense':     return Persona.tense;
      case 'dramatic':  return Persona.dramatic;
      case 'defeated':  return Persona.defeated;
      default:          return Persona.confident;
    }
  }

  String _fallbackQ(int n) {
    final qs = [
      'Is this person a batsman?',
      'Have they played for Mumbai Indians?',
      'Are they an Indian national player?',
      'Have they scored over 3000 IPL runs?',
      'Are they known for aggressive batting?',
      'Did they retire before 2020?',
      'Are they still active in IPL?',
      'Have they won an IPL title?',
      'Are they a T20 specialist?',
      'Have they represented their country as captain?',
      'Did they play in the first IPL season (2008)?',
      'Are they primarily a middle-order batsman?',
      'Have they taken more than 100 IPL wickets?',
      'Are they from Maharashtra?',
      'Do they bat right-handed?',
    ];
    return qs[(n - 1) % qs.length];
  }

  String _fallbackGuess() {
    final guesses = ['MS Dhoni', 'Virat Kohli', 'Rohit Sharma', 'AB de Villiers', 'Mumbai Indians', 'Chennai Super Kings'];
    return guesses[questionCount % guesses.length];
  }
}

// ──────────────────────────────────────────────────────────────────
// Watch Party Host Engine
// ──────────────────────────────────────────────────────────────────
class WatchPartyHost {
  int triviaIndex = 0;
  int correct = 0;
  int wrong = 0;

  Future<String> welcome(String venue) async {
    final prompt = '''You are Aria, a high-energy AI IPL watch party host at "$venue".
Give an electrifying 3-4 sentence welcome. Be dramatic, exciting, use cricket emojis.
Pure text only, no JSON.''';
    return gemini.generate(prompt);
  }

  Future<String> commentary(String situation) async {
    final prompt = '''You are Aria, an IPL commentator like Harsha Bhogle.
Give exciting 3-4 sentence live commentary for: "$situation"
Use cricket stats, drama, crowd reactions. Pure text only.''';
    return gemini.generate(prompt);
  }

  Future<String> announce(String milestone) async {
    final labels = {
      'six':        'SIX! 💥',
      'wicket':     'WICKET! 🎯',
      'fifty':      'FIFTY! 5️⃣0️⃣',
      'century':    'CENTURY! 💯',
      'boundary':   'FOUR! 🏃',
      'last_over':  'LAST OVER! ⏰',
      'chase':      'CHASE IS ON! 🎯',
      'super over': 'SUPER OVER! 🔥',
    };
    final prompt = '''You are Aria. React dramatically to: ${labels[milestone] ?? milestone.toUpperCase()}
2-3 sentences, HIGH energy, cricket emojis. Pure text only.''';
    return gemini.generate(prompt);
  }

  Future<Map<String, dynamic>> giveaway(String prize) async {
    final participants = 150 + (DateTime.now().millisecond % 200);
    final names = ['Rahul S.', 'Priya M.', 'Arjun K.', 'Sneha R.', 'Dev P.', 'Anjali T.', 'Rohan B.', 'Kavya N.'];
    final winner = names[DateTime.now().second % names.length];
    final prompt = '''You are Aria. Build up suspense for giveaway: "$prize". 1-2 dramatic sentences before revealing the winner. Pure text only.''';
    final text = await gemini.generate(prompt);
    return {'winner': winner, 'prize': prize, 'participants': participants, 'text': text};
  }

  Future<String> ask(String question) async {
    final prompt = '''You are Aria, an IPL AI expert. Answer this fan question concisely and with enthusiasm: "$question"
2-3 sentences max. Use IPL stats when relevant. Pure text only.''';
    return gemini.generate(prompt);
  }

  Map<String, dynamic> get currentTrivia {
    if (triviaIndex >= triviaPool.length) return triviaPool.last;
    return triviaPool[triviaIndex];
  }

  bool answerTrivia(String selected) {
    final t = currentTrivia;
    final correct_ = (t['a'] as String).toLowerCase().contains(selected.toLowerCase());
    if (correct_) correct++; else wrong++;
    triviaIndex++;
    return correct_;
  }

  bool get triviaComplete => triviaIndex >= triviaPool.length;
  int get triviaTotal => triviaPool.length;
}
