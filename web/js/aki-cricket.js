/**
 * PS1: Aki-Cricket — AI Akinator Game Logic
 * Gemini Flash powers the adaptive questioning engine
 */

const AKI_SYSTEM_PROMPT = `You are Aki-Cricket, an AI Akinator for IPL cricket. 
Your goal: guess what the player is thinking (an IPL player, team, or historic match) in exactly 15 Yes/No questions.

RULES:
1. Ask ONE focused Yes/No question at a time — never compound questions.
2. Use binary search logic: each question must cut remaining possibilities in half.
3. NEVER repeat a question or concept you've already asked.
4. Track all answers mentally and narrow precisely.
5. After ≤15 questions, make your FINAL GUESS.
6. Adapt your PERSONA based on state:
   - Questions 1-5: Confident, slightly smug ("I've already narrowed it down considerably...")
   - Questions 6-10: Focused, analytical ("Interesting... let me recalibrate...")
   - Questions 11-13: Tense, slightly worried ("Hmm, this is trickier than I expected...")
   - Questions 14-15: Dramatic ("This is my FINAL CHANCE — everything rides on this!")
   - After 15 with no guess: Panicked/defeated ("You've outsmarted me... this time!")
7. When ready to guess, say: "I GUESS: [your answer]"

Format each response as JSON:
{
  "question": "Your Yes/No question here",
  "thoughts": "Brief internal reasoning (1 sentence)",
  "persona": "One of: confident | focused | tense | dramatic | defeated",
  "isGuess": false,
  "guess": ""
}
If making final guess:
{
  "question": "",
  "thoughts": "...",
  "persona": "dramatic",
  "isGuess": true,
  "guess": "Virat Kohli" 
}`;

class AkiCricketGame {
  constructor() {
    this.gemini = new GeminiClient();
    this.questionCount = 0;
    this.maxQuestions = 15;
    this.answers = [];
    this.gameOver = false;
    this.startTime = null;
    this.timerInterval = null;
    this.onQuestion = null; // callback
    this.onGuess    = null;
    this.onTimer    = null;
    this.onPersonaChange = null;
  }

  start() {
    this.gemini.reset();
    this.questionCount = 0;
    this.answers = [];
    this.gameOver = false;
    this.startTime = Date.now();
    this._startTimer();
    return this._askNext('Start the game. Think of something about IPL and ask your first question.');
  }

  async _askNext(context) {
    if (this.questionCount >= this.maxQuestions) {
      return this._forceGuess();
    }
    this.questionCount++;
    const prompt = `Question ${this.questionCount}/${this.maxQuestions}. Answers so far: ${JSON.stringify(this.answers)}. ${context}`;
    
    try {
      const raw = await this.gemini.chat(prompt, AKI_SYSTEM_PROMPT);
      const parsed = this._parseResponse(raw);
      if (parsed.isGuess) {
        this._endGame(parsed.guess, true);
      } else {
        this.onQuestion?.(parsed, this.questionCount, this.maxQuestions);
        this.onPersonaChange?.(parsed.persona);
      }
      return parsed;
    } catch (e) {
      console.error(e);
      return null;
    }
  }

  async answer(isYes) {
    if (this.gameOver) return;
    this.answers.push({ q: this.questionCount, answer: isYes ? 'Yes' : 'No' });
    const feedback = isYes ? 'Player answered YES' : 'Player answered NO';
    return this._askNext(feedback);
  }

  async _forceGuess() {
    const prompt = `You've used all 15 questions. Answers: ${JSON.stringify(this.answers)}. Make your best guess now. Set isGuess:true.`;
    const raw = await this.gemini.chat(prompt);
    const parsed = this._parseResponse(raw);
    this._endGame(parsed.guess || 'Unknown', parsed.isGuess);
    return parsed;
  }

  _endGame(guess, akiWon) {
    this.gameOver = true;
    clearInterval(this.timerInterval);
    const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
    this.onGuess?.({ guess, akiWon, elapsed, questions: this.questionCount });
  }

  confirmGuess(correct) {
    // Player confirms if Aki's guess was correct
    const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
    if (correct) {
      this.onGuess?.({ akiWon: true, elapsed, questions: this.questionCount });
    } else {
      this.onGuess?.({ akiWon: false, elapsed, questions: this.questionCount });
    }
  }

  _parseResponse(raw) {
    if (!raw) return this._fallbackParsed();
    // Strip markdown code fences that Ollama sometimes adds
    let clean = raw.replace(/```json?\s*/gi, '').replace(/```\s*/g, '').trim();
    // Try direct parse
    try { const j = JSON.parse(clean); if (j.question !== undefined || j.isGuess) return j; } catch (_) {}
    // Try extracting first {...} block
    const m = clean.match(/\{[\s\S]*?\}/);
    if (m) { try { return JSON.parse(m[0]); } catch (_) {} }
    // Check if it's a plain text guess
    if (clean.toLowerCase().includes('i guess:') || clean.toLowerCase().includes('my guess is')) {
      const guessMatch = clean.match(/(?:guess(?:es)?:|my guess is)[:\s]+([A-Za-z ]+)/i);
      return { question: '', thoughts: '', persona: 'dramatic', isGuess: true, guess: guessMatch?.[1]?.trim() || 'Virat Kohli' };
    }
    // Use raw text as question
    const text = clean.replace(/[{}"\[\]]/g, '').trim().slice(0, 500);
    if (text.length > 8) {
      return { question: text, thoughts: '', persona: 'confident', isGuess: false, guess: '' };
    }
    return this._fallbackParsed();
  }

  _fallbackParsed() {
    const qs = [
      "Is this IPL player/team still active today?",
      "Has this player represented India internationally?",
      "Is this player primarily a batsman?",
      "Has this player won an IPL title?",
      "Is this player a right-hander?",
      "Did this player play for Mumbai Indians?",
      "Has this player scored 3000+ IPL runs?",
      "Is this player known as a T20 specialist?",
      "Did this player play in IPL 2008 (first season)?",
      "Is this player an overseas (non-Indian) player?",
    ];
    return {
      question: qs[Math.floor(this.questionCount % qs.length)],
      thoughts: 'Narrowing down the possibilities strategically...',
      persona: this.questionCount <= 5 ? 'confident' : this.questionCount <= 10 ? 'focused' : 'tense',
      isGuess: false, guess: ''
    };
  }


  _startTimer() {
    const maxTime = 120; // 2 minutes
    this.timerInterval = setInterval(() => {
      const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
      const remaining = maxTime - elapsed;
      this.onTimer?.(remaining);
      if (remaining <= 0) {
        clearInterval(this.timerInterval);
        if (!this.gameOver) this._forceGuess();
      }
    }, 1000);
  }

  getProgress() {
    return (this.questionCount / this.maxQuestions) * 100;
  }
}

window.AkiCricketGame = AkiCricketGame;

// ─── Leaderboard (Firebase mock — replace with real Firebase) ───
class Leaderboard {
  constructor() {
    this.key = 'aki_cricket_leaderboard';
    this.data = JSON.parse(localStorage.getItem(this.key) || '[]');
  }
  addEntry(name, questions, time, akiWon) {
    const entry = { name, questions, time, akiWon, ts: Date.now() };
    this.data.unshift(entry);
    this.data = this.data.slice(0, 20);
    localStorage.setItem(this.key, JSON.stringify(this.data));
  }
  getTop(n = 10) { return this.data.slice(0, n); }
  getStreak(name) {
    let streak = 0;
    for (const e of this.data) {
      if (e.name === name && !e.akiWon) streak++;
      else if (e.name === name) break;
    }
    return streak;
  }
}
window.Leaderboard = Leaderboard;
