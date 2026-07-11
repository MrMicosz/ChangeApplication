import os
from pathlib import Path

import google.generativeai as genai

SCRIPT_DIR = Path(__file__).resolve().parent
TEMP_IN = SCRIPT_DIR / "temp_in.txt"
TEMP_OUT = SCRIPT_DIR / "temp_out.txt"


def load_api_key() -> str:
    key = os.environ.get("GEMINI_API_KEY")
    if key:
        return key

    env_file = SCRIPT_DIR / ".env"
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith("GEMINI_API_KEY="):
                return line.split("=", 1)[1].strip().strip('"').strip("'")

    raise SystemExit("Set GEMINI_API_KEY in .env or as an environment variable.")


api_key = load_api_key()

genai.configure(api_key=api_key)
model = genai.GenerativeModel("gemini-2.5-flash")


def main():
    try:
        text = TEMP_IN.read_text(encoding="utf-8").strip()
        if not text:
            return

        prompt = (
            "Translate the following text to Thai. "
            "If it is already in Thai, translate it to English. "
            "Output ONLY the translation without any quotes or explanations:\n\n"
            f"{text}"
        )
        response = model.generate_content(prompt)
        TEMP_OUT.write_text(response.text.strip(), encoding="utf-8")

    except Exception as e:
        TEMP_OUT.write_text(f"เกิดข้อผิดพลาด: {str(e)}", encoding="utf-8")


if __name__ == "__main__":
    main()
