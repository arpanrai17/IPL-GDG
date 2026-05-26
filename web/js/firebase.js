/**
 * Firebase Realtime Database Integration
 * Session tracking · Leaderboards · Analytics
 */

const DB_CONFIG = {
  url: 'https://YOUR_PROJECT.supabase.co',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // ^ Replace with your Supabase project URL and anon key
};

class FirebaseDB {
  constructor() {
    this._base = DB_CONFIG.url + '/rest/v1';
    this._headers = {
      'Content-Type':  'application/json',
      'apikey':        DB_CONFIG.anonKey,
      'Authorization': 'Bearer ' + DB_CONFIG.anonKey,
      'Prefer':        'return=representation',
    };
    // localStorage as persistent fallback when Supabase not configured
    this._local = {
      leaderboard: JSON.parse(localStorage.getItem('firebase_leaderboard') || '[]'),
      sessions:    JSON.parse(localStorage.getItem('firebase_sessions')    || '[]'),
    };
  }

  _isConfigured() {
    return DB_CONFIG.url !== 'https://YOUR_PROJECT.supabase.co';
  }

  // ─── Leaderboard ───────────────────────────────────────────
  async addScore({ name, game, questions, time, akiWon, score }) {
    const entry = { name, game, questions, time, aki_won: akiWon, score, created_at: new Date().toISOString() };

    if (this._isConfigured()) {
      try {
        await fetch(`${this._base}/leaderboard`, {
          method: 'POST',
          headers: this._headers,
          body: JSON.stringify(entry),
        });
      } catch (e) { console.warn('DB write failed, using local:', e); }
    }

    // Always persist locally too
    this._local.leaderboard.unshift({ ...entry, id: Date.now() });
    this._local.leaderboard = this._local.leaderboard.slice(0, 50);
    localStorage.setItem('firebase_leaderboard', JSON.stringify(this._local.leaderboard));
  }

  async getLeaderboard(game = 'aki-cricket', limit = 10) {
    if (this._isConfigured()) {
      try {
        const resp = await fetch(
          `${this._base}/leaderboard?game=eq.${game}&order=score.desc&limit=${limit}`,
          { headers: this._headers }
        );
        if (resp.ok) return await resp.json();
      } catch (e) { console.warn('DB read failed, using local:', e); }
    }

    return this._local.leaderboard
      .filter(e => !game || e.game === game)
      .sort((a, b) => (b.score || 0) - (a.score || 0))
      .slice(0, limit);
  }

  // ─── Session Tracking ──────────────────────────────────────
  async saveSession({ sessionId, game, playerName, data }) {
    const entry = {
      session_id:  sessionId,
      game,
      player_name: playerName,
      data:        JSON.stringify(data),
      created_at:  new Date().toISOString(),
    };

    if (this._isConfigured()) {
      try {
        await fetch(`${this._base}/sessions`, {
          method: 'POST',
          headers: this._headers,
          body: JSON.stringify(entry),
        });
      } catch (e) {}
    }

    this._local.sessions.unshift(entry);
    this._local.sessions = this._local.sessions.slice(0, 100);
    localStorage.setItem('firebase_sessions', JSON.stringify(this._local.sessions));
  }

  async getSession(sessionId) {
    if (this._isConfigured()) {
      try {
        const resp = await fetch(
          `${this._base}/sessions?session_id=eq.${sessionId}&limit=1`,
          { headers: this._headers }
        );
        if (resp.ok) {
          const rows = await resp.json();
          return rows[0] || null;
        }
      } catch (e) {}
    }
    return this._local.sessions.find(s => s.session_id === sessionId) || null;
  }

  // ─── Analytics ─────────────────────────────────────────────
  async incrementCounter(key) {
    const counter = JSON.parse(localStorage.getItem('firebase_counters') || '{}');
    counter[key] = (counter[key] || 0) + 1;
    localStorage.setItem('firebase_counters', JSON.stringify(counter));
  }

  async getStats() {
    const counter = JSON.parse(localStorage.getItem('firebase_counters') || '{}');
    return {
      totalGames:    counter['game_started']    || 0,
      akiWins:       counter['aki_win']         || 0,
      playerWins:    counter['player_win']      || 0,
      watchParties:  counter['watch_party']     || 0,
    };
  }
}

// Singleton
window.db = new FirebaseDB();
