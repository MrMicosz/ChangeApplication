# 🧰 MultiTool — All-in-One Desktop Toolkit

A unified Windows utility that combines **Currency Converter** and **Smart Translator** into a single, always-on app with customizable keyboard shortcuts. One system tray icon, multiple tools at your fingertips.

---

## ✨ Features

### 🏠 MultiTool Hub (`Ctrl+Shift+Space`)
- Beautiful dark mode launcher with quick access to all tools
- One-click navigation to any tool
- Language selector (5 languages)
- Shows all keyboard shortcuts at a glance

### 💱 Currency Converter (`Ctrl+Shift+C`)
- **Smart Hotkey Conversion** — Highlight any number → press hotkey → get result instantly
- **7 Major Fiat Currencies** — USD, EUR, JPY, GBP, THB, KRW, CNY
- **₿ Bitcoin (BTC) Support** — via [CoinGecko](https://www.coingecko.com/)
- **Mini Dashboard** — See your amount in multiple currencies at once
- **Auto-Copy Result** — optional clipboard auto-copy
- Always on top, dark mode UI

### 🌐 Smart Translator (`Ctrl+Shift+T`)
- **AI-Powered Translation** — Powered by Gemini 2.5 Flash
- **Auto-detect Language** — Thai text → English, other languages → Thai
- **3 Modes:**
  - `Ctrl+Shift+T` — Translate & show popup
  - `Ctrl+Shift+R` — Translate & replace text in-place
  - `Ctrl+Shift+Y` — Copy last translation
- **Overlay popup** with fade animations
- Clipboard is always restored after operation

### ⚙️ Premium Settings Hub
- **Tabbed UI** — General / Currency / Translator / Hotkeys
- Dark mode design with indigo accent colors
- Customize all keyboard shortcuts
- Set API keys for both services
- 5 Languages: English 🇬🇧 · Thai 🇹🇭 · 日本語 🇯🇵 · 한국어 🇰🇷 · 中文 🇨🇳

---

## 📥 How to Install

### Prerequisites
1. [AutoHotkey v2](https://www.autohotkey.com/)
2. [Python 3.8+](https://www.python.org/) (for Smart Translator)

### Setup

```bash
# 1. Install Python dependency for translator
cd MultiTool/translator
pip install -r requirements.txt

# 2. Run the app
# Double-click MultiTool.ahk
```

---

## ⌨️ Default Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl+Shift+Space` | Open MultiTool Hub |
| `Ctrl+Shift+C` | Currency Converter (select number first) |
| `Ctrl+Shift+T` | Translate selected text (popup) |
| `Ctrl+Shift+R` | Translate & replace text in-place |
| `Ctrl+Shift+Y` | Copy last translation |

All shortcuts are customizable in **Settings → ⌨️ Hotkeys** tab.

---

## 🔑 API Key Setup

### Currency Converter — ExchangeRate-API
- Free Tier: 1,500 requests/month
- Sign up at [exchangerate-api.com](https://www.exchangerate-api.com/) → copy your API key
- Settings → 💱 Currency tab → paste key → Save

### Smart Translator — Gemini API
- Free Tier: generous limits
- Get a key at [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
- Settings → 🌐 Translator tab → paste key → Save

> **Note:** Bitcoin (BTC) rates are fetched from CoinGecko's public API — no key required.

---

## 📁 Project Structure

```
MultiTool/
├── MultiTool.ahk              # Main app (~900 lines)
├── config.ini                  # User settings (auto-created)
├── config.example.ini          # Example config
├── icon.ico                    # App icon
├── .gitignore
├── README.md
└── translator/                 # Python translator module
    ├── translator.py           # Gemini AI translation script
    ├── requirements.txt        # Python dependencies
    ├── .env                    # Gemini API key (auto-created)
    └── .env.example
```

---

## 🛡️ Security & Privacy

- **Clipboard**: Saved → copied → extracted → immediately restored
- **API Keys**: Stored locally in `config.ini` and `translator/.env` only
- **Currency API**: Only calls ExchangeRate-API + CoinGecko
- **Translation API**: Only calls Google Gemini API
- No analytics, no telemetry, no data collection

---

## 🛠️ Built With

- [AutoHotkey v2](https://www.autohotkey.com/) — Desktop automation & UI
- [Python](https://www.python.org/) — Translator backend
- [Gemini AI](https://ai.google.dev/) — Smart translation
- [ExchangeRate-API](https://www.exchangerate-api.com/) — Fiat currency rates
- [CoinGecko API](https://www.coingecko.com/) — Bitcoin price

---

## 📄 License

MIT License — free to use, modify, and distribute.
