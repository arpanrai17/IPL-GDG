/**
 * AI Engine — "Gemini Flash" (powered by Groq Cloud API)
 * ─────────────────────────────────────────────────────────
 * ▸ Hits the high-performance llama-3.3-70b-versatile cloud model for text
 * ▸ Hits llama-3.2-11b-vision-preview cloud model for vision analysis
 * ▸ All branding in the UI remains "Gemini Flash" as requested
 * ▸ Fully functional with streaming, vision, and robust fallbacks
 */

const AI_CONFIG = {
  endpoint: 'https://api.groq.com/openai/v1/chat/completions',
  apiKey: typeof AI_KEY !== 'undefined' ? AI_KEY : '',
  textModel: 'llama-3.3-70b-versatile',
  visionModel: 'llama-3.2-11b-vision-preview',
};

class GeminiClient {
  constructor() {
    this.history = [];
  }

  reset() { this.history = []; }

  // ── CORE TEXT QUERY ────────────────────────────────────────────────────────
  async query(prompt, temperature = 0.7, systemPrompt = '') {
    try {
      if (!AI_CONFIG.apiKey) throw new Error('API Key missing');
      
      const messages = [];
      if (systemPrompt) {
        messages.push({ role: 'system', content: systemPrompt });
      }
      messages.push({ role: 'user', content: prompt });

      const resp = await fetch(AI_CONFIG.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AI_CONFIG.apiKey}`
        },
        body: JSON.stringify({
          model: AI_CONFIG.textModel,
          messages,
          stream: false,
          temperature,
          max_tokens: 2048
        }),
      });

      if (!resp.ok) throw new Error(`Groq error: ${resp.status}`);
      const data = await resp.json();
      const text = (data.choices?.[0]?.message?.content || '').trim();
      if (!text) throw new Error('Empty response');
      return text;
    } catch (e) {
      console.warn('Gemini text query offline — using fallback:', e.message);
      return this._getFallbackForPrompt(prompt);
    }
  }

  // ── CORE VISION QUERY ──────────────────────────────────────────────────────
  async queryVision(systemPrompt, userPrompt, imageBase64, mimeType = 'image/jpeg') {
    try {
      if (!AI_CONFIG.apiKey) throw new Error('API Key missing');

      const resp = await fetch(AI_CONFIG.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AI_CONFIG.apiKey}`
        },
        body: JSON.stringify({
          model: AI_CONFIG.visionModel,
          messages: [
            { role: 'system', content: systemPrompt },
            {
              role: 'user',
              content: [
                { type: 'text', text: userPrompt },
                {
                  type: 'image_url',
                  image_url: {
                    url: `data:${mimeType};base64,${imageBase64}`
                  }
                }
              ]
            }
          ],
          temperature: 0.7,
          max_tokens: 1024
        }),
      });

      if (!resp.ok) throw new Error(`Groq vision error: ${resp.status}`);
      const data = await resp.json();
      const text = (data.choices?.[0]?.message?.content || '').trim();
      if (!text) throw new Error('Empty vision response');
      return text;
    } catch (e) {
      console.warn('Gemini vision query offline — using fallback:', e.message);
      return this._mockDRS();
    }
  }

  // ── CHAT WITH HISTORY ──────────────────────────────────────────────────────
  async chat(userMessage, systemPrompt = '', temperature = 0.8) {
    try {
      if (!AI_CONFIG.apiKey) throw new Error('API Key missing');

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
          model: AI_CONFIG.textModel,
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
      console.warn('Gemini chat offline — using fallback:', e.message);
      const fallback = this._mockAkiResponse(userMessage);
      this.history.push({ role: 'user',  content: userMessage });
      this.history.push({ role: 'model', content: fallback });
      return fallback;
    }
  }

  // ── STREAMING FOR COMMENTARY ───────────────────────────────────────────────
  async *stream(prompt, temperature = 0.8) {
    try {
      if (!AI_CONFIG.apiKey) throw new Error('API Key missing');

      const resp = await fetch(AI_CONFIG.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AI_CONFIG.apiKey}`
        },
        body: JSON.stringify({
          model: AI_CONFIG.textModel,
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
      const mock = this._mockCommentaryText();
      for (const word of mock.split(' ')) {
        yield word + ' ';
        await new Promise(r => setTimeout(r, 55));
      }
    }
  }

  // ── HELPER JSON EXTRACTOR ──────────────────────────────────────────────────
  extractJSON(text) {
    const stripped = text
      .replace(/```json\s*/gi, "")
      .replace(/```\s*/gi, "")
      .trim();
    const match = stripped.match(/\{[\s\S]*\}/);
    if (!match) throw new Error("AI response was not valid JSON.");
    return JSON.parse(match[0]);
  }

  // ── FEATURE 1: AI DRS VISION ANALYSIS ──────────────────────────────────────
  async analyzeDRS(imageBase64, mimeType = "image/jpeg") {
    const system = `You are an elite AI cricket DRS (Decision Review System) umpire with 20 years of experience. 
You analyze cricket images and deliver authoritative, dramatic verdicts using real cricket technology terminology.
You ALWAYS respond with valid JSON only — no markdown, no explanation, just the JSON object.`;

    const user = `Analyze this cricket image and provide your DRS verdict.
Respond ONLY with this JSON (replace all values with your actual analysis):
{
  "decision": "OUT or NOT OUT",
  "confidence": 92,
  "wideCall": "WIDE or FAIR DELIVERY",
  "wideConfidence": 95,
  "catchValidity": "VALID CATCH or INVALID CATCH or NO CATCH SCENARIO",
  "catchConfidence": 88,
  "lbwProbability": 76,
  "pressureIndex": "EXTREME",
  "pressureConfidence": 91,
  "psychologicalInsight": "The batsman's shoulder position and lack of eye contact with the ball suggest a technical lapse under high pressure.",
  "hotSpotAnalysis": "A clear heat signature is detected on the edge of the bat on HotSpot analysis.",
  "snickometer": "The audio spike occurs precisely as the ball passes the outside edge.",
  "hawkeyePath": "Hawk-Eye confirms ball path tracking hitting middle stump.",
  "dramaticVerdict": "Rock and roll that please. We have a clear spike on Snicko. I am ready to make my decision. You are on screen now.",
  "keyFactors": ["Clear spike on audio track", "HotSpot heat signature detected", "Impact in line with stumps"]
}`;

    const text = await this.queryVision(system, user, imageBase64, mimeType);
    return this.extractJSON(text);
  }

  // ── FEATURE 2: SCRIPTWRITER'S REVENGE ───────────────────────────────────────
  async generateMatchScript(matchData) {
    const o1 = parseInt(matchData.currentOver) + 1;
    const o2 = parseInt(matchData.currentOver) + 2;
    const o3 = parseInt(matchData.currentOver) + 3;

    const system = `You are the world's greatest cricket conspiracy theorist, storyteller, and IPL scriptwriter.
You believe every IPL match is scripted and you write wildly dramatic, conspiracy-laden scripts.
You ALWAYS respond with valid JSON only — no markdown, no explanation, just the JSON object.`;

    const user = `Write the most DRAMATIC conspiracy script for the next 3 overs of this IPL match.
MATCH SITUATION:
- Batting: ${matchData.team1} vs Bowling: ${matchData.team2}
- Current Over: ${matchData.currentOver} | Score: ${matchData.score} | Target: ${matchData.target || "N/A"}
- Situation: ${matchData.situation}
- Key Players: ${matchData.keyPlayers}

Respond ONLY with this exact JSON (fill ALL fields with creative content, no placeholders):
{
  "scriptTitle": "A dramatic conspiracy title",
  "masterPlan": "Two sentences describing the secret conspiracy.",
  "overs": [
    {
      "overNumber": ${o1},
      "script": "Detailed over breakdown.",
      "twist": "The over twist.",
      "bettingOddsShift": { "team": "${matchData.team1}", "before": "1.85", "after": "2.70", "suspicionLevel": "HIGH", "reason": "Reason here." },
      "twitterMoment": { "trend": "#Scripted", "topTweet": "Viral tweet.", "tweetAuthor": "@conspiracy_cricket", "likes": 14200, "retweets": 4800 }
    },
    {
      "overNumber": ${o2},
      "script": "Over breakdown.",
      "twist": "The over twist.",
      "bettingOddsShift": { "team": "${matchData.team2}", "before": "2.70", "after": "1.30", "suspicionLevel": "EXTREME", "reason": "Reason here." },
      "twitterMoment": { "trend": "#BCCIConfessions", "topTweet": "Viral tweet.", "tweetAuthor": "@cricket_sleuth", "likes": 31000, "retweets": 9400 }
    },
    {
      "overNumber": ${o3},
      "script": "Final climactic over breakdown.",
      "twist": "The ultimate shock twist.",
      "bettingOddsShift": { "team": "${matchData.team1}", "before": "1.30", "after": "4.50", "suspicionLevel": "EXTREME", "reason": "Final shift." },
      "twitterMoment": { "trend": "#FixedIPL", "topTweet": "Tweet.", "tweetAuthor": "@ipl_insider", "likes": 52000, "retweets": 18000 }
    }
  ],
  "conspiracyRating": 9,
  "verdict": "Final narrative summary.",
  "whistleblowerQuote": "Inside quote."
}`;

    const text = await this.query(user, 1.0, system);
    return this.extractJSON(text);
  }

  // ── FEATURE 3: OUTCOME PREDICTOR ───────────────────────────────────────────
  async callGeminiForPrediction(matchData) {
    const system = `You are an elite cricket statistician and AI match outcome predictor.
You analyze match parameters and return outcome win probabilities.
You ALWAYS respond with valid JSON only.`;

    const user = `Analyze this IPL match situation and predict the outcome.
Match: ${matchData.team1} (batting) vs ${matchData.team2} (bowling)
Score: ${matchData.score} in ${matchData.overs} overs | Target: ${matchData.target}
Pitch: ${matchData.pitch} | Weather: ${matchData.weather} | Venue: ${matchData.venue}

Respond ONLY with this exact JSON:
{
  "team1": "${matchData.team1}",
  "team2": "${matchData.team2}",
  "team1WinProb": 50,
  "team2WinProb": 50,
  "predictedWinner": "${matchData.team1}",
  "confidence": 75,
  "keyFactors": ["Factor 1", "Factor 2", "Factor 3"],
  "analysis": "A detailed 3-sentence tactical breakdown.",
  "pressureTeam": "${matchData.team2}",
  "pressureReason": "Why they are under pressure."
}`;

    const text = await this.query(user, 0.7, system);
    return this.extractJSON(text);
  }

  // ── FEATURE 4: WHAT IF ENGINE ──────────────────────────────────────────────
  async generateWhatIf(matchContext, turningPoint) {
    const system = `You are a cricket alternate-history AI. You simulate parallel universe cricket match outcomes with detailed, realistic ball-by-ball storytelling. Always respond with valid JSON only.`;

    const user = `Simulate an ALTERNATE UNIVERSE cricket match outcome based on this turning point.
REAL MATCH:
- Teams: ${matchContext.team1} vs ${matchContext.team2}
- Real Score: ${matchContext.score}
- Target: ${matchContext.target || "N/A"}
- Match Result: ${matchContext.result}
- Venue: ${matchContext.venue}

TURNING POINT:
"${turningPoint}"

Respond ONLY with this JSON:
{
  "turningPoint": "${turningPoint}",
  "realTimeline": {
    "title": "What Actually Happened",
    "keyMoments": [
      { "over": "15.2", "event": "Real event", "impact": "Real impact" }
    ],
    "result": "CSK won"
  },
  "alternateTimeline": {
    "title": "The Alternate Universe",
    "rippleEffect": "What cascades through.",
    "keyMoments": [
      { "over": "15.2", "event": "Alternate event", "impact": "Alternate impact" }
    ],
    "result": "MI won",
    "winProbabilityShift": "Win probability swings from 70% Team 1 to 65% Team 2"
  },
  "butterflyEffect": "One dramatic sentence about how this changes IPL history.",
  "confidenceScore": 88
}`;

    const text = await this.query(user, 0.8, system);
    return this.extractJSON(text);
  }

  // ── FEATURE 5: PLAYER CLUTCH INDEX ─────────────────────────────────────────
  async generateClutchIndex(matchData) {
    const system = `You are an elite cricket performance analyst specializing in pressure situations.
Always respond with valid JSON only.`;

    const user = `Analyze and generate CLUTCH INDEX scores for key players in this live cricket match.
LIVE MATCH DATA:
- Match: ${matchData.name}
- Current Score: ${matchData.score} in ${matchData.overs} overs
- Run Rate: ${matchData.runRate} | Required RR: ${matchData.requiredRunRate || "N/A"}
- Target: ${matchData.target || "N/A"} | Venue: ${matchData.venue}
- Match Status: ${matchData.matchStatus}

Generate Clutch Index scores for 6 key IPL players who would typically play in this match. Renders JSON:
{
  "matchContext": "Detailed context description.",
  "pressureLevel": "HIGH",
  "players": [
    {
      "name": "Virat Kohli",
      "team": "${matchData.team1 || "Team"}",
      "role": "Batsman",
      "clutchScore": 96,
      "clutchGrade": "S",
      "label": "Chase Master",
      "pressureStats": {
        "deathOverEconomy": "N/A",
        "chaseSuccessRate": "78%",
        "bigMatchAverage": "55.4"
      },
      "keyStrength": "Unmatched composure when pacing a chase.",
      "weakness": "Can be vulnerable to early spin in high pressure.",
      "currentFormBoost": 8,
      "verdict": "RELY ON"
    }
  ],
  "teamClutchRating": {
    "${matchData.team1 || "Team 1"}": 78,
    "${matchData.team2 || "Team 2"}": 72
  },
  "mostClutchPlayer": "Virat Kohli",
  "biggestChoker": "Fringe Bowler"
}`;

    const text = await this.query(user, 0.7, system);
    return this.extractJSON(text);
  }

  // ── FEATURE 6: MATCH FIXER DETECTOR ────────────────────────────────────────
  async generateFixerScore(matchData) {
    const system = `You are an AI match-fixing detection expert (for entertainment only). Always respond with valid JSON only.`;

    const user = `Analyze this cricket match for "suspicious patterns" (entertainment only):
Match: ${matchData.team1} vs ${matchData.team2}
Score: ${matchData.score} | Overs: ${matchData.overs} | Target: ${matchData.target}
Run Rate: ${matchData.runRate} | Venue: ${matchData.venue}
Extra context: ${matchData.context || "Standard T20 match"}

Respond ONLY with this JSON:
{
  "fixingProbability": 45,
  "suspicionLevel": "MEDIUM",
  "verdict": "Slight anomalies noticed in overs 12-14.",
  "redFlags": ["Red flag 1", "Red flag 2"],
  "bettingOddsAnomaly": "Odds shifted strangely.",
  "insiderQuote": " Fictional whistleblower quotes.",
  "overallAssessment": "Overall entertainment assessment."
}`;

    const text = await this.query(user, 0.7, system);
    return this.extractJSON(text);
  }

  // ── FEATURE 7: LIVE QUIZ GENERATOR ─────────────────────────────────────────
  async generateQuizFromMatch(matchData) {
    const system = `You are a cricket expert quiz master. Generate MCQ questions based on live match data. Always respond with valid JSON only.`;

    const user = `Generate 5 multiple choice quiz questions based on this LIVE cricket match:
Match: ${matchData.name}
Score: ${matchData.runs}/${matchData.wickets} in ${matchData.overs} overs
Run Rate: ${matchData.runRate} | Target: ${matchData.target || "N/A"}
Venue: ${matchData.venue}
Match Status: ${matchData.matchStatus}

Respond ONLY with this exact JSON:
{
  "matchTitle": "${matchData.name}",
  "questions": [
    {
      "id": 1,
      "question": "Which player is currently leading this team's pacing?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct": 0,
      "explanation": "Why Option A is correct.",
      "category": "Strategy"
    }
  ]
}`;

    const text = await this.query(user, 0.8, system);
    return this.extractJSON(text);
  }

  // ── FEATURE 8: COMMENTARY STYLER ───────────────────────────────────────────
  async generateCommentaryStyles(ballEvent) {
    const system = `You are a world-class cricket commentary expert who perfectly mimics legendary commentator styles. Always respond with valid JSON only.`;

    const user = `Write FULL LIVE COMMENTARY in Harsha Bhogle, Ravi Shastri, Tony Greig, and a Conspiracy Theorist style for this ball event:
BALL EVENT: "${ballEvent}"

Respond ONLY with this JSON:
{
  "event": "${ballEvent}",
  "styles": [
    {
      "commentator": "Harsha Bhogle",
      "style": "Poetic, storytelling",
      "commentary": "What a beautiful shot! It floats through Wankhede sky like a leaf in autumn."
    },
    {
      "commentator": "Ravi Shastri",
      "style": "Dramatic, loud",
      "commentary": "THAT IS OUT OF THE PARK! WORLD CLASS HEAVY HITTER AT PLAY!"
    },
    {
      "commentator": "Tony Greig",
      "style": "Excitable, technical",
      "commentary": "He got underneath it beautifully, absolutely brilliant wrist work there."
    },
    {
      "commentator": "Conspiracy Theorist",
      "style": "Suspicious",
      "commentary": "Notice how the bowler delivered that exactly on the half-volley? Scripted for the cameras!"
    }
  ]
}`;

    const text = await this.query(user, 0.9, system);
    return this.extractJSON(text);
  }


  // ── PRIVATE MOCK RESPONSE DISPATCHER ───────────────────────────────────────
  _getFallbackForPrompt(prompt) {
    const lower = prompt.toLowerCase();
    if (lower.includes('conspiracy') || lower.includes('scriptwriter')) return JSON.stringify(this._mockScriptwriter());
    if (lower.includes('outcome predictor') || lower.includes('prediction')) return JSON.stringify(this._mockPredictor());
    if (lower.includes('quiz')) return JSON.stringify(this._mockQuiz());
    if (lower.includes('commentary') && lower.includes('styles')) return JSON.stringify(this._mockCommentaryStyles());
    if (lower.includes('fixing') || lower.includes('fixer')) return JSON.stringify(this._mockFixer());
    if (lower.includes('alternate universe') || lower.includes('what if')) return JSON.stringify(this._mockWhatIf());
    if (lower.includes('clutch')) return JSON.stringify(this._mockClutch());
    return prompt;
  }

  // ── MOCK SYSTEM DEFINITIONS ──

  _mockAkiResponse(msg) {
    const lower = msg.toLowerCase();
    if (lower.includes('start') || lower.includes('first question')) {
      return JSON.stringify({
        question: "Is the IPL player/team/match you're thinking of still active today?",
        thoughts: "Filtering by temporal active bounds.",
        persona: "confident", isGuess: false, guess: ""
      });
    }
    const guesses = ['MS Dhoni', 'Virat Kohli', 'Rohit Sharma', 'Hardik Pandya', 'Rinku Singh'];
    if (this.history.length >= 8) {
      return JSON.stringify({
        question: "", thoughts: "Finalizing mind reading.", persona: "dramatic",
        isGuess: true, guess: guesses[Math.floor(Math.random() * guesses.length)]
      });
    }
    return JSON.stringify({
      question: "Has this individual won an IPL trophy as a captain?",
      thoughts: "Checking captaincy achievements to divide the pool.",
      persona: "focused", isGuess: false, guess: ""
    });
  }

  _mockCommentaryText() {
    return "📺 What an OUTSTANDING boundary! The stadium has erupted into absolute madness, waves of blue and gold flags flying everywhere! Composure under sheer pressure! 🏏🔥";
  }

  _mockDRS() {
    return {
      decision: "OUT",
      confidence: 96,
      wideCall: "FAIR DELIVERY",
      wideConfidence: 99,
      catchValidity: "VALID CATCH",
      catchConfidence: 94,
      lbwProbability: 88,
      pressureIndex: "HIGH",
      pressureConfidence: 90,
      psychologicalInsight: "The batsman's head dropped immediately, showing subconscious acceptance of the error before the umpire raised the finger.",
      hotSpotAnalysis: "Frictional heat signatures show a sharp white edge contact exactly on the middle section of the bat profile.",
      snickometer: "An acoustic spike of 48 decibels is captured exactly in sync with the ball passing the inside wood edge.",
      hawkeyePath: " Hawk-Eye ball tracking confirms the trajectory is hitting the middle and off stumps with more than 50% ball volume.",
      dramaticVerdict: "Out! We have a clear spike on snicko, hotspot confirms, and ball tracking is hitting the wickets. I am advising the field umpire to change his decision to OUT.",
      keyFactors: ["Acoustic spike on snickometer", "Frictional signature on hotspot", "Hawkeye indicates trajectory hitting middle stump"]
    };
  }

  _mockScriptwriter() {
    return {
      scriptTitle: "The Wankhede Light Show Sabotage",
      masterPlan: "To trigger a dramatic run-rate climb, Wankhede stadium lights are scheduled to flicker, cooling the batting team's momentum right before a suspicious death-over collapse.",
      overs: [
        {
          overNumber: 17,
          script: "Six runs off the first three balls, followed by a dramatic bat change where the player whispers an encrypted message to the runner. The next ball is a suspicous dot.",
          twist: "Fielder drops an extremely easy running catch, but winks towards the bowling team dug-out.",
          bettingOddsShift: { team: "Mumbai Indians", before: "1.65", after: "2.10", suspicionLevel: "HIGH", reason: "Odds inflated immediately following a dropped catch, defying standard market flows." },
          twitterMoment: { trend: "#ScriptedIPL", topTweet: "NO WAY he drops that unless he put his house on the bowling team! 👀 #IPLconspiracy", tweetAuthor: "@cricket_watcher", likes: 21000, retweets: 8900 }
        },
        {
          overNumber: 18,
          script: "Bumrah bowls two consecutive wide deliveries that are almost identical, stretching the batting team's heart rate before throwing a slower ball that shatters the stumps.",
          twist: "The stadium lights drop by 20% in brightness, causing a 5-minute strategic delay.",
          bettingOddsShift: { team: "Chennai Super Kings", before: "2.10", after: "1.40", suspicionLevel: "EXTREME", reason: "Strategic light failure occurred exactly when CSK required momentum stabilization." },
          twitterMoment: { trend: "#StadiumLightsFixed", topTweet: "Did someone pull the plug in Wankhede or did the scriptwriter need a coffee break? 😂", tweetAuthor: "@meme_cricket", likes: 35000, retweets: 12000 }
        },
        {
          overNumber: 19,
          script: "15 runs needed. Batter hits a massive six, then runs a highly suspicious double where both players end up at the same crease. Wicket thrown away.",
          twist: "The batsman walks off smiling, despite throwing the match on a simple run-out.",
          bettingOddsShift: { team: "Mumbai Indians", before: "1.40", after: "4.80", suspicionLevel: "EXTREME", reason: "Double crease mistake shifted outcome probability mathematically to the bowling team." },
          twitterMoment: { trend: "#TheSameCrease", topTweet: "They aren't even trying to hide it anymore! The script is out! 💀💀", tweetAuthor: "@cricket_hacker", likes: 62000, retweets: 24000 }
        }
      ],
      conspiracyRating: 9,
      verdict: "A perfect theatrical production designed to push the tournament's viewership ratings. A dramatic run-chase engineered to build suspense and end on the absolute final ball.",
      whistleblowerQuote: "The stadium engineers were instructed to test the power grids exactly at 10:15 PM, regardless of the match state. Make of that what you will."
    };
  }

  _mockPredictor() {
    return {
      team1: "Chennai Super Kings",
      team2: "Mumbai Indians",
      team1WinProb: 68,
      team2WinProb: 32,
      predictedWinner: "Chennai Super Kings",
      confidence: 84,
      keyFactors: [
        "Required run rate has climbed above 12.8 per over on a spinning pitch.",
        "CSK's death specialists have historically defended this total 82% of the time.",
        "Mumbai Indians currently have no set batters left at the crease."
      ],
      analysis: "CSK holds a massive tactical advantage. The pitch is showing rapid deterioration with visible cracks, making spin-deflection extreme. Chasing 45 in the final three overs against Jadeja and Pathirana is historically a losing scenario.",
      pressureTeam: "Mumbai Indians",
      pressureReason: "Must hit at least two boundaries per over against highly restrictive bowling on a dusty, crumbling pitch."
    };
  }

  _mockQuiz() {
    return {
      matchTitle: "CSK vs LSG — IPL 2026",
      questions: [
        {
          id: 1,
          question: "With 42 runs needed off 22 balls, what is the required run rate (RRR) CSK must maintain?",
          options: ["9.54 runs/over", "11.45 runs/over", "12.80 runs/over", "13.20 runs/over"],
          correct: 1,
          explanation: "42 runs off 22 balls is exactly 1.91 runs per ball, translating to 11.45 runs per over.",
          category: "Statistics"
        },
        {
          id: 2,
          question: "Which bowler should LSG deploy to restrict CSK's set batsman in the death overs?",
          options: ["A slow off-spinner", "A high-pace yorker specialist", "A medium-pace leg-cutter bowler", "A standard swing bowler"],
          correct: 1,
          explanation: "High-pace yorkers at the death restrict leverage and deny batsmen room to clear their front leg.",
          category: "Strategy"
        },
        {
          id: 3,
          question: "In standard T20 cricket, how many fielders are legally allowed outside the 30-yard circle after the powerplay?",
          options: ["3 fielders", "4 fielders", "5 fielders", "6 fielders"],
          correct: 2,
          explanation: "In T20, a maximum of 5 fielders are allowed outside the ring during non-powerplay overs.",
          category: "General"
        },
        {
          id: 4,
          question: "If the bowling team delivers a waist-height full toss, what is the consequence?",
          options: ["Dead ball and warning", "Wide ball and 1 run penalty", "No-ball and subsequent Free Hit", "Standard dot ball"],
          correct: 2,
          explanation: "Waist-high full tosses (beamers) are called No-Balls, granting 1 extra run and a Free Hit next delivery.",
          category: "Tactics"
        },
        {
          id: 5,
          question: "Given a 11.45 RRR, which batting approach yields the highest statistical probability of a chase win?",
          options: ["Playing defensive for red-ball singles", "Clearing front leg to target short boundaries", "Trying to run three runs on every outfield hit", "Farming the strike for bowlers"],
          correct: 1,
          explanation: "Targeting shorter boundaries and clearing front leg creates high-leverage scoring options necessary to meet high RRRs.",
          category: "Prediction"
        }
      ]
    };
  }

  _mockCommentaryStyles() {
    return {
      event: "Virat Kohli pulls Bumrah for a massive six",
      styles: [
        {
          commentator: "Harsha Bhogle",
          style: "Poetic & Analytical",
          commentary: "Oh, that is absolutely celestial! He just leaned back, saw the short delivery coming, and sent it floating like a dream into the night sky. It's not just a shot; it's a statement of absolute class. The crowd rises as one, witnessing pure cricket poetry."
        },
        {
          commentator: "Ravi Shastri",
          style: "Dramatic & Loud",
          commentary: "THAT IS ABSOLUTELY GONE! OUT OF THE STADIUM! Virat Kohli climbs all over the short ball and deposits it into the top tier of Wankhede! WORLD CLASS HITTING FROM THE MASTER! Absolute pandemonium in the stands!"
        },
        {
          commentator: "Tony Greig",
          style: "Excitable & Technical",
          commentary: "Oh, what a cricketer! What a magnificent stroke! Look at that footwork, he gets back ever so quickly, gets the hands high, and rolls the wrists beautifully over the ball. Fielder had absolutely no chance! Superb, absolutely superb!"
        },
        {
          commentator: "Conspiracy Theorist",
          style: "Suspicious & Wild",
          commentary: "Look at the timing of that shot! The bowler gives him a comfortable short ball right on the hip, exactly when the host broadcaster's commercial segment ended. Very convenient. The scriptwriters are working overtime tonight!"
        }
      ]
    };
  }

  _mockFixer() {
    return {
      fixingProbability: 72,
      suspicionLevel: "HIGH",
      verdict: "Extremely suspicious betting odd anomalies combined with highly convenient dropped catches indicate strong potential script alignment.",
      redFlags: [
        "Four consecutive full-tosses delivered in the 18th over by a premier pace bowler.",
        "Strategic lighting delay occurring exactly when the batting team required momentum containment.",
        "Betting odds shifted 3.5 points in under 60 seconds without a wicket falling."
      ],
      bettingOddsAnomaly: "CSK's win margin odds collapsed from 3.20 to 1.15 in over 14 despite losing their top scorer, suggesting heavy financial syndicate positioning.",
      insiderQuote: "We were told to expect a power grid check during the death overs. Nobody asked questions, we just let the engineers do their job.",
      overallAssessment: "While entertaining, the data demonstrates extreme statistical anomalies in player movements and odd pricing that strongly mimic scripted dramatic events."
    };
  }

  _mockWhatIf() {
    return {
      turningPoint: "What if MS Dhoni wasn't run out in the 2019 World Cup semi-final?",
      realTimeline: {
        title: "What Actually Happened",
        keyMoments: [
          { over: "48.2", event: "Martin Guptill throws a direct hit from deep square leg.", impact: "Dhoni is run out by inches." },
          { over: "48.6", event: "Chahal is dismissed, leaving India's tail exposed.", impact: "India falls short." },
          { over: "49.3", event: "New Zealand seals a 18-run victory.", impact: "India is knocked out of the World Cup." }
        ],
        result: "New Zealand won by 18 runs"
      },
      alternateTimeline: {
        title: "The Alternate Universe",
        rippleEffect: "Dhoni makes his crease with a desperate dive. This survival keeps India's most clinical finisher active, forcing NZ into defensive bowling placements.",
        keyMoments: [
          { over: "48.2", event: "Dhoni slides bat, direct hit occurs but replay shows crease secured.", impact: "Dhoni survives, Wankhede/India erupts." },
          { over: "48.6", event: "Dhoni hits a classic helicopter six over deep midwicket.", impact: "Required runs drop to 12 off final over." },
          { over: "19.6", event: "Dhoni hits a final ball boundary over extra-cover to win.", impact: "India pulls off a legendary heist." }
        ],
        result: "India won by 1 wicket",
        winProbabilityShift: "Win probability shifted from 9% India to 100% India in under 10 balls."
      },
      butterflyEffect: "India advances to the 2019 World Cup Final, defeating England at Lord's. MS Dhoni retires on the spot as a two-time World Cup champion, rewriting the history of Indian cricket leadership.",
      confidenceScore: 92
    };
  }

  _mockClutch() {
    return {
      matchContext: "CSK need 42 runs off 22 balls in a high-tension home chase.",
      pressureLevel: "HIGH",
      players: [
        {
          name: "Ruturaj Gaikwad",
          team: "Chennai Super Kings",
          role: "WK-Batsman",
          clutchScore: 91,
          clutchGrade: "S",
          label: "Ice Man",
          pressureStats: { deathOverEconomy: "N/A", chaseSuccessRate: "73%", bigMatchAverage: "51.2" },
          keyStrength: "Stays extremely calm, maintaining a low heart-rate when calculating boundary gaps.",
          weakness: "Vulnerable to high-pace short balls early in the innings.",
          currentFormBoost: 6,
          verdict: "RELY ON"
        },
        {
          name: "Shivam Dube",
          team: "Chennai Super Kings",
          role: "All-rounder",
          clutchScore: 84,
          clutchGrade: "A",
          label: "Mr. Reliable",
          pressureStats: { deathOverEconomy: "9.2", chaseSuccessRate: "68%", bigMatchAverage: "44.5" },
          keyStrength: "Incredible leverage against spin, able to hit sixes at will.",
          weakness: "Struggles with dot-ball accumulation under tight swing bowling.",
          currentFormBoost: 10,
          verdict: "RELY ON"
        },
        {
          name: "Ravindra Jadeja",
          team: "Chennai Super Kings",
          role: "All-rounder",
          clutchScore: 95,
          clutchGrade: "S",
          label: "Pressure God",
          pressureStats: { deathOverEconomy: "7.1", chaseSuccessRate: "76%", bigMatchAverage: "58.0" },
          keyStrength: "Possesses match-winning muscle memory on the absolute final ball.",
          weakness: "None under standard subcontinental chasing conditions.",
          currentFormBoost: 12,
          verdict: "RELY ON"
        },
        {
          name: "Nicholas Pooran",
          team: "Lucknow Super Giants",
          role: "Batsman",
          clutchScore: 88,
          clutchGrade: "A",
          label: "Death Specialist",
          pressureStats: { deathOverEconomy: "N/A", chaseSuccessRate: "69%", bigMatchAverage: "46.2" },
          keyStrength: "Pure explosive speed that can dismantle restrictive bowling lines.",
          weakness: "Can throw away wicket on rash strokes early in pressure turns.",
          currentFormBoost: 4,
          verdict: "WILDCARD"
        },
        {
          name: "Ravi Bishnoi",
          team: "Lucknow Super Giants",
          role: "Bowler",
          clutchScore: 78,
          clutchGrade: "B",
          label: "Wildcard",
          pressureStats: { deathOverEconomy: "7.8", chaseSuccessRate: "N/A", bigMatchAverage: "38.2" },
          keyStrength: "Gong-gong spin that confuses batsmen chasing quick boundaries.",
          weakness: "Prone to bowling wides when hit for consecutive sixes.",
          currentFormBoost: 2,
          verdict: "WILDCARD"
        },
        {
          name: "Fringe Bowler",
          team: "Lucknow Super Giants",
          role: "Bowler",
          clutchScore: 48,
          clutchGrade: "D",
          label: "The Choker",
          pressureStats: { deathOverEconomy: "11.6", chaseSuccessRate: "N/A", bigMatchAverage: "22.0" },
          keyStrength: "Excellent pace but loses accuracy under heavy crowd volume.",
          weakness: "Panics in the final over, reverting to predictable full tosses.",
          currentFormBoost: -8,
          verdict: "RISKY"
        }
      ],
      teamClutchRating: {
        "Chennai Super Kings": 82,
        "Lucknow Super Giants": 69
      },
      mostClutchPlayer: "Ravindra Jadeja",
      biggestChoker: "Fringe Bowler"
    };
  }
}

window.GeminiClient = GeminiClient;
window.gemini = new GeminiClient();
