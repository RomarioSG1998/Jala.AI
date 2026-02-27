import asyncio
import os

from flask import Flask, jsonify, request

from telegram_bot import StudySecretaryBot


app = Flask(__name__)
_bot_instance = StudySecretaryBot()
_cron_secret = os.getenv("CRON_SECRET", "").strip()


def _is_authorized() -> bool:
    if not _cron_secret:
        return True
    auth = (request.headers.get("authorization") or "").strip()
    return auth == f"Bearer {_cron_secret}"


@app.route("/", methods=["GET", "POST"])
def run_telegram_cycle():
    if not _is_authorized():
        return jsonify({"ok": False, "error": "unauthorized"}), 401

    try:
        asyncio.run(_bot_instance.run_scheduled_cycle())
        return jsonify({"ok": True})
    except Exception as exc:
        return jsonify({"ok": False, "error": str(exc)}), 500
