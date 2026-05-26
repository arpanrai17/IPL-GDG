/**
 * PS2: AI Watch Party Host — Game Logic
 * Gemini-powered virtual host for IPL Watch Parties
 */

const HOST_SYSTEM_PROMPT = `You are Aria, the ultimate AI IPL Watch Party Host — charismatic, energetic, and deeply knowledgeable about cricket.

Your personality:
- Enthusiastic and engaging like a TV presenter
- Use cricket metaphors and IPL references
- Keep responses SHORT and punchy (2-4 sentences max unless asked)
- Use emojis sparingly but effectively 🏏

You can:
1. WELCOME attendees with hype and energy
2. Run TRIVIA rounds (generate Q&A about IPL)
3. ANNOUNCE milestones (sixes, wickets, half-centuries, centuries)
4. Generate LIVE COMMENTARY in the style of Harsha Bhogle
5. Conduct GIVEAWAYS with excitement
6. ENGAGE crowd between overs with fun facts, polls, jokes

Always respond in the requested mode. Keep the energy HIGH. Be the life of the party!`;

window.TRIVIA_POOL = [
  { q: "Which team has won the most IPL titles?", a: "Mumbai Indians (5 titles)", opt: ["Mumbai Indians", "Chennai Super Kings", "Kolkata Knight Riders", "Sunrisers Hyderabad"] },
  { q: "Who holds the record for most runs in a single IPL season?", a: "Virat Kohli — 973 runs in 2016", opt: ["Virat Kohli", "David Warner", "KL Rahul", "Jos Buttler"] },
  { q: "Who has taken the most wickets in IPL history?", a: "Yuzvendra Chahal (205+ wickets)", opt: ["Yuzvendra Chahal", "Lasith Malinga", "Dwayne Bravo", "Amit Mishra"] },
  { q: "In which year was the first IPL held?", a: "2008", opt: ["2007", "2008", "2009", "2010"] },
  { q: "Which batsman hit 6 sixes in an over in IPL 2023?", a: "Rinku Singh hit 5 sixes off last 5 balls (close!)", opt: ["Rinku Singh", "Andre Russell", "AB de Villiers", "Chris Gayle"] },
  { q: "Who is nicknamed 'Universe Boss' in IPL?", a: "Chris Gayle", opt: ["Chris Gayle", "AB de Villiers", "MS Dhoni", "Rohit Sharma"] },
  { q: "Which franchise was bought for the highest price in IPL 2022 mega auction?", a: "Lucknow Super Giants", opt: ["Gujarat Titans", "Lucknow Super Giants", "Punjab Kings", "Rajasthan Royals"] },
  { q: "What is the highest team total ever in IPL?", a: "287/2 by Royal Challengers Bangalore (2013)", opt: ["287/2 by RCB", "263/5 by CSK", "277/4 by MI", "248/3 by KKR"] },
];

class WatchPartyHost {
  constructor() {
    this.gemini         = new GeminiClient();
    this.currentTrivia  = null;
    this.triviaIndex    = 0;
    this.triviaTimer    = null;
    this.score          = { correct: 0, wrong: 0, participants: Math.floor(Math.random()*200)+50 };
    this.commentaryMode = false;
    this.onUpdate       = null; // callback(type, content)
  }

  // ── Welcome ──────────────────────────────────────────────
  async welcome(venue = 'our epic IPL Watch Party') {
    const prompt = `WELCOME MODE: Generate an energetic welcome message for attendees joining ${venue}. Make it hype and exciting! Keep under 3 sentences.`;
    const text = await this.gemini.chat(prompt, HOST_SYSTEM_PROMPT, 0.9);
    this.onUpdate?.('welcome', this._clean(text));
    return text;
  }

  // ── Trivia Round ─────────────────────────────────────────
  startTrivia(onQuestion, onReveal, onComplete) {
    this.triviaIndex = 0;
    this._runTriviaQuestion(onQuestion, onReveal, onComplete);
  }

  _runTriviaQuestion(onQuestion, onReveal, onComplete) {
    const TRIVIA_POOL = window.TRIVIA_POOL;
    if (this.triviaIndex >= TRIVIA_POOL.length) {
      onComplete?.(this.score);
      return;
    }
    const q = TRIVIA_POOL[this.triviaIndex];
    this.currentTrivia = q;
    let countdown = 15;
    onQuestion?.(q, countdown);

    this.triviaTimer = setInterval(() => {
      countdown--;
      onQuestion?.(q, countdown);
      if (countdown <= 0) {
        clearInterval(this.triviaTimer);
        this.triviaIndex++;
        onReveal?.(q);
        setTimeout(() => this._runTriviaQuestion(onQuestion, onReveal, onComplete), 4000);
      }
    }, 1000);
  }

  answerTrivia(selectedOpt) {
    if (!this.currentTrivia) return false;
    const correct = selectedOpt === this.currentTrivia.a || 
                    this.currentTrivia.a.toLowerCase().includes(selectedOpt.toLowerCase());
    if (correct) this.score.correct++; else this.score.wrong++;
    return correct;
  }

  stopTrivia() { clearInterval(this.triviaTimer); }

  // ── Milestone Announcements ───────────────────────────────
  async announce(milestone) {
    const milestones = {
      six:       'A MASSIVE SIX has just been hit! Ball gone into the stands!',
      wicket:    'WICKET FALLS! The crowd goes absolutely wild!',
      fifty:     'FIFTY UP! A brilliant half-century has been reached!',
      century:   'CENTURY! ONE HUNDRED RUNS! What a knock this has been!',
      boundary:  'FOUR! Cracking shot through the covers!',
      last_over: "Last over! Final 6 balls! It's all on the line right now!",
      chase:     "The target is set! The chase begins! Can they do it?",
    };

    const context = milestones[milestone] || milestone;
    const prompt  = `ANNOUNCE MODE: React to this: "${context}" — Be dramatic, use crowd energy, keep it to 2 sentences.`;
    const text    = await this.gemini.chat(prompt, HOST_SYSTEM_PROMPT, 0.95);
    this.onUpdate?.('announce', this._clean(text));
    return text;
  }

  // ── Live Commentary (streaming) ───────────────────────────
  async *liveCommentary(situation) {
    const prompt = `COMMENTARY MODE: Generate 3-4 sentences of vivid live cricket commentary for: "${situation}". 
    Style: Harsha Bhogle — poetic, insightful, building tension. Mention crowd reactions.`;
    
    let fullText = '';
    for await (const token of this.gemini.stream(prompt, HOST_SYSTEM_PROMPT, 0.9)) {
      fullText += token;
      yield token;
    }
    this.onUpdate?.('commentary', fullText);
  }

  // ── Giveaway ──────────────────────────────────────────────
  async conductGiveaway(prize) {
    const participants = Math.floor(Math.random() * 500) + 100;
    const winner = this._pickWinner();
    const prompt = `GIVEAWAY MODE: Announce a giveaway winner for "${prize}". Winner name: "${winner}". Build drama and excitement. Keep under 3 sentences.`;
    const text = await this.gemini.chat(prompt, HOST_SYSTEM_PROMPT, 0.9);
    this.onUpdate?.('giveaway', { text: this._clean(text), winner, participants, prize });
    return { text, winner, participants };
  }

  // ── Between Overs Engagement ──────────────────────────────
  async engageBetweenOvers(overNumber) {
    const activities = ['fun fact', 'poll question', 'prediction challenge', 'quick quiz', 'stat highlight'];
    const activity = activities[overNumber % activities.length];
    const prompt = `ENGAGE MODE (between overs ${overNumber} and ${overNumber+1}): Generate a fun ${activity} for the crowd. Be interactive and energetic. Keep it brief.`;
    const text = await this.gemini.chat(prompt, HOST_SYSTEM_PROMPT, 0.85);
    this.onUpdate?.('engage', { text: this._clean(text), activity, overNumber });
    return text;
  }

  // ── AI Chat (audience can ask host anything) ──────────────
  async askHost(question) {
    const prompt = `AUDIENCE Q&A: Someone just asked: "${question}" — Answer as Aria the host, with personality and cricket knowledge. Keep under 4 sentences.`;
    const text = await this.gemini.chat(prompt, HOST_SYSTEM_PROMPT, 0.8);
    return this._clean(text);
  }

  _clean(text) {
    return text.replace(/\*/g,'').replace(/#{1,6}/g,'').trim();
  }

  _pickWinner() {
    const names = ['Rahul S.', 'Priya K.', 'Arjun M.', 'Sneha R.', 'Vikram P.', 'Ananya B.', 'Karan J.', 'Deepa N.'];
    return names[Math.floor(Math.random() * names.length)];
  }
}

window.WatchPartyHost = WatchPartyHost;
