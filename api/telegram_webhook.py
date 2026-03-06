import asyncio
import os
from typing import Any, Dict, List

import requests
from flask import Flask, jsonify, request

from telegram_bot import StudySecretaryBot


app = Flask(__name__)
_bot_instance = StudySecretaryBot()
_token = os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
_secret = os.getenv("TELEGRAM_WEBHOOK_SECRET", "").strip()
_audio_only = str(os.getenv("BOT_REPLY_AUDIO_ONLY", "true")).strip().lower() in ("1", "true", "yes", "on")
_tts_engine = str(os.getenv("BOT_TTS_ENGINE", "edge")).strip().lower()
_tts_edge_timeout = int(str(os.getenv("BOT_TTS_EDGE_TIMEOUT_SEC", "12")).strip() or "12")
_webhook_ensured = False


def _resolve_webhook_url() -> str:
    manual = str(os.getenv("TELEGRAM_WEBHOOK_URL", "")).strip()
    if manual:
        return manual
    render_external = str(os.getenv("RENDER_EXTERNAL_URL", "")).strip()
    if render_external:
        return render_external.rstrip("/") + "/"
    return ""


def _ensure_telegram_webhook() -> None:
    global _webhook_ensured
    if _webhook_ensured or not _token:
        return

    webhook_url = _resolve_webhook_url()
    if not webhook_url:
        return

    api = f"https://api.telegram.org/bot{_token}/setWebhook"
    payload = {"url": webhook_url}
    if _secret:
        payload["secret_token"] = _secret
    try:
        resp = requests.post(api, data=payload, timeout=20)
        data = resp.json() if resp.content else {}
        if bool(data.get("ok")):
            _webhook_ensured = True
    except Exception:
        return


def _send_messages(chat_id: str, messages: List[str]) -> None:
    if not _token:
        return
    url = f"https://api.telegram.org/bot{_token}/sendMessage"
    voice_url = f"https://api.telegram.org/bot{_token}/sendVoice"
    for msg in messages:
        if not msg:
            continue
        cleaned = str(msg).replace("*", "").strip()
        if not cleaned:
            continue
        try:
            if _audio_only:
                audio = None
                if _tts_engine == "edge":
                    try:
                        audio = asyncio.run(
                            asyncio.wait_for(
                                _bot_instance.synthesize_speech_edge_ogg(cleaned),
                                timeout=max(4, _tts_edge_timeout),
                            )
                        )
                    except Exception:
                        audio = None
                if not audio:
                    audio = _bot_instance.synthesize_speech_ogg(cleaned)
                if audio:
                    files = {"voice": ("reply.ogg", audio, "audio/ogg")}
                    data = {"chat_id": int(chat_id)}
                    requests.post(voice_url, data=data, files=files, timeout=40)
                    continue
            requests.post(url, json={"chat_id": int(chat_id), "text": cleaned}, timeout=20)
        except Exception:
            continue


@app.route("/", methods=["POST", "GET"])
def telegram_webhook():
    _ensure_telegram_webhook()

    if request.method == "GET":
        return jsonify({"ok": True, "service": "telegram_webhook"})

    if _secret:
        received = request.headers.get("x-telegram-bot-api-secret-token", "")
        if received != _secret:
            return jsonify({"ok": False, "error": "unauthorized"}), 401

    payload: Dict[str, Any] = request.get_json(silent=True) or {}
    message = payload.get("message") or payload.get("edited_message") or {}
    chat = message.get("chat") or {}
    text = message.get("text")
    chat_id = chat.get("id")

    if not chat_id or text is None:
        return jsonify({"ok": True, "ignored": True})

    responses = asyncio.run(_bot_instance.handle_incoming_text(str(chat_id), str(text)))
    _send_messages(str(chat_id), responses)
    return jsonify({"ok": True, "sent": len(responses)})
