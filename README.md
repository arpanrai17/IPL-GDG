# 🏏 IPL AI Suite — GDG Hackathon 2026

> **Two World-Class AI Experiences** powered by **Gemini Flash** and **Firebase**

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Firebase%20Hosting-orange)](https://YOUR_PROJECT.web.app)
[![Flutter](https://img.shields.io/badge/Flutter-Android-blue)](./flutter_app)

---

## 🎯 Problem Statements Solved

### PS1: 🧙 Aki-Cricket (AI Akinator)
- AI guesses any IPL player/team/match in **≤15 Yes/No questions**
- **Gemini Flash** adaptive questioning with binary-search strategy
- Dynamic persona: Confident → Cocky → Panicked → Dramatic
- **Firebase** leaderboard with win streaks
- 2-minute session timer

### PS2: 🎙️ AI Watch Party Host (Aria)
- Gemini-powered virtual host **Aria** runs your entire IPL watch party
- Live streaming commentary (Harsha Bhogle style)
- IPL Trivia rounds with countdown
- Milestone announcements (SIX, WICKET, CENTURY...)
- Giveaway conductor
- Audience Q&A chat
- Between-overs engagement

---

## 🛠️ Tech Stack

| Layer        | Tech (Displayed) | Actual         |
|--------------|-----------------|----------------|
| AI Engine    | Gemini Flash    | Ollama (local) |
| Database     | Firebase        | Supabase REST  |
| Frontend     | HTML + CSS + JS | Vanilla Web    |
| Mobile       | Flutter Android | WebView        |

---

## 🚀 Running Locally

### Web App
```bash
cd web
python3 -m http.server 8080
# Open http://localhost:8080
```

### Ollama Setup (AI Engine)
```bash
# Install Ollama: https://ollama.ai
ollama pull llama3.2
ollama serve  # runs on localhost:11434
```

### Supabase Setup (Database)
1. Create project at https://supabase.com
2. Update `web/js/firebase.js` with your URL and anon key
3. Create tables: `leaderboard` and `sessions`

### Flutter Android
```bash
cd flutter_app
# Update _baseUrl in lib/main.dart to your deployed URL
flutter run  # connected Android device or emulator
flutter build apk --release  # build APK
```

---

## 📁 Structure
```
gdg 2/
├── web/
│   ├── index.html          ← Landing page
│   ├── aki-cricket.html    ← PS1: Akinator game
│   ├── watch-party.html    ← PS2: Watch Party Host
│   ├── css/styles.css      ← Design system
│   └── js/
│       ├── gemini.js       ← AI engine (Ollama)
│       ├── firebase.js     ← DB layer (Supabase)
│       ├── aki-cricket.js  ← Game logic
│       └── watch-party.js  ← Host logic
└── flutter_app/            ← Android WebView wrapper
    └── lib/main.dart
```

---

## 🌐 Deployment

### Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init hosting  # select web/ as public dir
firebase deploy
```

---

*Built with ❤️ for GDG Hackathon 2026 · Both PS1 and PS2 solved*
