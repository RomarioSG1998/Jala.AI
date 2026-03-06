import asyncio
import os
from typing import Any, Dict, List, Optional

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
        if not _token:
            print("[webhook] TELEGRAM_BOT_TOKEN ausente; nao foi possivel configurar webhook")
        return

    webhook_url = _resolve_webhook_url()
    if not webhook_url:
        print("[webhook] URL de webhook ausente (use TELEGRAM_WEBHOOK_URL ou RENDER_EXTERNAL_URL)")
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
            print(f"[webhook] Telegram webhook configurado: {webhook_url}")
            return
        print(f"[webhook] setWebhook falhou: {data}")
    except Exception as exc:
        print(f"[webhook] excecao ao configurar webhook: {exc}")
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
                    resp = requests.post(voice_url, data=data, files=files, timeout=40)
                    if resp.status_code >= 300:
                        print(f"[webhook] erro sendVoice status={resp.status_code} body={resp.text[:300]}")
                    continue
            resp = requests.post(url, json={"chat_id": int(chat_id), "text": cleaned}, timeout=20)
            if resp.status_code >= 300:
                print(f"[webhook] erro sendMessage status={resp.status_code} body={resp.text[:300]}")
        except Exception as exc:
            print(f"[webhook] excecao ao enviar mensagem para Telegram: {exc}")
            continue


def _download_telegram_file(file_id: str) -> Optional[bytes]:
    if not _token or not file_id:
        return None
    try:
        meta_resp = requests.get(
            f"https://api.telegram.org/bot{_token}/getFile",
            params={"file_id": file_id},
            timeout=20,
        )
        meta = meta_resp.json() if meta_resp.content else {}
        file_path = (((meta or {}).get("result") or {}).get("file_path") or "").strip()
        if not file_path:
            print(f"[webhook] getFile falhou: {meta}")
            return None
        file_resp = requests.get(f"https://api.telegram.org/file/bot{_token}/{file_path}", timeout=60)
        if file_resp.status_code >= 300:
            print(f"[webhook] download de arquivo falhou status={file_resp.status_code}")
            return None
        return file_resp.content
    except Exception as exc:
        print(f"[webhook] excecao ao baixar arquivo do Telegram: {exc}")
        return None


def _handle_audio_message(chat_id: str, message: Dict[str, Any]) -> List[str]:
    media = (message.get("voice") or message.get("audio") or {})
    file_id = str(media.get("file_id") or "").strip()
    mime_type = str(media.get("mime_type") or "audio/ogg").strip() or "audio/ogg"
    duration = int(media.get("duration") or 0)
    file_size = int(media.get("file_size") or 0)

    max_seconds = int(os.getenv("BOT_AUDIO_MAX_SECONDS", "60") or "60")
    max_bytes = int(os.getenv("BOT_AUDIO_MAX_BYTES", str(8 * 1024 * 1024)) or str(8 * 1024 * 1024))

    if max_seconds > 0 and duration > max_seconds:
        return [f"Audio muito longo ({duration}s). Envie ate {max_seconds}s para eu responder rapido."]

    if max_bytes > 0 and file_size > max_bytes:
        return ["Arquivo de audio muito grande. Envie um audio menor ou em texto."]

    audio_bytes = _download_telegram_file(file_id)
    if not audio_bytes:
        return ["Nao consegui baixar esse audio. Tente novamente."]

    transcript = _bot_instance.transcribe_audio(audio_bytes, mime_type=mime_type)
    if not transcript:
        return ["Nao consegui entender o audio. Pode tentar de novo ou mandar em texto?"]

    print(f"[webhook] audio transcrito chat={chat_id}: {transcript[:120]}")
    return asyncio.run(_bot_instance.handle_incoming_text(str(chat_id), transcript))


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
    has_audio = bool(message.get("voice") or message.get("audio"))

    if not chat_id:
        return jsonify({"ok": True, "ignored": True})

    if has_audio:
        responses = _handle_audio_message(str(chat_id), message)
    elif text is not None:
        responses = asyncio.run(_bot_instance.handle_incoming_text(str(chat_id), str(text)))
    else:
        return jsonify({"ok": True, "ignored": True})

    _send_messages(str(chat_id), responses)
    return jsonify({"ok": True, "sent": len(responses)})


# Configure webhook as soon as service boots; route call remains as backup.
_ensure_telegram_webhook()
