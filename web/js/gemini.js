/**
 * AI Engine — "Gemini Flash" (powered by Groq Cloud API)
 * ─────────────────────────────────────────────────────────
 * ▸ Hits the high-performance llama-3.3-70b-versatile cloud model
 * ▸ All branding in the UI remains "Gemini Flash" as requested
 * ▸ Fully functional with streaming and fallbacks
 */

const AI_CONFIG = {
  endpoint: 'https://api.groq.com/openai/v1/chat/completions',
  apiKey: typeof AI_KEY !== 'undefined' ? AI_KEY : '',
  model: 'llama-3.3-70b-versatile',
};

class GeminiClient {
  constructor() {
    this.history = [];
  }

  reset() { this.history = []; }

  async chat(userMessage, systemPrompt = '', temperature = 0.8) {
    try {
      const messages = [];
      if (systemPrompt) {
        messages.push({ role: 'system', content: systemPrompt });
      }
      for (const h of this.history) {
        messages.push({ role: h.role === 'model' ? 'assistant' : 'user', content: h.content });
      }
      messages.push({ role: 'user', content: userMessage });

      const resp = await fetch(AI_CONFIG.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AI_CONFIG.apiKey}`
        },
        body: JSON.stringify({
          model: AI_CONFIG.model,
          messages,
          stream: false,
          temperature,
          max_tokens: 1024
        }),
      });

      if (!resp.ok) throw new Error(`Groq error: ${resp.status}`);
      const data = await resp.json();
      const text = (data.choices?.[0]?.message?.content || '').trim();
      if (!text) throw new Error('Empty response');

      this.history.push({ role: 'user',  content: userMessage });
      this.history.push({ role: 'model', content: text });
      return text;
    } catch (e) {
      console.warn('Gemini (Groq) offline — using fallback:', e.message);
      const fallback = this._mockResponse(userMessage);
      this.history.push({ role: 'user',  content: userMessage });
      this.history.push({ role: 'model', content: fallback });
      return fallback;
    }
  }

  // Simple generate (no history)
  async query(prompt, temperature = 0.7) {
    try {
      const resp = await fetch(AI_CONFIG.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AI_CONFIG.apiKey}`
        },
        body: JSON.stringify({
          model: AI_CONFIG.model,
          messages: [{ role: 'user', content: prompt }],
          stream: false,
          temperature,
          max_tokens: 1024
        }),
      });
      if (!resp.ok) throw new Error(`Groq error: ${resp.status}`);
      const data = await resp.json();
      return (data.choices?.[0]?.message?.content || '').trim() || this._mockResponse(prompt);
    } catch (e) {
      console.warn('Gemini query fallback:', e.message);
      return this._mockResponse(prompt);
    }
  }

  // Streaming generate
  async *stream(prompt, temperature = 0.8) {
    try {
      const resp = await fetch(AI_CONFIG.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AI_CONFIG.apiKey}`
        },
        body: JSON.stringify({
          model: AI_CONFIG.model,
          messages: [{ role: 'user', content: prompt }],
          stream: true,
          temperature,
          max_tokens: 1024
        }),
      });

      if (!resp.ok) throw new Error(`Groq stream error: ${resp.status}`);

      const reader = resp.body.getReader();
      const decoder = new TextDecoder();
      let fullText = '';
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          const cleaned = line.trim();
          if (!cleaned.startsWith('data:')) continue;
          const jsonStr = cleaned.slice(5).trim();
          if (jsonStr === '[DONE]') break;
          try {
            const parsed = JSON.parse(jsonStr);
            const token = parsed.choices?.[0]?.delta?.content || '';
            if (token) {
              fullText += token;
              yield token;
            }
          } catch (_) {}
        }
      }
      this.history.push({ role: 'model', content: fullText });
    } catch (e) {
      console.warn('Stream fallback:', e.message);
      const mock = this._mockCommentary();
      for (const word of mock.split(' ')) {
        yield word + ' ';
        await new Promise(r => setTimeout(r, 55));
      }
    }
  }

  // ─── Fallbacks for when Ollama is offline ─────────────────────────
  _mockResponse(msg) {
    const lower = msg.toLowerCase();

    // Aki-Cricket JSON responses
    if (lower.includes('start') || lower.includes('first question')) {
      return JSON.stringify({
        question: "Is the IPL player/team/match you're thinking of still active today?",
        thoughts: "Starting with a broad temporal filter to divide the pool in half.",
        persona: "confident", isGuess: false, guess: ""
      });
    }
    if (lower.includes('yes')) {
      return JSON.stringify({
        question: "Does this player bat in the top 4 of the batting order?",
        thoughts: "Narrowing by batting role — top-order batsmen are a known set.",
        persona: "confident", isGuess: false, guess: ""
      });
    }
    if (lower.includes('no')) {
      return JSON.stringify({
        question: "Is this player primarily known as a bowler?",
        thoughts: "Ruling out batsmen — checking if bowler or all-rounder.",
        persona: "focused", isGuess: false, guess: ""
      });
    }
    if (lower.includes('india') || lower.includes('national')) {
      return JSON.stringify({
        question: "Has this player ever captained their national team?",
        thoughts: "Captaincy is a strong distinguishing feature.",
        persona: "focused", isGuess: false, guess: ""
      });
    }
    if (lower.includes('guess') || lower.includes('all 15') || lower.includes('best guess')) {
      const guesses = ['MS Dhoni', 'Virat Kohli', 'Rohit Sharma', 'Mumbai Indians', 'Chennai Super Kings', 'AB de Villiers'];
      return JSON.stringify({
        question: "", thoughts: "Best guess based on all clues.", persona: "dramatic",
        isGuess: true, guess: guesses[Math.floor(Math.random() * guesses.length)]
      });
    }

    // Commentary / Watch Party text responses
    if (lower.includes('welcome') || lower.includes('host')) return this._mockWelcome(msg);
    if (lower.includes('six') || lower.includes('wicket') || lower.includes('milestone')) return this._mockMilestone(lower);
    if (lower.includes('commentary') || lower.includes('situation')) return this._mockCommentary();
    if (lower.includes('giveaway') || lower.includes('prize')) return this._mockGiveaway();

    // Generic Aki question fallback
    const fallbackQs = [
      { question: "Has this player represented India in international cricket?", thoughts: "Checking nationality — major filter.", persona: "focused" },
      { question: "Has this player won an IPL title?", thoughts: "Champions are a much smaller pool.", persona: "confident" },
      { question: "Is this player a right-handed batsman?", thoughts: "Handedness narrows the pool significantly.", persona: "focused" },
      { question: "Did this player play before 2015?", thoughts: "Temporal filter — era of play.", persona: "tense" },
      { question: "Is this player from Mumbai?", thoughts: "Geography can be a decisive filter.", persona: "focused" },
      { question: "Has this player hit more than 200 sixes in IPL?", thoughts: "Power hitters form a small exclusive club.", persona: "dramatic" },
    ];
    const q = fallbackQs[this.history.length % fallbackQs.length];
    return JSON.stringify({ ...q, isGuess: false, guess: "" });
  }

  _mockWelcome(msg) {
    return `🎙️ WELCOME to the most ELECTRIC IPL watch party of the season! I'm Aria, your Gemini-powered AI host! The stadium is PACKED, the energy is absolutely OFF THE CHARTS, and tonight we make HISTORY! Get ready for live trivia, epic commentary, incredible giveaways, and so much more! Are you ready?! LET'S. GO! 🏏🔥🎉`;
  }

  _mockCommentary() {
    const lines = [
      "📺 What a SPECTACULAR delivery! The crowd has erupted — you can feel the electricity right through the stadium! The batsman played that with supreme confidence, and the ball races to the boundary! Absolutely breathtaking IPL cricket! 🏏🔥",
      "📺 And what a MOMENT! The crowd is on its feet! This is why IPL cricket is the greatest show on Earth — pure drama, pure skill, pure MAGIC! The stadium has never been louder! 🎉",
      "📺 UNBELIEVABLE! The batsman has timed that to perfection — the fielder dives, can't reach it! FOUR RUNS! The roar from the crowd is deafening! This match has everything! 🏏",
    ];
    return lines[Math.floor(Math.random() * lines.length)];
  }

  _mockMilestone(p) {
    if (p.includes('six'))     return '💥 BOOM! That ball is GONE — way into the stands! What a MONSTROUS hit! The crowd has gone absolutely BERSERK! This is IPL cricket at its most ELECTRIC! 🔥';
    if (p.includes('wicket'))  return '🎯 BOWLED HIM! What a sensational delivery! The stumps shatter and the fielding team ERUPTS! This changes EVERYTHING in this match! 🏏';
    if (p.includes('century')) return '💯 ONE HUNDRED! A MAGNIFICENT century! The entire stadium rises as one! This is a performance that will be remembered FOREVER in IPL history! 🏆';
    if (p.includes('fifty'))   return '5️⃣0️⃣ FIFTY! A crucial half-century at the perfect moment! The innings is building beautifully and the crowd is absolutely loving it! 👏';
    if (p.includes('super'))   return '🔥 SUPER OVER!! The tension is UNBEARABLE! After 20 overs, both teams are TIED! This is what DREAMS are made of — absolute madness! 😱';
    if (p.includes('last') || p.includes('over')) return '⏰ LAST OVER! Six balls. Everything on the line. The crowd is holding their breath! Who will be tonight\'s HERO?! 😤';
    return '🎉 UNBELIEVABLE! The crowd has ERUPTED! This is the moment every cricket fan lives for! Pure IPL magic! 🏏🔥';
  }

  _mockGiveaway() {
    return '🎊 After careful Gemini AI analysis of all our incredible participants and a nail-biting randomized selection process... the moment you\'ve all been waiting for...';
  }
}

window.GeminiClient = GeminiClient;
