#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ╔══════════════════════════════════════════════════════════════╗
; ║              🧰 MultiTool — All-in-One Toolkit              ║
; ║          Currency Converter + Smart Translator Hub           ║
; ╚══════════════════════════════════════════════════════════════╝

; ═══════════════════════════════════════════════════════════════
; 1. CONFIGURATION — Load settings from INI
; ═══════════════════════════════════════════════════════════════
iniFile := A_ScriptDir "\config.ini"
if !FileExist(iniFile) {
    IniWrite("EN", iniFile, "General", "Lang")
    IniWrite("", iniFile, "Currency", "APIKey")
    IniWrite("0", iniFile, "Currency", "AutoCopy")
    IniWrite("^+c", iniFile, "Currency", "Hotkey")
    IniWrite("", iniFile, "Translator", "GeminiKey")
    IniWrite("^+t", iniFile, "Translator", "HotkeyTranslate")
    IniWrite("^+r", iniFile, "Translator", "HotkeyReplace")
    IniWrite("^+y", iniFile, "Translator", "HotkeyCopyLast")
    IniWrite("^+space", iniFile, "Hub", "Hotkey")
}

global apiKey := IniRead(iniFile, "Currency", "APIKey", "")
global autoCopy := IniRead(iniFile, "Currency", "AutoCopy", "0")
global currencyHotkey := IniRead(iniFile, "Currency", "Hotkey", "^+c")

global geminiKey := IniRead(iniFile, "Translator", "GeminiKey", "")
global translateHotkey := IniRead(iniFile, "Translator", "HotkeyTranslate", "^+t")
global replaceHotkey := IniRead(iniFile, "Translator", "HotkeyReplace", "^+r")
global copyLastHotkey := IniRead(iniFile, "Translator", "HotkeyCopyLast", "^+y")

global hubHotkey := IniRead(iniFile, "Hub", "Hotkey", "^+space")
global lastAmount := ""

; ═══════════════════════════════════════════════════════════════
; 2. BTC RATE CACHE
; ═══════════════════════════════════════════════════════════════
global btcCache := Map("rate", 0.0, "timestamp", 0)
global btcCacheTTL := 180

; ═══════════════════════════════════════════════════════════════
; 3. TRANSLATOR STATE
; ═══════════════════════════════════════════════════════════════
global LastTranslation := ""
global ScriptDir := A_ScriptDir
global PythonCmd := DetectPython()
global gOverlay := 0
global gPopup := 0
global gEditCtrl := 0
global gHintCtrl := 0
global gCopyBtn := 0
global gIsLoading := false

; ═══════════════════════════════════════════════════════════════
; 4. LANGUAGE SYSTEM — 5 Languages
; ═══════════════════════════════════════════════════════════════
global langList := ["EN", "TH", "JA", "KO", "ZH"]
global langLabels := Map("EN", "EN", "TH", "ไทย", "JA", "日本語", "KO", "한국어", "ZH", "中文")
global langDisplayList := ["English", "ไทย", "日本語", "한국어", "中文"]
global currentLang := IniRead(iniFile, "General", "Lang", "EN")

validLang := false
for _, lang in langList {
    if (lang == currentLang)
        validLang := true
}
if (!validLang)
    global currentLang := "EN"

; ── All translatable strings ──
global strings := Map(
    ; --- Hub ---
    "hub_title_en",        "🧰 MultiTool Hub",
    "hub_title_th",        "🧰 ศูนย์เครื่องมือ",
    "hub_title_ja",        "🧰 マルチツール",
    "hub_title_ko",        "🧰 멀티 도구",
    "hub_title_zh",        "🧰 多功能工具",

    "hub_currency_en",     "💱  Currency Converter",
    "hub_currency_th",     "💱  แปลงสกุลเงิน",
    "hub_currency_ja",     "💱  通貨換算",
    "hub_currency_ko",     "💱  환율 변환",
    "hub_currency_zh",     "💱  货币转换",

    "hub_translator_en",   "🌐  Smart Translator",
    "hub_translator_th",   "🌐  แปลภาษาอัจฉริยะ",
    "hub_translator_ja",   "🌐  スマート翻訳",
    "hub_translator_ko",   "🌐  스마트 번역",
    "hub_translator_zh",   "🌐  智能翻译",

    "hub_settings_en",     "⚙️  Settings",
    "hub_settings_th",     "⚙️  ตั้งค่า",
    "hub_settings_ja",     "⚙️  設定",
    "hub_settings_ko",     "⚙️  설정",
    "hub_settings_zh",     "⚙️  设置",

    "hub_desc_en",         "Press a button or use keyboard shortcuts",
    "hub_desc_th",         "กดปุ่มหรือใช้คีย์ลัด",
    "hub_desc_ja",         "ボタンまたはショートカットを使用",
    "hub_desc_ko",         "버튼 또는 단축키 사용",
    "hub_desc_zh",         "按按钮或使用快捷键",

    "hub_tr_desc_en",      "Select text → Ctrl+Shift+T to translate",
    "hub_tr_desc_th",      "คลุมข้อความ → Ctrl+Shift+T เพื่อแปล",
    "hub_tr_desc_ja",      "テキスト選択 → Ctrl+Shift+T で翻訳",
    "hub_tr_desc_ko",      "텍스트 선택 → Ctrl+Shift+T 번역",
    "hub_tr_desc_zh",      "选择文字 → Ctrl+Shift+T 翻译",

    "hub_curr_desc_en",    "Select number → Ctrl+Shift+C to convert",
    "hub_curr_desc_th",    "คลุมเลข → Ctrl+Shift+C เพื่อแปลง",
    "hub_curr_desc_ja",    "数字選択 → Ctrl+Shift+C で換算",
    "hub_curr_desc_ko",    "숫자 선택 → Ctrl+Shift+C 변환",
    "hub_curr_desc_zh",    "选择数字 → Ctrl+Shift+C 转换",

    ; --- Currency converter strings ---
    "hint_th",          "คลุมเลขแล้วกดปุ่มคีย์ลัด",
    "hint_en",          "Select number & press hotkey",
    "hint_ja",          "数字を選択してホットキーを押す",
    "hint_ko",          "숫자를 선택하고 단축키",
    "hint_zh",          "选择数字后按快捷键",

    "converting_th",    "กำลังแปลง...",
    "converting_en",    "Converting...",
    "converting_ja",    "変換中...",
    "converting_ko",    "변환 중...",
    "converting_zh",    "转换中...",

    "no_key_th",        "กรุณาตั้ง API Key ก่อน!`n(กดปุ่ม Settings)",
    "no_key_en",        "Please set API Key first!`n(Click Settings)",
    "no_key_ja",        "API Keyを設定してください!`n(Settingsをクリック)",
    "no_key_ko",        "API Key를 먼저 설정하세요!`n(Settings 클릭)",
    "no_key_zh",        "请先设置 API Key!`n(点击 Settings)",

    "no_number_th",     "ไม่พบตัวเลขที่ถูกต้อง!",
    "no_number_en",     "No valid number found!",
    "no_number_ja",     "有効な数字が見つかりません!",
    "no_number_ko",     "유효한 숫자를 찾을 수 없습니다!",
    "no_number_zh",     "未找到有效数字!",

    "no_amount_th",     "ยังไม่มีตัวเลข`nคลุมเลขแล้วกดคีย์ลัดก่อน",
    "no_amount_en",     "No amount yet`nSelect number & press hotkey first",
    "no_amount_ja",     "金額がまだありません`n数字を選択してホットキー",
    "no_amount_ko",     "금액이 없습니다`n숫자 선택 후 단축키",
    "no_amount_zh",     "还没有金额`n选择数字后按快捷键",

    "net_error_th",     "เชื่อมต่อไม่ได้!`nตรวจสอบอินเทอร์เน็ต",
    "net_error_en",     "Connection failed!`nCheck your internet",
    "net_error_ja",     "接続に失敗しました!`nインターネットを確認",
    "net_error_ko",     "연결 실패!`n인터넷을 확인하세요",
    "net_error_zh",     "连接失败!`n请检查网络",

    "invalid_key_th",   "API Key ไม่ถูกต้อง!",
    "invalid_key_en",   "Invalid API Key!",
    "invalid_key_ja",   "API Keyが無効です!",
    "invalid_key_ko",   "API Key가 올바르지 않습니다!",
    "invalid_key_zh",   "API Key 无效!",

    "inactive_th",      "บัญชี API ยังไม่ได้ยืนยันอีเมล!",
    "inactive_en",      "API account not verified!",
    "inactive_ja",      "APIアカウント未認証!",
    "inactive_ko",      "API 계정이 인증되지 않았습니다!",
    "inactive_zh",      "API 账户未验证!",

    "quota_th",         "โควตา API หมดแล้ว!`n(รอเดือนหน้าหรือเปลี่ยน Key)",
    "quota_en",         "API quota reached!`n(Wait next month or change Key)",
    "quota_ja",         "APIクォータ上限!`n(来月まで待つかKeyを変更)",
    "quota_ko",         "API 할당량 초과!`n(다음 달까지 대기 또는 Key 변경)",
    "quota_zh",         "API 配额已用完!`n(等下个月或更换 Key)",

    "api_error_th",     "API Error — ลองใหม่อีกครั้ง",
    "api_error_en",     "API Error — try again",
    "api_error_ja",     "API エラー — 再試行してください",
    "api_error_ko",     "API 오류 — 다시 시도하세요",
    "api_error_zh",     "API 错误 — 请重试",

    "no_result_th",     "ไม่สามารถอ่านผลลัพธ์ได้",
    "no_result_en",     "Cannot read result",
    "no_result_ja",     "結果を読み取れません",
    "no_result_ko",     "결과를 읽을 수 없습니다",
    "no_result_zh",     "无法读取结果",

    "http_error_th",    "Network Error (HTTP ",
    "http_error_en",    "Network Error (HTTP ",
    "http_error_ja",    "ネットワークエラー (HTTP ",
    "http_error_ko",    "네트워크 오류 (HTTP ",
    "http_error_zh",    "网络错误 (HTTP ",

    "key_saved_th",     "บันทึกการตั้งค่าแล้ว! ✓",
    "key_saved_en",     "Settings saved! ✓",
    "key_saved_ja",     "設定保存完了! ✓",
    "key_saved_ko",     "설정 저장 완료! ✓",
    "key_saved_zh",     "设置已保存! ✓",

    "key_cleared_th",   "ลบ API Key แล้ว",
    "key_cleared_en",   "API Key cleared.",
    "key_cleared_ja",   "API Key 削除済み",
    "key_cleared_ko",   "API Key 삭제됨",
    "key_cleared_zh",   "API Key 已清除",

    "key_prompt_th",    "API Key จาก ExchangeRate-API:",
    "key_prompt_en",    "API Key from ExchangeRate-API:",
    "key_prompt_ja",    "ExchangeRate-APIのAPI Key:",
    "key_prompt_ko",    "ExchangeRate-API의 API Key:",
    "key_prompt_zh",    "ExchangeRate-API 的 API Key:",

    "hotkey_lbl_th",    "คีย์ลัด:",
    "hotkey_lbl_en",    "Hotkey:",
    "hotkey_lbl_ja",    "ホットキー:",
    "hotkey_lbl_ko",    "단축키:",
    "hotkey_lbl_zh",    "快捷键:",

    "autocopy_lbl_th",  " คัดลอกผลลัพธ์อัตโนมัติ",
    "autocopy_lbl_en",  " Enable Auto-Copy Result",
    "autocopy_lbl_ja",  " 自動コピー (Auto-Copy)",
    "autocopy_lbl_ko",  " 자동 복사 (Auto-Copy)",
    "autocopy_lbl_zh",  " 自动复制 (Auto-Copy)",

    "key_link_th",      '<a href="https://www.exchangerate-api.com/">สมัคร Key ฟรีที่นี่</a>',
    "key_link_en",      '<a href="https://www.exchangerate-api.com/">Get a free Key here</a>',
    "key_link_ja",      '<a href="https://www.exchangerate-api.com/">無料キーはこちら</a>',
    "key_link_ko",      '<a href="https://www.exchangerate-api.com/">무료 Key 받기</a>',
    "key_link_zh",      '<a href="https://www.exchangerate-api.com/">免费获取 Key</a>',

    ; --- Tray Menu ---
    "tray_hub_th",      "เปิดศูนย์เครื่องมือ",
    "tray_hub_en",      "Open MultiTool Hub",
    "tray_hub_ja",      "ハブを開く",
    "tray_hub_ko",      "허브 열기",
    "tray_hub_zh",      "打开工具中心",

    "tray_currency_th", "แปลงสกุลเงิน",
    "tray_currency_en", "Currency Converter",
    "tray_currency_ja", "通貨換算",
    "tray_currency_ko", "환율 변환",
    "tray_currency_zh", "货币转换",

    "tray_translator_th", "แปลภาษาอัจฉริยะ",
    "tray_translator_en", "Smart Translator",
    "tray_translator_ja", "スマート翻訳",
    "tray_translator_ko", "스마트 번역",
    "tray_translator_zh", "智能翻译",

    "tray_settings_th", "ตั้งค่าโปรแกรม",
    "tray_settings_en", "Settings",
    "tray_settings_ja", "設定",
    "tray_settings_ko", "설정",
    "tray_settings_zh", "设置",

    "tray_exit_th",     "ปิดโปรแกรม",
    "tray_exit_en",     "Exit",
    "tray_exit_ja",     "終了",
    "tray_exit_ko",     "종료",
    "tray_exit_zh",     "退出",

    "tray_tip_th",      "MultiTool",
    "tray_tip_en",      "MultiTool",
    "tray_tip_ja",      "MultiTool",
    "tray_tip_ko",      "MultiTool",
    "tray_tip_zh",      "MultiTool",

    "tray_ready_th",    "MultiTool พร้อมใช้งานแล้ว!",
    "tray_ready_en",    "MultiTool is ready!",
    "tray_ready_ja",    "MultiTool 準備完了!",
    "tray_ready_ko",    "MultiTool 준비 완료!",
    "tray_ready_zh",    "MultiTool 已就绪!",

    "ready_after_key_th", "พร้อมใช้งานแล้ว!",
    "ready_after_key_en", "Ready!",
    "ready_after_key_ja", "準備完了!",
    "ready_after_key_ko", "준비 완료!",
    "ready_after_key_zh", "已就绪!",

    ; --- Settings Window ---
    "settings_title_en",     "⚙️ MultiTool Settings",
    "settings_title_th",     "⚙️ ตั้งค่า MultiTool",
    "settings_title_ja",     "⚙️ MultiTool 設定",
    "settings_title_ko",     "⚙️ MultiTool 설정",
    "settings_title_zh",     "⚙️ MultiTool 设置",

    "tab_general_en",   "🌐 General",
    "tab_general_th",   "🌐 ทั่วไป",
    "tab_general_ja",   "🌐 一般",
    "tab_general_ko",   "🌐 일반",
    "tab_general_zh",   "🌐 常规",

    "tab_currency_en",  "💱 Currency",
    "tab_currency_th",  "💱 สกุลเงิน",
    "tab_currency_ja",  "💱 通貨",
    "tab_currency_ko",  "💱 환율",
    "tab_currency_zh",  "💱 货币",

    "tab_translator_en", "🌐 Translator",
    "tab_translator_th", "🌐 แปลภาษา",
    "tab_translator_ja", "🌐 翻訳",
    "tab_translator_ko", "🌐 번역",
    "tab_translator_zh", "🌐 翻译",

    "tab_hotkeys_en",   "⌨️ Hotkeys",
    "tab_hotkeys_th",   "⌨️ คีย์ลัด",
    "tab_hotkeys_ja",   "⌨️ ホットキー",
    "tab_hotkeys_ko",   "⌨️ 단축키",
    "tab_hotkeys_zh",   "⌨️ 快捷键",

    "lbl_language_en",  "Language:",
    "lbl_language_th",  "ภาษา:",
    "lbl_language_ja",  "言語:",
    "lbl_language_ko",  "언어:",
    "lbl_language_zh",  "语言:",

    "lbl_gemini_key_en",  "Gemini API Key:",
    "lbl_gemini_key_th",  "Gemini API Key:",
    "lbl_gemini_key_ja",  "Gemini API Key:",
    "lbl_gemini_key_ko",  "Gemini API Key:",
    "lbl_gemini_key_zh",  "Gemini API Key:",

    "gemini_link_th",     '<a href="https://aistudio.google.com/apikey">สร้าง Gemini Key ฟรีที่นี่</a>',
    "gemini_link_en",     '<a href="https://aistudio.google.com/apikey">Get a free Gemini Key here</a>',
    "gemini_link_ja",     '<a href="https://aistudio.google.com/apikey">Gemini Keyを無料で取得</a>',
    "gemini_link_ko",     '<a href="https://aistudio.google.com/apikey">무료 Gemini Key 받기</a>',
    "gemini_link_zh",     '<a href="https://aistudio.google.com/apikey">免费获取 Gemini Key</a>',

    "lbl_hk_currency_en", "Currency Converter:",
    "lbl_hk_currency_th", "แปลงสกุลเงิน:",
    "lbl_hk_currency_ja", "通貨換算:",
    "lbl_hk_currency_ko", "환율 변환:",
    "lbl_hk_currency_zh", "货币转换:",

    "lbl_hk_translate_en", "Translate (Popup):",
    "lbl_hk_translate_th", "แปลภาษา (Popup):",
    "lbl_hk_translate_ja", "翻訳 (ポップアップ):",
    "lbl_hk_translate_ko", "번역 (팝업):",
    "lbl_hk_translate_zh", "翻译 (弹窗):",

    "lbl_hk_replace_en",  "Translate & Replace:",
    "lbl_hk_replace_th",  "แปลแล้วแทนที่:",
    "lbl_hk_replace_ja",  "翻訳して置換:",
    "lbl_hk_replace_ko",  "번역 후 교체:",
    "lbl_hk_replace_zh",  "翻译并替换:",

    "lbl_hk_copylast_en", "Copy Last Translation:",
    "lbl_hk_copylast_th", "คัดลอกผลแปลล่าสุด:",
    "lbl_hk_copylast_ja", "最後の翻訳をコピー:",
    "lbl_hk_copylast_ko", "마지막 번역 복사:",
    "lbl_hk_copylast_zh", "复制上次翻译:",

    "lbl_hk_hub_en",      "Open Hub:",
    "lbl_hk_hub_th",      "เปิด Hub:",
    "lbl_hk_hub_ja",      "ハブを開く:",
    "lbl_hk_hub_ko",      "허브 열기:",
    "lbl_hk_hub_zh",      "打开工具中心:",

    "btn_save_en",      "💾  Save Settings",
    "btn_save_th",      "💾  บันทึกการตั้งค่า",
    "btn_save_ja",      "💾  設定を保存",
    "btn_save_ko",      "💾  설정 저장",
    "btn_save_zh",      "💾  保存设置",

    ; --- Translator UI strings ---
    "tr_no_text_th",    "ไม่พบข้อความที่เลือก",
    "tr_no_text_en",    "No text selected",
    "tr_no_text_ja",    "テキストが選択されていません",
    "tr_no_text_ko",    "선택된 텍스트 없음",
    "tr_no_text_zh",    "未选择文本",

    "tr_translating_th",  "กำลังแปล...",
    "tr_translating_en",  "Translating...",
    "tr_translating_ja",  "翻訳中...",
    "tr_translating_ko",  "번역 중...",
    "tr_translating_zh",  "翻译中...",

    "tr_result_th",     "ผลการแปล",
    "tr_result_en",     "Translation Result",
    "tr_result_ja",     "翻訳結果",
    "tr_result_ko",     "번역 결과",
    "tr_result_zh",     "翻译结果",

    "tr_error_th",      "เกิดข้อผิดพลาด",
    "tr_error_en",      "Error",
    "tr_error_ja",      "エラー",
    "tr_error_ko",      "오류",
    "tr_error_zh",      "错误",

    "tr_copied_th",     "คัดลอกผลแปลแล้ว ✓",
    "tr_copied_en",     "Translation copied ✓",
    "tr_copied_ja",     "翻訳コピー済み ✓",
    "tr_copied_ko",     "번역 복사 완료 ✓",
    "tr_copied_zh",     "翻译已复制 ✓",

    "tr_replaced_th",   "แทนที่ข้อความแล้ว ✓",
    "tr_replaced_en",   "Text replaced ✓",
    "tr_replaced_ja",   "テキスト置換済み ✓",
    "tr_replaced_ko",   "텍스트 교체 완료 ✓",
    "tr_replaced_zh",   "文本已替换 ✓",

    "tr_no_result_th",  "ยังไม่มีผลแปล — กดคีย์ลัดแปลก่อน",
    "tr_no_result_en",  "No translation yet — translate first",
    "tr_no_result_ja",  "翻訳結果なし — 先に翻訳してください",
    "tr_no_result_ko",  "번역 결과 없음 — 먼저 번역하세요",
    "tr_no_result_zh",  "暂无翻译 — 请先翻译",

    "tr_close_hint_th", "คลิกที่อื่นเพื่อปิด",
    "tr_close_hint_en", "Click outside to close",
    "tr_close_hint_ja", "外側をクリックして閉じる",
    "tr_close_hint_ko", "외부를 클릭하여 닫기",
    "tr_close_hint_zh", "点击外部关闭",

    "tr_copy_btn_th",   "คัดลอก",
    "tr_copy_btn_en",   "Copy",
    "tr_copy_btn_ja",   "コピー",
    "tr_copy_btn_ko",   "복사",
    "tr_copy_btn_zh",   "复制",

    "tr_no_gemini_th",  "กรุณาตั้ง Gemini API Key ก่อน!`n(ไปที่ Settings → Translator)",
    "tr_no_gemini_en",  "Please set Gemini API Key first!`n(Go to Settings → Translator)",
    "tr_no_gemini_ja",  "Gemini API Keyを設定してください!`n(Settings → Translator)",
    "tr_no_gemini_ko",  "Gemini API Key를 설정하세요!`n(Settings → Translator)",
    "tr_no_gemini_zh",  "请先设置 Gemini API Key!`n(Settings → Translator)",

    "tr_python_fail_th",  "Python ทำงานไม่สำเร็จ",
    "tr_python_fail_en",  "Python execution failed",
    "tr_python_fail_ja",  "Python実行失敗",
    "tr_python_fail_ko",  "Python 실행 실패",
    "tr_python_fail_zh",  "Python 执行失败",

    "tr_read_fail_th",  "อ่านผลแปลไม่ได้",
    "tr_read_fail_en",  "Cannot read translation result",
    "tr_read_fail_ja",  "翻訳結果を読み取れません",
    "tr_read_fail_ko",  "번역 결과를 읽을 수 없습니다",
    "tr_read_fail_zh",  "无法读取翻译结果",

    "tr_empty_th",      "ได้ผลลัพธ์ว่าง",
    "tr_empty_en",      "Empty result",
    "tr_empty_ja",      "空の結果",
    "tr_empty_ko",      "빈 결과",
    "tr_empty_zh",      "空结果"
)

GetText(key) {
    global strings, currentLang
    lang := StrLower(currentLang)
    k := key . "_" . lang
    if strings.Has(k)
        return strings[k]
    k := key . "_en"
    if strings.Has(k)
        return strings[k]
    return key
}

; ═══════════════════════════════════════════════════════════════
; 5. HOTKEY REGISTRATION — Each tool gets its own hotkeys
; ═══════════════════════════════════════════════════════════════
global registeredCurrencyHK := currencyHotkey
global registeredTranslateHK := translateHotkey
global registeredReplaceHK := replaceHotkey
global registeredCopyLastHK := copyLastHotkey
global registeredHubHK := hubHotkey

RegisterAllHotkeys() {
    global registeredCurrencyHK, registeredTranslateHK, registeredReplaceHK, registeredCopyLastHK, registeredHubHK
    global currencyHotkey, translateHotkey, replaceHotkey, copyLastHotkey, hubHotkey

    ; Currency hotkey
    Try {
        Hotkey(currencyHotkey, ConvertAction)
        registeredCurrencyHK := currencyHotkey
    } Catch {
        currencyHotkey := "^+c"
        Hotkey(currencyHotkey, ConvertAction)
        registeredCurrencyHK := currencyHotkey
    }

    ; Translate hotkey
    Try {
        Hotkey(translateHotkey, TranslateAndShowAction)
        registeredTranslateHK := translateHotkey
    } Catch {
        translateHotkey := "^+t"
        Hotkey(translateHotkey, TranslateAndShowAction)
        registeredTranslateHK := translateHotkey
    }

    ; Replace hotkey
    Try {
        Hotkey(replaceHotkey, TranslateAndReplaceAction)
        registeredReplaceHK := replaceHotkey
    } Catch {
        replaceHotkey := "^+r"
        Hotkey(replaceHotkey, TranslateAndReplaceAction)
        registeredReplaceHK := replaceHotkey
    }

    ; Copy last hotkey
    Try {
        Hotkey(copyLastHotkey, CopyLastTranslationAction)
        registeredCopyLastHK := copyLastHotkey
    } Catch {
        copyLastHotkey := "^+y"
        Hotkey(copyLastHotkey, CopyLastTranslationAction)
        registeredCopyLastHK := copyLastHotkey
    }

    ; Hub hotkey
    Try {
        Hotkey(hubHotkey, ShowHubAction)
        registeredHubHK := hubHotkey
    } Catch {
        hubHotkey := "^+space"
        Hotkey(hubHotkey, ShowHubAction)
        registeredHubHK := hubHotkey
    }
}

RegisterAllHotkeys()

; ═══════════════════════════════════════════════════════════════
; 6. SYSTEM TRAY
; ═══════════════════════════════════════════════════════════════
BuildTrayMenu()
BuildTrayMenu() {
    A_IconTip := "MultiTool`n💱 " . currencyHotkey . " Currency · 🌐 " . translateHotkey . " Translate"
    trayMenu := A_TrayMenu
    trayMenu.Delete()
    trayMenu.Add(GetText("tray_hub"), (*) => ShowHub())
    trayMenu.Add()
    trayMenu.Add(GetText("tray_currency"), (*) => ShowCurrencyGui())
    trayMenu.Add(GetText("tray_translator"), (*) => ShowLastTranslation())
    trayMenu.Add()
    trayMenu.Add(GetText("tray_settings"), (*) => ShowSettingsWindow())
    trayMenu.Add()
    trayMenu.Add(GetText("tray_exit"), (*) => ExitApp())
    trayMenu.Default := GetText("tray_hub")
}

; ═══════════════════════════════════════════════════════════════
; 7. HUB WINDOW — Main launcher (premium dark UI)
; ═══════════════════════════════════════════════════════════════
global HubGui := ""

ShowHubAction(HotkeyName) {
    ShowHub()
}

ShowHub(*) {
    global HubGui
    if (HubGui != "") {
        Try HubGui.Destroy()
    }

    HubGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +Owner", GetText("hub_title"))
    HubGui.BackColor := "0D0D1A"

    ; Dark title bar
    try {
        if !DllCall("dwmapi\DwmSetWindowAttribute", "ptr", HubGui.Hwnd, "int", 20, "int*", 1, "int", 4)
            DllCall("dwmapi\DwmSetWindowAttribute", "ptr", HubGui.Hwnd, "int", 19, "int*", 1, "int", 4)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", HubGui.Hwnd, "int", 34, "int*", 0x4F1A0D, "int", 4)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", HubGui.Hwnd, "int", 38, "int*", 2, "int", 4)
    }

    ; ── Header ──
    HubGui.SetFont("s20 bold c7C83F4", "Segoe UI")
    HubGui.Add("Text", "x25 y15 w340 h38 Center BackgroundTrans", "🧰 MultiTool")

    HubGui.SetFont("s9 norm c666680", "Segoe UI")
    HubGui.Add("Text", "x25 y55 w340 h20 Center BackgroundTrans", GetText("hub_desc"))

    ; ── Gradient separator ──
    HubGui.Add("Text", "x30 y82 w330 h2 Background1A1A3A")

    ; ═══ Currency Converter Card ═══
    HubGui.Add("Text", "x25 y95 w340 h75 Background12122A")
    
    HubGui.SetFont("s13 bold cFFFFFF", "Segoe UI")
    CurrBtn := HubGui.Add("Button", "x30 y100 w330 h40", GetText("hub_currency"))
    CurrBtn.OnEvent("Click", (*) => (HubGui.Destroy(), ShowCurrencyGui()))

    HubGui.SetFont("s8 norm c555570", "Segoe UI")
    HubGui.Add("Text", "x35 y145 w230 h16 BackgroundTrans", GetText("hub_curr_desc"))
    HubGui.Add("Text", "x285 y145 w75 h16 Right BackgroundTrans", currencyHotkey)

    ; ═══ Smart Translator Card ═══
    HubGui.Add("Text", "x25 y180 w340 h95 Background12122A")

    HubGui.SetFont("s13 bold cFFFFFF", "Segoe UI")
    TrBtn := HubGui.Add("Button", "x30 y185 w330 h40", GetText("hub_translator"))
    TrBtn.OnEvent("Click", (*) => (HubGui.Destroy(), ShowLastTranslation()))

    HubGui.SetFont("s8 norm c555570", "Segoe UI")
    HubGui.Add("Text", "x35 y230 w230 h16 BackgroundTrans", GetText("hub_tr_desc"))
    HubGui.Add("Text", "x285 y230 w75 h16 Right BackgroundTrans", translateHotkey)
    HubGui.Add("Text", "x35 y248 w160 h16 BackgroundTrans", "Replace: " . replaceHotkey . "  ·  Copy: " . copyLastHotkey)

    ; ── Separator ──
    HubGui.Add("Text", "x30 y285 w330 h2 Background1A1A3A")

    ; ═══ Settings Button ═══
    HubGui.SetFont("s10 norm cA0A0BB", "Segoe UI")
    SetBtn := HubGui.Add("Button", "x30 y297 w330 h36", GetText("hub_settings"))
    SetBtn.OnEvent("Click", (*) => (HubGui.Destroy(), ShowSettingsWindow()))

    ; ── Language selector ──
    HubGui.SetFont("s8 norm c555570", "Segoe UI")
    HubGui.Add("Text", "x30 y348 w20 h18 BackgroundTrans", "🌐")

    langChoose := 1
    for i, lang in langList {
        if (lang == currentLang)
            langChoose := i
    }
    HubGui.SetFont("s8 norm cBlack", "Segoe UI")
    HubLangDrop := HubGui.Add("DropDownList", "x52 y345 w80 h20 Choose" . langChoose . " -E0x200", langDisplayList)
    HubLangDrop.OnEvent("Change", OnHubChangeLang)

    ; ── Footer ──
    HubGui.SetFont("s7 norm c333348", "Segoe UI")
    HubGui.Add("Text", "x30 y373 w330 h15 Center BackgroundTrans", "MultiTool v1.0 — by MrMic")

    HubGui.OnEvent("Close", (*) => HubGui.Destroy())
    HubGui.Show("w390 h398")
}

OnHubChangeLang(*) {
    global currentLang, HubGui
    selectedIdx := HubGui["DropDownList1"].Value
    global currentLang := langList[selectedIdx]
    IniWrite(currentLang, iniFile, "General", "Lang")
    BuildTrayMenu()
    Try HubGui.Destroy()
    ShowHub()
}

; ═══════════════════════════════════════════════════════════════
; 8. CURRENCY CONVERTER — Full module (from Currency-Ex)
; ═══════════════════════════════════════════════════════════════
global currList := ["USD", "EUR", "JPY", "GBP", "THB", "KRW", "CNY", "₿ BTC"]

; --- Create Currency GUI (Dark Mode) ---
global CurrGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox", "💱 Currency Converter")
CurrGui.BackColor := "0D0D1A"

try {
    if !DllCall("dwmapi\DwmSetWindowAttribute", "ptr", CurrGui.Hwnd, "int", 20, "int*", 1, "int", 4)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", CurrGui.Hwnd, "int", 19, "int*", 1, "int", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", CurrGui.Hwnd, "int", 34, "int*", 0x4F1A0D, "int", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", CurrGui.Hwnd, "int", 38, "int*", 2, "int", 4)
}

; [Row 1] Logo + currency selectors
CurrGui.SetFont("s16 bold c7C83F4", "Segoe UI")
CurrGui.Add("Text", "x15 y12 w60 h30 BackgroundTrans", "💱")

CurrGui.SetFont("s10 norm cBlack", "Segoe UI")
FromCurrency := CurrGui.Add("DropDownList", "x80 y15 w65 Choose1 -E0x200", currList)

CurrGui.SetFont("s14 bold c7C83F4", "Segoe UI")
SwapBtn := CurrGui.Add("Button", "x150 y12 w35 h28", "⇄")
SwapBtn.OnEvent("Click", SwapCurrencies)

CurrGui.SetFont("s10 norm cBlack", "Segoe UI")
ToCurrency := CurrGui.Add("DropDownList", "x190 y15 w65 Choose5 -E0x200", currList)

; [Row 2] Language selector
CurrGui.SetFont("s9 norm c666680", "Segoe UI")
CurrGui.Add("Text", "x15 y46 w20 h20 BackgroundTrans", "🌐")

langChoose := 1
for i, lang in langList {
    if (lang == currentLang)
        langChoose := i
}
CurrGui.SetFont("s9 norm cBlack", "Segoe UI")
LangDrop := CurrGui.Add("DropDownList", "x38 y43 w80 Choose" . langChoose . " -E0x200", langDisplayList)
LangDrop.OnEvent("Change", OnChangeLang)

; [Center] Result display
CurrGui.SetFont("s14 bold cFFFFFF", "Segoe UI")
ResultText := CurrGui.Add("Text", "x15 y72 w275 h50 Center BackgroundTrans", GetText("hint"))

; [Rate per unit]
CurrGui.SetFont("s9 norm c666680", "Segoe UI")
RateText := CurrGui.Add("Text", "x15 y125 w275 h20 Center BackgroundTrans", "")

; [Mini Dashboard]
CurrGui.Add("Text", "x10 y148 w285 h40 Background12122A")
CurrGui.SetFont("s8 norm c7C83F4", "Segoe UI")
DashboardText := CurrGui.Add("Text", "x15 y153 w275 h30 Center BackgroundTrans", "")

; [Bottom buttons]
CurrGui.SetFont("s9 norm cFFFFFF", "Segoe UI")
RefreshBtn := CurrGui.Add("Button", "x15 y195 w30 h24", "🔄")
RefreshBtn.OnEvent("Click", RefreshConvert)

CurrGui.SetFont("s8 norm cA0A0BB", "Segoe UI")
BackBtn := CurrGui.Add("Button", "x55 y195 w60 h24", "← Hub")
BackBtn.OnEvent("Click", (*) => (CurrGui.Show("Hide"), ShowHub()))

CurrGui.SetFont("s8 norm cA0A0BB", "Segoe UI")
SettingsBtn := CurrGui.Add("Button", "x215 y195 w70 h24", GetText("tray_settings"))
SettingsBtn.OnEvent("Click", ShowSettingsWindow)

ShowCurrencyGui(*) {
    if (apiKey == "") {
        ResultText.Value := GetText("no_key")
    }
    CurrGui.Show("AutoSize")
}

SwapCurrencies(*) {
    fromIdx := FromCurrency.Value
    toIdx := ToCurrency.Value
    FromCurrency.Value := toIdx
    ToCurrency.Value := fromIdx
}

OnChangeLang(*) {
    global currentLang
    selectedIdx := LangDrop.Value
    global currentLang := langList[selectedIdx]
    IniWrite(currentLang, iniFile, "General", "Lang")

    if (lastAmount == "")
        ResultText.Value := GetText("hint")
    SettingsBtn.Text := GetText("tray_settings")
    BuildTrayMenu()
}

; --- Helpers ---
CleanNumber(rawText) {
    cleaned := RegExReplace(rawText, "[^\d\.]", "")
    if (cleaned != "" && RegExMatch(cleaned, "^\d+(\.\d+)?$"))
        return cleaned
    return ""
}

GetCurrCode(displayStr) {
    return RegExReplace(displayStr, "[^A-Za-z]", "")
}

FormatAmt(val, isBTC, isRate := false) {
    if isBTC {
        str := Format("{:0.8f}", val)
        str := RTrim(str, "0")
        return RTrim(str, ".")
    } else {
        return isRate ? Format("{:0.4f}", val) : Format("{:0.2f}", val)
    }
}

; --- API & Conversion ---
PerformConversion(amountToConvert) {
    if (apiKey == "") {
        ResultText.Value := GetText("no_key")
        ShowCurrencyGui()
        return
    }

    fromCurrCode := GetCurrCode(FromCurrency.Text)
    toCurrCode := GetCurrCode(ToCurrency.Text)

    ShowCurrencyGui()
    ResultText.Value := GetText("converting")
    RateText.Value := ""
    DashboardText.Value := ""

    btcToUsd := 0.0
    if (fromCurrCode == "BTC" || toCurrCode == "BTC") {
        now := A_TickCount // 1000
        if (btcCache["rate"] > 0 && (now - btcCache["timestamp"]) < btcCacheTTL) {
            btcToUsd := btcCache["rate"]
        } else {
            try {
                cgHttp := ComObject("WinHttp.WinHttpRequest.5.1")
                cgUrl := "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
                cgHttp.Open("GET", cgUrl, true)
                cgHttp.SetRequestHeader("User-Agent", "Mozilla/5.0")
                cgHttp.Send()
                cgHttp.WaitForResponse()
                cgResp := cgHttp.ResponseText
                if RegExMatch(cgResp, '"usd"\s*:\s*([\d\.]+)', &cgMatch) {
                    btcToUsd := cgMatch[1]
                    btcCache["rate"] := btcToUsd
                    btcCache["timestamp"] := now
                }
            } catch {
                ResultText.Value := GetText("net_error")
                return
            }
        }
    }

    try {
        apiBase := (fromCurrCode == "BTC") ? "USD" : fromCurrCode
        
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        url := "https://v6.exchangerate-api.com/v6/" . apiKey . "/latest/" . apiBase
        
        http.Open("GET", url, true)
        http.Send()
        http.WaitForResponse()

        status := http.Status
        response := http.ResponseText

        if (status != 200) {
            ResultText.Value := GetText("http_error") . status . ")"
            return
        }

        if InStr(response, '"conversion_rates"') {
            toRate := 1.0
            
            if (fromCurrCode == "BTC" && toCurrCode == "BTC") {
                toRate := 1.0
            } else if (fromCurrCode == "BTC") {
                usdToTarget := 1.0
                if (toCurrCode != "USD") {
                    if RegExMatch(response, '"' . toCurrCode . '"\s*:\s*([\d\.]+)', &rMatch)
                        usdToTarget := rMatch[1]
                    else {
                        ResultText.Value := GetText("no_result")
                        return
                    }
                }
                toRate := btcToUsd * usdToTarget
            } else if (toCurrCode == "BTC") {
                fromToUsd := 1.0
                if (fromCurrCode != "USD") {
                    if RegExMatch(response, '"USD"\s*:\s*([\d\.]+)', &rMatch)
                        fromToUsd := rMatch[1]
                    else {
                        ResultText.Value := GetText("no_result")
                        return
                    }
                }
                if (btcToUsd > 0)
                    toRate := fromToUsd / btcToUsd
                else
                    toRate := 0
            } else if (fromCurrCode != toCurrCode) {
                if RegExMatch(response, '"' . toCurrCode . '"\s*:\s*([\d\.]+)', &rMatch)
                    toRate := rMatch[1]
                else {
                    ResultText.Value := GetText("no_result")
                    return
                }
            }

            mainResult := amountToConvert * toRate
            isToBTC := (toCurrCode == "BTC")
            mainResultStr := FormatAmt(mainResult, isToBTC)
            ResultText.Value := amountToConvert . " " . fromCurrCode . "`n= " . mainResultStr . " " . toCurrCode
            
            unitRateStr := FormatAmt(toRate, isToBTC, true)
            RateText.Value := "1 " . fromCurrCode . " = " . unitRateStr . " " . toCurrCode

            ; Mini Dashboard
            dashCurrs := ["USD", "EUR", "GBP", "JPY", "CNY", "THB"]
            dashOut := ""
            count := 0
            for _, dCurr in dashCurrs {
                if (dCurr == fromCurrCode || dCurr == toCurrCode)
                    continue
                
                dRate := 1.0
                if (fromCurrCode == "BTC") {
                    usdToDCurr := 1.0
                    if (dCurr != "USD") {
                        if RegExMatch(response, '"' . dCurr . '"\s*:\s*([\d\.]+)', &drMatch)
                            usdToDCurr := drMatch[1]
                    }
                    dRate := btcToUsd * usdToDCurr
                } else {
                    if RegExMatch(response, '"' . dCurr . '"\s*:\s*([\d\.]+)', &drMatch)
                        dRate := drMatch[1]
                }
                
                dResult := amountToConvert * dRate
                dashOut .= dCurr . " " . FormatAmt(dResult, false) . "    "
                count++
                if (count == 3)
                    dashOut .= "`n"
            }
            DashboardText.Value := dashOut

            if (autoCopy == "1") {
                A_Clipboard := mainResultStr
            }

        } else if InStr(response, '"error-type"') {
            if InStr(response, "invalid-key")
                ResultText.Value := GetText("invalid_key")
            else if InStr(response, "inactive-account")
                ResultText.Value := GetText("inactive")
            else if InStr(response, "quota-reached")
                ResultText.Value := GetText("quota")
            else
                ResultText.Value := GetText("api_error")
        } else {
            ResultText.Value := GetText("no_result")
        }
    } catch as err {
        ResultText.Value := GetText("net_error")
    }
}

; --- Hotkey trigger for currency ---
ConvertAction(HotkeyName) {
    SavedClipboard := ClipboardAll()
    A_Clipboard := ""
    Send "^c"

    if !ClipWait(1) {
        A_Clipboard := SavedClipboard
        return
    }

    rawText := Trim(A_Clipboard)
    A_Clipboard := SavedClipboard

    amount := CleanNumber(rawText)
    global lastAmount := amount

    if (amount == "") {
        ToolTip(GetText("no_number"))
        SetTimer () => ToolTip(), -2000
        return
    }
    
    PerformConversion(amount)
}

RefreshConvert(*) {
    if (lastAmount == "") {
        ResultText.Value := GetText("no_amount")
        return
    }
    PerformConversion(lastAmount)
}

; ═══════════════════════════════════════════════════════════════
; 9. SMART TRANSLATOR — Full module (from Translate.ahk)
;    Uses Python + Gemini AI for intelligent translation
; ═══════════════════════════════════════════════════════════════

; --- Hotkey action wrappers ---
TranslateAndShowAction(HotkeyName) {
    TranslateAndShow()
}

TranslateAndReplaceAction(HotkeyName) {
    TranslateAndReplace()
}

CopyLastTranslationAction(HotkeyName) {
    CopyLastTranslation()
}

; --- Main translation functions ---
TranslateAndShow() {
    if (geminiKey == "") {
        ShowStatusToast(GetText("tr_no_gemini"))
        return
    }

    selectedText := GetSelectedText()
    if (selectedText = "") {
        ShowStatusToast(GetText("tr_no_text"))
        return
    }

    ShowTranslationPopup(, true)
    tr := DoTranslate(selectedText)
    if !tr["success"] {
        if tr.Has("isError") {
            ShowTranslationPopup(tr["error"], false, true)
        } else {
            CloseTranslationPopup()
            ShowStatusToast(tr["error"])
        }
        return
    }
    LastTranslation := tr["text"]
    ShowTranslationPopup(tr["text"])
}

TranslateAndReplace() {
    if (geminiKey == "") {
        ShowStatusToast(GetText("tr_no_gemini"))
        return
    }

    selectedText := GetSelectedText()
    if (selectedText = "") {
        ShowStatusToast(GetText("tr_no_text"))
        return
    }

    tr := DoTranslate(selectedText)
    if !tr["success"] {
        ShowStatusToast(tr["error"])
        return
    }
    LastTranslation := tr["text"]
    A_Clipboard := tr["text"]
    Sleep(80)
    Send("^v")
    ShowStatusToast(GetText("tr_replaced"))
}

CopyLastTranslation() {
    if LastTranslation = "" {
        ShowStatusToast(GetText("tr_no_result"))
        return
    }
    A_Clipboard := LastTranslation
    Sleep(50)
    ShowStatusToast(GetText("tr_copied"))
}

ShowLastTranslation() {
    if LastTranslation = "" {
        ShowStatusToast(GetText("tr_no_result"))
        return
    }
    ShowTranslationPopup(LastTranslation)
}

; --- Clipboard handling ---
GetSelectedText() {
    clipSaved := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(1) {
        A_Clipboard := clipSaved
        return ""
    }
    selectedText := A_Clipboard
    A_Clipboard := clipSaved
    return Trim(selectedText)
}

; --- Python-based Gemini translation ---
DoTranslate(selectedText) {
    ; Write .env file with current Gemini key for Python to read
    envFile := ScriptDir "\translator\.env"
    try FileDelete(envFile)
    FileAppend("GEMINI_API_KEY=" . geminiKey, envFile, "UTF-8")

    tempIn := ScriptDir "\translator\temp_in.txt"
    tempOut := ScriptDir "\translator\temp_out.txt"
    translator := ScriptDir "\translator\translator.py"

    try FileDelete(tempIn)
    FileAppend(selectedText, tempIn, "UTF-8")

    exitCode := RunWait(PythonCmd ' "' translator '"', ScriptDir "\translator", "Hide")
    if exitCode != 0 {
        return Map("success", false, "error", GetText("tr_python_fail") . " (exit " . exitCode . ")")
    }

    try
        translated := Trim(FileRead(tempOut, "UTF-8"))
    catch {
        return Map("success", false, "error", GetText("tr_read_fail"))
    }

    if translated = "" {
        return Map("success", false, "error", GetText("tr_empty"))
    }

    if InStr(translated, "เกิดข้อผิดพลาด:") {
        return Map("success", false, "error", translated, "isError", true)
    }

    return Map("success", true, "text", translated)
}

; --- Translation popup (with overlay + fade) ---
ShowTranslationPopup(text := "", loading := false, isError := false) {
    global gIsLoading

    wasLoading := gIsLoading
    gIsLoading := loading

    if !gPopup
        CreateTranslationPopup()

    if loading {
        gEditCtrl.Value := GetText("tr_translating")
        gPopup["title"].Text := "Smart Translator"
        gEditCtrl.Opt("+Disabled")
        gCopyBtn.Enabled := false
    } else {
        gEditCtrl.Value := text
        gEditCtrl.Opt("-Disabled")
        gPopup["title"].Text := isError ? GetText("tr_error") : GetText("tr_result")
        gCopyBtn.Enabled := !isError
    }

    ResizePopupContent(text, loading)
    PositionPopup()
    if !wasLoading || loading
        FadeInPopup()
}

CreateTranslationPopup() {
    global gOverlay, gPopup, gEditCtrl, gHintCtrl, gCopyBtn

    gOverlay := Gui("+AlwaysOnTop -Caption +ToolWindow")
    gOverlay.BackColor := "0D0D1A"
    
    overlayClick := gOverlay.Add("Text", "x0 y0 w" A_ScreenWidth " h" A_ScreenHeight " BackgroundTrans")
    overlayClick.OnEvent("Click", CloseTranslationPopup)
    
    gOverlay.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
    WinSetTransparent(55, gOverlay)

    gPopup := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    gPopup.BackColor := "13132A"
    gPopup.SetFont("s12", "Segoe UI")
    gPopup.OnEvent("Close", CloseTranslationPopup)
    gPopup.OnEvent("Escape", CloseTranslationPopup)

    ; Title bar
    gPopup.Add("Text", "vtitle x0 y0 w500 h40 Background1A1A3A cBBBBDD Center", GetText("tr_result"))
    gPopup["title"].SetFont("s11 Bold", "Segoe UI")

    closeBtn := gPopup.Add("Text", "x460 y8 w28 h24 Center BackgroundTrans c666680", "✕")
    closeBtn.SetFont("s12", "Segoe UI")
    closeBtn.OnEvent("Click", CloseTranslationPopup)

    ; Edit area
    gEditCtrl := gPopup.Add("Edit", "x16 y52 w468 +Multi +ReadOnly +Wrap -HScroll +VScroll Background0D0D1A cFFFFFF")
    gEditCtrl.SetFont("s15", "Segoe UI")

    ; Footer
    gHintCtrl := gPopup.Add("Text", "x16 y+10 w300 h20 BackgroundTrans c555570", GetText("tr_close_hint"))
    gHintCtrl.SetFont("s9", "Segoe UI")

    gCopyBtn := gPopup.Add("Button", "x384 y+0 w100 h30", GetText("tr_copy_btn"))
    gCopyBtn.SetFont("s10", "Segoe UI")
    gCopyBtn.OnEvent("Click", CopyFromPopup)
}

ResizePopupContent(text, loading := false) {
    global gPopup, gEditCtrl, gHintCtrl, gCopyBtn

    popupW := 500
    editW := 468
    minEditH := 80
    maxEditH := 320

    if loading {
        editH := 72
    } else {
        lineBreaks := StrSplit(text, "`n", "`r").Length
        charEstimate := Max(StrLen(text), 1)
        wrapLines := Ceil(charEstimate / 42)
        lineCount := Max(lineBreaks, wrapLines)
        editH := Min(maxEditH, Max(minEditH, lineCount * 26 + 16))
    }

    gEditCtrl.Move(, , editW, editH)

    footerY := 52 + editH + 12
    gHintCtrl.Move(16, footerY + 4)
    gCopyBtn.Move(384, footerY)

    popupH := footerY + 46
    gPopup.Show("w" popupW " h" popupH " Hide")
}

PositionPopup() {
    global gPopup

    gPopup.GetPos(, , &w, &h)
    MouseGetPos(&mx, &my)

    x := mx + 20
    y := my + 20

    if x + w > A_ScreenWidth - 16
        x := A_ScreenWidth - w - 16
    if y + h > A_ScreenHeight - 48
        y := A_ScreenHeight - h - 48
    if x < 16
        x := 16
    if y < 16
        y := 16

    gPopup.Show("x" x " y" y " NA")
}

FadeInPopup() {
    global gOverlay, gPopup

    WinSetTransparent(1, gPopup)
    WinSetTransparent(1, gOverlay)

    loop 10 {
        WinSetTransparent(Min(255, A_Index * 26), gPopup)
        WinSetTransparent(Min(55, A_Index * 6), gOverlay)
        Sleep(12)
    }
    WinSetTransparent(255, gPopup)
    WinSetTransparent(55, gOverlay)
}

CloseTranslationPopup(*) {
    global gOverlay, gPopup, gEditCtrl, gHintCtrl, gCopyBtn, gIsLoading

    if !gPopup
        return

    popupRef := gPopup
    overlayRef := gOverlay

    gPopup := 0
    gOverlay := 0
    gEditCtrl := 0
    gHintCtrl := 0
    gCopyBtn := 0
    gIsLoading := false

    loop 6 {
        alpha := 255 - (A_Index * 45)
        if alpha < 0
            alpha := 0
        try WinSetTransparent(alpha, popupRef)
        try WinSetTransparent(Max(0, 55 - A_Index * 10), overlayRef)
        Sleep(16)
    }

    try popupRef.Destroy()
    try overlayRef.Destroy()
}

CopyFromPopup(*) {
    global gEditCtrl, gIsLoading, LastTranslation

    if gIsLoading || !gEditCtrl
        return

    text := Trim(gEditCtrl.Value)
    if text = "" || text = GetText("tr_translating")
        return

    LastTranslation := text
    A_Clipboard := text
    Sleep(50)
    ShowStatusToast(GetText("tr_copied"))
}

ShowStatusToast(text, durationMs := 2200) {
    static hideTimer := 0

    if hideTimer {
        SetTimer(hideTimer, 0)
        hideTimer := 0
    }

    CoordMode("ToolTip", "Screen")
    MouseGetPos(&mx, &my)
    ToolTip(text, mx + 16, my + 20)
    hideTimer := (*) => ToolTip()
    SetTimer(hideTimer, -durationMs)
}

DetectPython() {
    for cmd in ["py", "python"] {
        try {
            exitCode := RunWait(A_ComSpec ' /c ' cmd ' -c "import sys; sys.exit(0)"', , "Hide")
            if exitCode = 0
                return cmd
        }
    }
    return "py"
}

; ═══════════════════════════════════════════════════════════════
; 10. SETTINGS HUB — Premium tabbed settings UI
; ═══════════════════════════════════════════════════════════════
ShowSettingsWindow(*) {
    SGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", GetText("settings_title"))
    SGui.BackColor := "0D0D1A"

    try {
        if !DllCall("dwmapi\DwmSetWindowAttribute", "ptr", SGui.Hwnd, "int", 20, "int*", 1, "int", 4)
            DllCall("dwmapi\DwmSetWindowAttribute", "ptr", SGui.Hwnd, "int", 19, "int*", 1, "int", 4)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", SGui.Hwnd, "int", 34, "int*", 0x4F1A0D, "int", 4)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", SGui.Hwnd, "int", 38, "int*", 2, "int", 4)
    }

    ; ── Header ──
    SGui.SetFont("s14 bold c7C83F4", "Segoe UI")
    SGui.Add("Text", "x20 y10 w380 h30 Center BackgroundTrans", GetText("settings_title"))

    SGui.Add("Text", "x20 y42 w380 h1 Background1A1A3A")

    ; ── Tab Control ──
    tabNames := [GetText("tab_general"), GetText("tab_currency"), GetText("tab_translator"), GetText("tab_hotkeys")]
    SGui.SetFont("s9 norm cFFFFFF", "Segoe UI")
    TabCtrl := SGui.Add("Tab3", "x10 y50 w400 h310", tabNames)

    ; ═══════════════════════════════════════
    ; Tab 1: General
    ; ═══════════════════════════════════════
    TabCtrl.UseTab(1)

    SGui.SetFont("s10 bold cBBBBDD", "Segoe UI")
    SGui.Add("Text", "x25 y90 BackgroundTrans", GetText("lbl_language"))

    langChoose := 1
    for i, lang in langList {
        if (lang == currentLang)
            langChoose := i
    }
    SGui.SetFont("s10 norm cBlack", "Segoe UI")
    SettingsLangDrop := SGui.Add("DropDownList", "x25 y115 w200 Choose" . langChoose . " -E0x200", langDisplayList)

    SGui.SetFont("s9 norm c666680", "Segoe UI")
    SGui.Add("Text", "x25 y155 w360 BackgroundTrans", "MultiTool v1.0")
    SGui.Add("Text", "x25 y175 w360 BackgroundTrans", "💱 Currency Converter + 🌐 Smart Translator")
    SGui.Add("Text", "x25 y195 w360 BackgroundTrans", "Built with AutoHotkey v2 + Python + Gemini AI")
    SGui.Add("Text", "x25 y225 w360 BackgroundTrans", "by MrMic 🧰")

    ; ═══════════════════════════════════════
    ; Tab 2: Currency
    ; ═══════════════════════════════════════
    TabCtrl.UseTab(2)

    SGui.SetFont("s10 bold cBBBBDD", "Segoe UI")
    SGui.Add("Text", "x25 y90 BackgroundTrans", GetText("key_prompt"))

    SGui.SetFont("s10 norm cBlack", "Segoe UI")
    InputKey := SGui.Add("Edit", "x25 y115 w360 -E0x200", apiKey)

    SGui.SetFont("s9 norm cFFFFFF", "Segoe UI")
    ChkAutoCopy := SGui.Add("Checkbox", "x25 y152 Checked" . autoCopy, GetText("autocopy_lbl"))

    SGui.SetFont("s9 cBBBBDD", "Segoe UI")
    SGui.Add("Link", "x25 y185", GetText("key_link"))

    ; ═══════════════════════════════════════
    ; Tab 3: Translator
    ; ═══════════════════════════════════════
    TabCtrl.UseTab(3)

    SGui.SetFont("s10 bold cBBBBDD", "Segoe UI")
    SGui.Add("Text", "x25 y90 BackgroundTrans", GetText("lbl_gemini_key"))

    SGui.SetFont("s10 norm cBlack", "Segoe UI")
    InputGeminiKey := SGui.Add("Edit", "x25 y115 w360 -E0x200", geminiKey)

    SGui.SetFont("s9 cBBBBDD", "Segoe UI")
    SGui.Add("Link", "x25 y150", GetText("gemini_link"))

    SGui.SetFont("s8 norm c666680", "Segoe UI")
    SGui.Add("Text", "x25 y180 w360 BackgroundTrans", "Powered by Gemini 2.5 Flash — AI Translation")
    SGui.Add("Text", "x25 y198 w360 BackgroundTrans", "Auto-detect: Thai → English, Others → Thai")
    SGui.Add("Text", "x25 y216 w360 BackgroundTrans", "Requires Python + google-generativeai package")

    ; ═══════════════════════════════════════
    ; Tab 4: Hotkeys
    ; ═══════════════════════════════════════
    TabCtrl.UseTab(4)

    yPos := 88
    rowH := 34

    SGui.SetFont("s9 bold cBBBBDD", "Segoe UI")
    SGui.Add("Text", "x25 y" . yPos . " BackgroundTrans", GetText("lbl_hk_currency"))
    SGui.SetFont("s9 norm cBlack", "Segoe UI")
    InputHkCurrency := SGui.Add("Edit", "x220 y" . (yPos - 2) . " w170 -E0x200", currencyHotkey)

    yPos += rowH
    SGui.SetFont("s9 bold cBBBBDD", "Segoe UI")
    SGui.Add("Text", "x25 y" . yPos . " BackgroundTrans", GetText("lbl_hk_translate"))
    SGui.SetFont("s9 norm cBlack", "Segoe UI")
    InputHkTranslate := SGui.Add("Edit", "x220 y" . (yPos - 2) . " w170 -E0x200", translateHotkey)

    yPos += rowH
    SGui.SetFont("s9 bold cBBBBDD", "Segoe UI")
    SGui.Add("Text", "x25 y" . yPos . " BackgroundTrans", GetText("lbl_hk_replace"))
    SGui.SetFont("s9 norm cBlack", "Segoe UI")
    InputHkReplace := SGui.Add("Edit", "x220 y" . (yPos - 2) . " w170 -E0x200", replaceHotkey)

    yPos += rowH
    SGui.SetFont("s9 bold cBBBBDD", "Segoe UI")
    SGui.Add("Text", "x25 y" . yPos . " BackgroundTrans", GetText("lbl_hk_copylast"))
    SGui.SetFont("s9 norm cBlack", "Segoe UI")
    InputHkCopyLast := SGui.Add("Edit", "x220 y" . (yPos - 2) . " w170 -E0x200", copyLastHotkey)

    yPos += rowH
    SGui.SetFont("s9 bold cBBBBDD", "Segoe UI")
    SGui.Add("Text", "x25 y" . yPos . " BackgroundTrans", GetText("lbl_hk_hub"))
    SGui.SetFont("s9 norm cBlack", "Segoe UI")
    InputHkHub := SGui.Add("Edit", "x220 y" . (yPos - 2) . " w170 -E0x200", hubHotkey)

    yPos += rowH + 8
    SGui.SetFont("s8 norm c555570", "Segoe UI")
    SGui.Add("Text", "x25 y" . yPos . " w360 BackgroundTrans", "^ = Ctrl   + = Shift   ! = Alt   # = Win")
    SGui.Add("Text", "x25 y" . (yPos + 16) . " w360 BackgroundTrans", "Example: ^+c = Ctrl+Shift+C")

    ; ═══════════════════════════════════════
    ; Bottom: Save button (outside tabs)
    ; ═══════════════════════════════════════
    TabCtrl.UseTab(0)

    SGui.SetFont("s11 bold cWhite", "Segoe UI")
    SaveSettingsBtn := SGui.Add("Button", "x60 y375 w300 h40", GetText("btn_save"))
    SaveSettingsBtn.OnEvent("Click", (btn, *) => SaveAllSettings(
        SettingsLangDrop,
        InputKey,
        ChkAutoCopy,
        InputGeminiKey,
        InputHkCurrency,
        InputHkTranslate,
        InputHkReplace,
        InputHkCopyLast,
        InputHkHub,
        SGui
    ))

    SGui.OnEvent("Close", (*) => SGui.Destroy())
    SGui.Show("w420 h430")
}

SaveAllSettings(LangDropCtrl, KeyCtrl, AutoCopyCtrl, GeminiKeyCtrl, HkCurrCtrl, HkTransCtrl, HkReplCtrl, HkCopyCtrl, HkHubCtrl, SettingsGui) {
    ; 1. Language
    global currentLang
    selectedIdx := LangDropCtrl.Value
    global currentLang := langList[selectedIdx]
    IniWrite(currentLang, iniFile, "General", "Lang")

    ; 2. Currency settings
    global apiKey := Trim(KeyCtrl.Value)
    global autoCopy := AutoCopyCtrl.Value
    IniWrite(apiKey, iniFile, "Currency", "APIKey")
    IniWrite(autoCopy, iniFile, "Currency", "AutoCopy")

    ; 3. Gemini Key
    global geminiKey := Trim(GeminiKeyCtrl.Value)
    IniWrite(geminiKey, iniFile, "Translator", "GeminiKey")

    ; 4. Hotkeys — unregister old, register new
    global registeredCurrencyHK, registeredTranslateHK, registeredReplaceHK, registeredCopyLastHK, registeredHubHK
    global currencyHotkey, translateHotkey, replaceHotkey, copyLastHotkey, hubHotkey

    newHkCurr := Trim(HkCurrCtrl.Value)
    newHkTrans := Trim(HkTransCtrl.Value)
    newHkRepl := Trim(HkReplCtrl.Value)
    newHkCopy := Trim(HkCopyCtrl.Value)
    newHkHub := Trim(HkHubCtrl.Value)

    if (newHkCurr == "") newHkCurr := "^+c"
    if (newHkTrans == "") newHkTrans := "^+t"
    if (newHkRepl == "") newHkRepl := "^+r"
    if (newHkCopy == "") newHkCopy := "^+y"
    if (newHkHub == "") newHkHub := "^+space"

    ; Currency hotkey
    if (newHkCurr != registeredCurrencyHK) {
        Try Hotkey(registeredCurrencyHK, "Off")
        Try {
            Hotkey(newHkCurr, ConvertAction, "On")
            registeredCurrencyHK := newHkCurr
        } Catch {
            newHkCurr := "^+c"
            Hotkey(newHkCurr, ConvertAction, "On")
            registeredCurrencyHK := newHkCurr
        }
    }
    currencyHotkey := newHkCurr
    IniWrite(currencyHotkey, iniFile, "Currency", "Hotkey")

    ; Translate hotkey
    if (newHkTrans != registeredTranslateHK) {
        Try Hotkey(registeredTranslateHK, "Off")
        Try {
            Hotkey(newHkTrans, TranslateAndShowAction, "On")
            registeredTranslateHK := newHkTrans
        } Catch {
            newHkTrans := "^+t"
            Hotkey(newHkTrans, TranslateAndShowAction, "On")
            registeredTranslateHK := newHkTrans
        }
    }
    translateHotkey := newHkTrans
    IniWrite(translateHotkey, iniFile, "Translator", "HotkeyTranslate")

    ; Replace hotkey
    if (newHkRepl != registeredReplaceHK) {
        Try Hotkey(registeredReplaceHK, "Off")
        Try {
            Hotkey(newHkRepl, TranslateAndReplaceAction, "On")
            registeredReplaceHK := newHkRepl
        } Catch {
            newHkRepl := "^+r"
            Hotkey(newHkRepl, TranslateAndReplaceAction, "On")
            registeredReplaceHK := newHkRepl
        }
    }
    replaceHotkey := newHkRepl
    IniWrite(replaceHotkey, iniFile, "Translator", "HotkeyReplace")

    ; Copy last hotkey
    if (newHkCopy != registeredCopyLastHK) {
        Try Hotkey(registeredCopyLastHK, "Off")
        Try {
            Hotkey(newHkCopy, CopyLastTranslationAction, "On")
            registeredCopyLastHK := newHkCopy
        } Catch {
            newHkCopy := "^+y"
            Hotkey(newHkCopy, CopyLastTranslationAction, "On")
            registeredCopyLastHK := newHkCopy
        }
    }
    copyLastHotkey := newHkCopy
    IniWrite(copyLastHotkey, iniFile, "Translator", "HotkeyCopyLast")

    ; Hub hotkey
    if (newHkHub != registeredHubHK) {
        Try Hotkey(registeredHubHK, "Off")
        Try {
            Hotkey(newHkHub, ShowHubAction, "On")
            registeredHubHK := newHkHub
        } Catch {
            newHkHub := "^+space"
            Hotkey(newHkHub, ShowHubAction, "On")
            registeredHubHK := newHkHub
        }
    }
    hubHotkey := newHkHub
    IniWrite(hubHotkey, iniFile, "Hub", "Hotkey")

    ; Update Currency GUI language
    langIdx := 1
    for i, lang in langList {
        if (lang == currentLang)
            langIdx := i
    }
    LangDrop.Value := langIdx

    if (lastAmount == "")
        ResultText.Value := GetText("hint")
    SettingsBtn.Text := GetText("tray_settings")
    BuildTrayMenu()

    ; Close settings & notify
    SettingsGui.Destroy()
    TrayTip(GetText("key_saved"), "MultiTool", 1)
    SetTimer () => TrayTip(), -3000
}

; ═══════════════════════════════════════════════════════════════
; 11. STARTUP — Smart behavior
; ═══════════════════════════════════════════════════════════════
if (apiKey == "" || geminiKey == "") {
    ShowHub()
} else {
    CurrGui.Show("Hide")
    TrayTip(GetText("tray_ready"), "MultiTool", 1)
    SetTimer () => TrayTip(), -4000
}
