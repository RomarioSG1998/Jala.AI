#!/usr/bin/env python3
import asyncio
import base64
import io
import os
import re
import subprocess
import tempfile
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from typing import Dict, List, Optional, Tuple
from urllib.parse import urlparse
from zoneinfo import ZoneInfo

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from dotenv import load_dotenv
import requests
from supabase import Client, create_client
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes, MessageHandler, filters


load_dotenv()

def env_str(name: str, default: str = "") -> str:
    value = str(os.getenv(name, default) or "").strip()
    if len(value) >= 2 and ((value[0] == '"' and value[-1] == '"') or (value[0] == "'" and value[-1] == "'")):
        value = value[1:-1].strip()
    return value


def env_int(name: str, default: int) -> int:
    try:
        return int(env_str(name, str(default)))
    except Exception:
        return default


def is_valid_http_url(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme in ("http", "https") and bool(parsed.netloc)


def normalize_supabase_url(raw: str) -> str:
    value = env_str(raw, "") if raw in os.environ else str(raw or "").strip()
    if not value:
        return ""
    if not value.startswith(("http://", "https://")):
        value = f"https://{value}"
    return value.rstrip("/")


TELEGRAM_BOT_TOKEN = env_str("TELEGRAM_BOT_TOKEN")
SUPABASE_URL = normalize_supabase_url(env_str("SUPABASE_URL"))
SUPABASE_KEY = env_str("SUPABASE_KEY")
BOT_DEFAULT_USER_ID = env_int("BOT_DEFAULT_USER_ID", 1)
BOT_DEFAULT_TIMEZONE = env_str("BOT_DEFAULT_TIMEZONE", "America/Sao_Paulo")
BOT_POLL_SECONDS = env_int("BOT_POLL_SECONDS", 60)
BOT_PROACTIVE_ENABLED = env_str("BOT_PROACTIVE_ENABLED", "false").lower() in ("1", "true", "yes", "on")
BOT_AI_ENABLED = env_str("BOT_AI_ENABLED", env_str("OT_AI_ENABLED", "true")).lower() in ("1", "true", "yes", "on")
BOT_AUDIO_STT_PROVIDER = env_str("BOT_AUDIO_STT_PROVIDER", "local").lower()
BOT_AUDIO_MAX_SECONDS = env_int("BOT_AUDIO_MAX_SECONDS", 60)
BOT_AUDIO_MAX_BYTES = env_int("BOT_AUDIO_MAX_BYTES", 8 * 1024 * 1024)
WHISPER_MODEL_SIZE = env_str("WHISPER_MODEL_SIZE", "tiny")
WHISPER_COMPUTE_TYPE = env_str("WHISPER_COMPUTE_TYPE", "int8")
BOT_DIRECT_GEMINI_MODE = env_str("BOT_DIRECT_GEMINI_MODE", "true").lower() in ("1", "true", "yes", "on")
BOT_REPLY_AUDIO_ONLY = env_str("BOT_REPLY_AUDIO_ONLY", "true").lower() in ("1", "true", "yes", "on")
BOT_TTS_ENGINE = env_str("BOT_TTS_ENGINE", "edge").lower()
BOT_TTS_MAX_CHARS = env_int("BOT_TTS_MAX_CHARS", 0)
BOT_TTS_EDGE_TIMEOUT_SEC = env_int("BOT_TTS_EDGE_TIMEOUT_SEC", 12)
GEMINI_MODELS = [
    m.strip()
    for m in env_str(
        "GEMINI_MODELS",
        "gemini-flash-latest,gemini-2.5-flash,gemini-2.5-pro,gemini-2.0-flash,gemini-2.0-flash-001,gemini-2.0-flash-exp-image-generation",
    ).split(",")
    if m.strip()
]


def normalize_text(value: Optional[str]) -> str:
    return str(value or "").strip().lower()


def is_greeting_text(text: str) -> bool:
    t = normalize_text(text)
    if not t:
        return False
    greetings = {
        "oi", "ola", "olá", "e ai", "e aí", "hey", "hello", "hi",
        "bom dia", "boa tarde", "boa noite", "tudo bem", "blz", "beleza",
    }
    if t in greetings:
        return True
    # short casual messages only
    return len(t.split()) <= 3 and any(g in t for g in ("oi", "ola", "olá", "hi", "hey"))


def is_planning_request(text: str) -> bool:
    t = normalize_text(text)
    if not t:
        return False
    keywords = [
        "plano", "planeja", "planejamento", "prioridade", "priorizar",
        "hoje", "semana", "prazo", "venc", "tarefa", "atividade",
        "o que fazer", "organiza", "organizar", "agenda", "cronograma",
    ]
    return any(k in t for k in keywords)


def get_task_weight(task: dict) -> float:
    for key in ("nota_maxima", "points_possible", "peso", "pontuacao"):
        value = task.get(key)
        if value is None:
            continue
        try:
            return float(value)
        except Exception:
            continue
    return 0.0


def canonical_task_name(name: Optional[str]) -> str:
    raw = normalize_text(name)
    # Remove prefixos comuns que geram duplicidade visual no Canvas.
    raw = re.sub(r"^(tarefa|atividade)\s+", "", raw)
    raw = re.sub(r"\s+", " ", raw).strip()
    return raw


def parse_date_only(value: Optional[str]) -> Optional[date]:
    if not value:
        return None
    raw = str(value).strip()
    if not raw:
        return None
    try:
        if len(raw) >= 10:
            return datetime.strptime(raw[:10], "%Y-%m-%d").date()
    except Exception:
        return None
    return None


def parse_time_only(value: Optional[str], fallback: time) -> time:
    raw = str(value or "").strip()
    if not raw:
        return fallback
    for fmt in ("%H:%M:%S", "%H:%M"):
        try:
            return datetime.strptime(raw, fmt).time()
        except ValueError:
            continue
    return fallback


def is_done_task(task: dict) -> bool:
    """Interpreta status vindo da sincronizacao Canvas->DB.

    Regras principais:
    - data_entrega preenchida => concluida
    - situacao iniciando com "nota:" => concluida
    - termos positivos (concluida/corrigida/finalizada/avaliada/entregue)
      desde que nao tenha marcador negativo de "nao entregue"
    """
    status = normalize_text(task.get("situacao"))

    submitted_at = str(task.get("data_entrega") or "").strip()
    if submitted_at:
        return True

    if status.startswith("nota:"):
        return True

    negative_markers = ("nao entregue", "não entregue", "sem entrega")
    if any(marker in status for marker in negative_markers):
        return False

    positive_markers = ("conclu", "corrigida", "finalizada", "avaliada", "entregue")
    return any(marker in status for marker in positive_markers)


def task_status_flags(task: dict) -> Dict[str, bool]:
    """Mapeia uma task Canvas em flags usadas pelo bot."""
    status = normalize_text(task.get("situacao"))
    done = is_done_task(task)

    in_progress = any(k in status for k in ("andamento", "em andamento", "em progresso"))
    pending = any(k in status for k in ("pendente", "nao entregue", "não entregue", "atrasada"))
    overdue_hint = any(k in status for k in ("atrasada", "vencida", "fora do prazo"))

    return {
        "done": done,
        "in_progress": in_progress and not done,
        "pending": pending and not done,
        "overdue_hint": overdue_hint and not done,
    }


def is_disciplina_in_study_period(disciplina: dict, ref_date: date, require_valid_dates: bool = False) -> bool:
    inicio = parse_date_only(disciplina.get("date_inicio"))
    fim = parse_date_only(disciplina.get("date_fim"))
    if require_valid_dates and (inicio is None or fim is None):
        return False
    if inicio and ref_date < inicio:
        return False
    if fim and ref_date > fim:
        return False
    return True


def is_disciplina_active_for_alerts(disciplina: Optional[dict], ref_date: date) -> bool:
    if not disciplina:
        return False
    status = normalize_text(disciplina.get("situation"))
    tipo = normalize_text(disciplina.get("tipo_disciplina"))
    if status != "estudando":
        return False
    if tipo and tipo != "normal":
        return False
    return is_disciplina_in_study_period(disciplina, ref_date, require_valid_dates=True)


@dataclass
class DashboardSummary:
    overdue: List[dict]
    due_today: List[dict]
    due_week: List[dict]
    in_progress: List[dict]
    pending: List[dict]


class StudySecretaryBot:
    def __init__(self) -> None:
        if not TELEGRAM_BOT_TOKEN:
            raise RuntimeError("TELEGRAM_BOT_TOKEN not configured in .env")
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise RuntimeError("SUPABASE_URL/SUPABASE_KEY not configured in .env")
        if not is_valid_http_url(SUPABASE_URL):
            raise RuntimeError(
                f"SUPABASE_URL invalid: {SUPABASE_URL!r}. Expected format: https://<project-ref>.supabase.co"
            )

        self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        self.application: Application = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
        self.scheduler = AsyncIOScheduler()
        self._schema_missing_warned = False
        self._gemini_keys: List[str] = self.load_gemini_keys()
        self._preferred_model: Optional[str] = GEMINI_MODELS[0] if GEMINI_MODELS else None
        self._available_models_cache: List[str] = []
        self._available_models_cache_until: Optional[datetime] = None
        self._last_priority_by_chat: Dict[str, List[dict]] = {}
        self._last_disciplinas_by_chat: Dict[str, Dict[int, dict]] = {}
        self._user_name_cache: Dict[int, str] = {}
        self._dialog_history_by_chat: Dict[str, List[str]] = {}
        self._whisper_model = None

        self.application.add_handler(CommandHandler("start", self.cmd_start))
        self.application.add_handler(CommandHandler("help", self.cmd_help))
        self.application.add_handler(CommandHandler("hoje", self.cmd_hoje))
        self.application.add_handler(CommandHandler("semana", self.cmd_semana))
        self.application.add_handler(CommandHandler("urgentes", self.cmd_urgentes))
        self.application.add_handler(CommandHandler("disciplinas", self.cmd_disciplinas))
        self.application.add_handler(CommandHandler("agenda", self.cmd_agenda))
        self.application.add_handler(CommandHandler("plano", self.cmd_plano))
        self.application.add_handler(CommandHandler("modelo", self.cmd_modelo))
        self.application.add_handler(CommandHandler("usuario", self.cmd_usuario))
        self.application.add_handler(CommandHandler("config", self.cmd_config))
        self.application.add_handler(CommandHandler("horario", self.cmd_horario))
        self.application.add_handler(MessageHandler(filters.VOICE | filters.AUDIO, self.on_audio_message))
        self.application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, self.on_free_text))

    def load_gemini_keys(self) -> List[str]:
        keys: List[str] = []
        try:
            resp = self.supabase.table("variaveis_ambiente").select("*").limit(1).maybe_single().execute()
            row = resp.data or {}
            for key_name, value in row.items():
                if key_name.startswith("geminiApiKey_") and value:
                    val = str(value).strip()
                    if val and val not in keys:
                        keys.append(val)
        except Exception:
            # Keep silent: AI is optional.
            pass
        return keys

    def load_available_gemini_models(self) -> List[str]:
        now = datetime.utcnow()
        if self._available_models_cache and self._available_models_cache_until and now < self._available_models_cache_until:
            return list(self._available_models_cache)

        if not self._gemini_keys:
            return list(GEMINI_MODELS)

        for key in self._gemini_keys:
            try:
                url = f"https://generativelanguage.googleapis.com/v1beta/models?key={key}"
                resp = requests.get(url, timeout=15)
                if resp.status_code >= 400:
                    continue
                data = resp.json() or {}
                rows = data.get("models") or []
                names: List[str] = []
                for row in rows:
                    methods = row.get("supportedGenerationMethods") or []
                    if "generateContent" not in methods:
                        continue
                    name = str(row.get("name") or "")
                    # API returns "models/<model-name>"
                    if name.startswith("models/"):
                        name = name.split("/", 1)[1]
                    if not name.startswith("gemini"):
                        continue
                    if name not in names:
                        names.append(name)
                if names:
                    self._available_models_cache = names
                    self._available_models_cache_until = now + timedelta(minutes=10)
                    return names
            except Exception:
                continue

        # Fallback list from env if model listing is unavailable.
        return list(GEMINI_MODELS)

    def get_model_order(self) -> List[str]:
        model_order = self.load_available_gemini_models()
        if not model_order:
            model_order = list(GEMINI_MODELS)
        if self._preferred_model and self._preferred_model in model_order:
            model_order.remove(self._preferred_model)
            model_order.insert(0, self._preferred_model)
        return model_order

    def probe_first_working_model(self) -> Tuple[Optional[str], str]:
        if not self._gemini_keys:
            return None, "Nenhuma chave Gemini encontrada em variaveis_ambiente."

        endpoint_tpl = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
        model_order = self.get_model_order()
        for model in model_order:
            for key in self._gemini_keys:
                try:
                    resp = requests.post(
                        endpoint_tpl.format(model=model, key=key),
                        json={
                            "contents": [{"role": "user", "parts": [{"text": "Responda apenas OK"}]}],
                            "generationConfig": {"temperature": 0.0, "maxOutputTokens": 20},
                        },
                        timeout=20,
                    )
                    if resp.status_code >= 400:
                        continue
                    data = resp.json() or {}
                    candidates = data.get("candidates") or []
                    parts = (((candidates[0] if candidates else {}).get("content") or {}).get("parts") or [])
                    txt = "\n".join(str(p.get("text", "")) for p in parts if p.get("text")).strip()
                    if txt:
                        self._preferred_model = model
                        return model, f"Modelo ativo: {model}"
                except Exception:
                    continue
        return None, "Nenhum modelo respondeu com sucesso agora (erro/quota indisponível)."

    def get_config_for_chat(self, chat_id: str) -> dict:
        try:
            resp = (
                self.supabase.table("bot_config")
                .select("*")
                .eq("telegram_chat_id", chat_id)
                .limit(1)
                .execute()
            )
            rows = resp.data or []
            if rows:
                return rows[0]
        except Exception as exc:
            if self.is_schema_missing_error(exc):
                self.warn_schema_missing_once(exc)
                return self.default_config(chat_id)
            raise

        payload = self.default_config(chat_id)
        self.supabase.table("bot_config").upsert(payload, on_conflict="telegram_chat_id").execute()
        return payload

    def update_chat_config(self, chat_id: str, updates: dict) -> dict:
        payload = {"telegram_chat_id": chat_id, **updates}
        self.supabase.table("bot_config").upsert(payload, on_conflict="telegram_chat_id").execute()
        return self.get_config_for_chat(chat_id)

    def user_exists(self, user_id: int) -> bool:
        try:
            resp = (
                self.supabase.table("users")
                .select("id")
                .eq("id", user_id)
                .limit(1)
                .execute()
            )
            return bool(resp.data)
        except Exception:
            return False

    def default_config(self, chat_id: str) -> dict:
        return {
            "id_usuario": BOT_DEFAULT_USER_ID,
            "telegram_chat_id": chat_id,
            "timezone": BOT_DEFAULT_TIMEZONE,
            "daily_enabled": True,
            "weekly_enabled": True,
            "urgent_enabled": True,
            "daily_time": "07:30:00",
            "weekly_day": 6,
            "weekly_time": "18:00:00",
            "urgency_hours": 6,
        }

    @staticmethod
    def is_schema_missing_error(exc: Exception) -> bool:
        text = str(exc).lower()
        return (
            "relation \"public.bot_config\" does not exist" in text
            or "relation \"public.bot_notifications_log\" does not exist" in text
            or "code': '42p01'" in text
        )

    def warn_schema_missing_once(self, exc: Exception) -> None:
        if self._schema_missing_warned:
            return
        self._schema_missing_warned = True
        print("[bot] Missing DB schema for telegram bot.")
        print("[bot] Run once in Supabase SQL Editor: sql/telegram_bot_schema.sql")
        print(f"[bot] Detail: {exc}")

    def fetch_tasks_for_user(self, user_id: int) -> List[dict]:
        resp = (
            self.supabase.table("tasks")
            .select("*")
            .eq("id_usuario", user_id)
            .execute()
        )
        return resp.data or []

    def get_user_name(self, user_id: int) -> str:
        if user_id in self._user_name_cache:
            return self._user_name_cache[user_id]
        try:
            resp = (
                self.supabase.table("users")
                .select("id, name")
                .eq("id", user_id)
                .limit(1)
                .maybe_single()
                .execute()
            )
            row = resp.data or {}
            name = str(row.get("name") or "").strip()
            if name:
                self._user_name_cache[user_id] = name
                return name
        except Exception:
            pass
        return "você"

    def fetch_disciplinas_map(self, disciplina_ids: List[int]) -> Dict[int, dict]:
        if not disciplina_ids:
            return {}
        resp = (
            self.supabase.table("disciplina")
            .select("id, nome, situation, tipo_disciplina, date_inicio, date_fim, canvas_sync")
            .in_("id", disciplina_ids)
            .execute()
        )
        rows = resp.data or []
        out: Dict[int, dict] = {}
        for row in rows:
            try:
                out[int(row["id"])] = row
            except Exception:
                continue
        return out

    def build_summary(
        self,
        user_id: int,
        now: datetime,
        strict_active_disciplines: bool = False,
    ) -> Tuple[DashboardSummary, Dict[int, dict]]:
        today = now.date()
        end_week = today + timedelta(days=7)

        tasks = self.fetch_tasks_for_user(user_id)
        disciplina_ids = sorted({int(t["id_disciplina"]) for t in tasks if t.get("id_disciplina") is not None})
        disciplinas_map = self.fetch_disciplinas_map(disciplina_ids)

        overdue: List[dict] = []
        due_today: List[dict] = []
        due_week: List[dict] = []
        in_progress: List[dict] = []
        pending: List[dict] = []

        for task in tasks:
            flags = task_status_flags(task)
            if flags["done"]:
                continue

            disc_id = task.get("id_disciplina")
            try:
                disc_id_int = int(disc_id)
            except Exception:
                disc_id_int = None
            disciplina = disciplinas_map.get(disc_id_int) if disc_id_int is not None else None

            # For conversational context, include open Canvas tasks even if discipline
            # status/date is stale. Keep strict mode for proactive alerting.
            if strict_active_disciplines and not is_disciplina_active_for_alerts(disciplina, today):
                continue
            if not strict_active_disciplines:
                from_canvas = bool(task.get("canvas_id")) or bool(str(task.get("link_canvas") or "").strip())
                disc_canvas_sync = bool((disciplina or {}).get("canvas_sync"))
                if not (from_canvas or disc_canvas_sync):
                    continue

            due = parse_date_only(task.get("data_fim"))
            if flags["in_progress"]:
                in_progress.append(task)
            if flags["pending"]:
                pending.append(task)

            # Sem prazo mapeado: nao classifica em vencida/hoje/semana.
            if due is None:
                continue
            if due < today or (flags["overdue_hint"] and due <= today):
                overdue.append(task)
            elif due == today:
                due_today.append(task)
            elif today < due <= end_week:
                due_week.append(task)

        def sort_by_due(rows: List[dict]) -> List[dict]:
            return sorted(rows, key=lambda r: parse_date_only(r.get("data_fim")) or date.max)

        return (
            DashboardSummary(
                overdue=sort_by_due(overdue),
                due_today=sort_by_due(due_today),
                due_week=sort_by_due(due_week),
                in_progress=sort_by_due(in_progress),
                pending=sort_by_due(pending),
            ),
            disciplinas_map,
        )

    @staticmethod
    def build_today_priority_list(summary: DashboardSummary) -> List[dict]:
        merged: List[dict] = []
        by_key: Dict[Tuple[object, str], dict] = {}

        # Junta hoje+semana e remove duplicidades por disciplina + nome canônico.
        for row in (summary.overdue + summary.due_today + summary.due_week):
            disc_id = row.get("id_disciplina")
            key = (disc_id, canonical_task_name(row.get("nome")))
            existing = by_key.get(key)
            if not existing:
                by_key[key] = row
                continue

            # Mantém a tarefa "mais importante": maior peso; em empate, menor prazo.
            w_new = get_task_weight(row)
            w_old = get_task_weight(existing)
            d_new = parse_date_only(row.get("data_fim")) or date.max
            d_old = parse_date_only(existing.get("data_fim")) or date.max
            if (w_new > w_old) or (w_new == w_old and d_new < d_old):
                by_key[key] = row

        merged = list(by_key.values())
        return sorted(
            merged,
            key=lambda r: (
                -(get_task_weight(r)),
                parse_date_only(r.get("data_fim")) or date.max,
            ),
        )

    def build_priority_text(self, summary: DashboardSummary, disciplinas_map: Dict[int, dict], now: datetime) -> str:
        priority = self.build_today_priority_list(summary)
        lines = [f"Olhei sua semana ({now.date()})."]
        if not priority:
            lines.append("No momento, voce nao tem tarefa critica em aberto.")
            return "\n".join(lines)
        lines.append("Eu focaria nisso agora:")
        for task in priority[:4]:
            lines.append(self.format_task_line(task, disciplinas_map))
        lines.append("Se quiser, eu quebro isso em plano de hoje (manha/tarde/noite).")
        return "\n".join(lines)

    def build_concrete_chat_fallback(
        self,
        summary: DashboardSummary,
        disciplinas_map: Dict[int, dict],
        now: datetime,
    ) -> str:
        priority = self.build_today_priority_list(summary)
        if not priority:
            return (
                f"Hoje ({now.date()}) voce esta sem tarefa critica aberta. "
                "Se quiser, eu te monto um plano leve pra manter ritmo na semana."
            )

        lines = ["Beleza, olhando seu contexto agora, eu focaria nisso:"]
        for idx, task in enumerate(priority[:3], start=1):
            lines.append(f"{idx}. {self.format_task_natural(task, disciplinas_map)}")
        if summary.overdue:
            lines.append("Comeca pela primeira, porque ela esta mais critica.")
        else:
            lines.append("Comeca pela primeira e me chama quando terminar que eu recalculo.")
        return "\n".join(lines)

    @staticmethod
    def extract_priority_reference_index(text: str) -> Optional[int]:
        t = normalize_text(text)
        if any(w in t for w in ("primeira", "1", "um")):
            return 0
        if any(w in t for w in ("segunda", "2", "dois")):
            return 1
        if any(w in t for w in ("terceira", "3", "tres", "três")):
            return 2
        m = re.search(r"\b([1-9])\b", t)
        if m:
            return int(m.group(1)) - 1
        return None

    def build_follow_up_for_task(self, task: dict, disciplinas_map: Dict[int, dict]) -> str:
        due = str(task.get("data_fim") or "-")[:10]
        status = str(task.get("situacao") or "sem status").strip()
        link = str(task.get("link_canvas") or "").strip()
        base = f"Essa tarefa e: {self.format_task_natural(task, disciplinas_map)}. Situacao: {status}."
        if link:
            return f"{base}\nSe quiser abrir direto no Canvas: {link}"
        return base

    def add_dialog_turn(self, chat_id: str, role: str, text: str) -> None:
        line = f"{role}: {str(text or '').strip()}"
        if not line.strip():
            return
        history = self._dialog_history_by_chat.get(chat_id) or []
        history.append(line)
        self._dialog_history_by_chat[chat_id] = history[-8:]

    def build_dialog_history_block(self, chat_id: Optional[str]) -> str:
        if not chat_id:
            return ""
        rows = self._dialog_history_by_chat.get(chat_id) or []
        if not rows:
            return ""
        return "\n".join(rows[-6:])

    def build_runtime_info_text(self, cfg: dict, user_name: str) -> str:
        return (
            f"Resumo rápido ({user_name}):\n"
            f"- id_usuario: {cfg.get('id_usuario')}\n"
            f"- timezone: {cfg.get('timezone')}\n"
            f"- resumo diário: {cfg.get('daily_enabled')} às {cfg.get('daily_time')}\n"
            f"- resumo semanal: {cfg.get('weekly_enabled')} (dia {cfg.get('weekly_day')} às {cfg.get('weekly_time')})\n"
            f"- alertas urgentes: {cfg.get('urgent_enabled')} (janela {cfg.get('urgency_hours')}h)\n\n"
            "Como usar:\n"
            "- Pergunte em linguagem natural (ex.: 'o que tenho hoje?')\n"
            "- /plano para plano inteligente\n"
            "- /horario HH:MM para definir horário diário\n"
            "- /config para ver/ajustar tudo"
        )

    @staticmethod
    def format_task_line(task: dict, disciplinas_map: Dict[int, dict]) -> str:
        due = task.get("data_fim") or "-"
        peso = get_task_weight(task)
        disc_name = "Disciplina #{}".format(task.get("id_disciplina", "-"))
        try:
            disc = disciplinas_map.get(int(task.get("id_disciplina")))
            if disc and disc.get("nome"):
                disc_name = disc["nome"]
        except Exception:
            pass
        peso_txt = f" | peso: {peso:g}" if peso > 0 else ""
        due = str(due)[:10]
        return f"- {task.get('nome', 'Sem nome')} ({disc_name}) | prazo {due}{peso_txt}"

    @staticmethod
    def format_task_natural(task: dict, disciplinas_map: Dict[int, dict]) -> str:
        due = str(task.get("data_fim") or "-")[:10]
        disc_name = "disciplina"
        try:
            disc = disciplinas_map.get(int(task.get("id_disciplina")))
            if disc and disc.get("nome"):
                disc_name = disc["nome"]
        except Exception:
            pass
        return f"{task.get('nome', 'Sem nome')} ({disc_name}, prazo {due})"

    def build_canvas_context_block(
        self,
        summary: DashboardSummary,
        disciplinas_map: Dict[int, dict],
        now: datetime,
        chat_id: Optional[str] = None,
    ) -> str:
        def task_line(task: dict) -> str:
            due = str(task.get("data_fim") or "-")[:10]
            status = str(task.get("situacao") or "sem status").strip()
            link = str(task.get("link_canvas") or "").strip()
            base = f"- {self.format_task_natural(task, disciplinas_map)} | status: {status}"
            if link:
                base += f" | link: {link}"
            return base

        lines: List[str] = []
        lines.append(f"Data de referencia: {now.date()}")
        lines.append(
            f"Resumo: vencidas={len(summary.overdue)}, hoje={len(summary.due_today)}, semana={len(summary.due_week)}, pendentes={len(summary.pending)}, andamento={len(summary.in_progress)}"
        )
        lines.append("")
        lines.append("Vencidas (ate 8):")
        for task in summary.overdue[:8]:
            lines.append(task_line(task))
        if not summary.overdue:
            lines.append("- nenhuma")

        lines.append("")
        lines.append("Hoje + Semana (ate 10):")
        merged = (summary.due_today + summary.due_week)[:10]
        for task in merged:
            lines.append(task_line(task))
        if not merged:
            lines.append("- nenhuma")

        lines.append("")
        lines.append("Pendentes/andamento sem perder contexto (ate 8):")
        pending_pool = (summary.pending + summary.in_progress)[:8]
        for task in pending_pool:
            lines.append(task_line(task))
        if not pending_pool:
            lines.append("- nenhuma")

        if chat_id:
            last_priority = self._last_priority_by_chat.get(chat_id) or []
            if last_priority:
                lines.append("")
                lines.append("Ultimas prioridades mostradas ao usuario (ate 5):")
                for task in last_priority[:5]:
                    lines.append(task_line(task))

        return "\n".join(lines)

    def _build_ai_prompt(self, summary: DashboardSummary, disciplinas_map: Dict[int, dict], now: datetime) -> str:
        def section(title: str, tasks: List[dict], limit: int) -> str:
            lines = [f"{title} ({len(tasks)}):"]
            for task in tasks[:limit]:
                lines.append(self.format_task_line(task, disciplinas_map))
            if not tasks:
                lines.append("- nenhuma")
            return "\n".join(lines)

        return (
            "Você é um assistente pessoal de estudos. Responda em português do Brasil.\n"
            "Seja claro, humano e direto, sem texto longo.\n"
            "Monte um plano de execução para hoje e para os próximos 7 dias.\n"
            "Formato obrigatório:\n"
            "1) Foco de hoje (máx 3 bullets)\n"
            "2) Risco da semana (máx 3 bullets)\n"
            "3) Ordem sugerida (máx 5 itens numerados)\n"
            "4) Próxima ação imediata (1 linha)\n"
            "Sem introdução longa e sem repetir dados.\n\n"
            f"Data atual: {now.date()}\n\n"
            + section("Tarefas vencidas", summary.overdue, 10)
            + "\n\n"
            + section("Tarefas de hoje", summary.due_today, 10)
            + "\n\n"
            + section("Tarefas da semana", summary.due_week, 15)
            + "\n\n"
            + section("Backlog de hoje (inclui semana), priorizado por pontuação", self.build_today_priority_list(summary), 15)
            + "\n\n"
            + section("Tarefas em andamento", summary.in_progress, 10)
        )

    def generate_ai_plan(self, summary: DashboardSummary, disciplinas_map: Dict[int, dict], now: datetime) -> Optional[str]:
        if not BOT_AI_ENABLED or not self._gemini_keys:
            return None

        prompt = self._build_ai_prompt(summary, disciplinas_map, now)
        endpoint_tpl = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
        model_order = self.get_model_order()

        for model in model_order:
            for key in self._gemini_keys:
                try:
                    url = endpoint_tpl.format(model=model, key=key)
                    payload = {
                        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
                        "generationConfig": {
                            "temperature": 0.35,
                            "maxOutputTokens": 420
                        }
                    }
                    resp = requests.post(url, json=payload, timeout=25)
                    if resp.status_code >= 400:
                        continue
                    body = resp.json()
                    candidates = body.get("candidates") or []
                    if not candidates:
                        continue
                    parts = (((candidates[0] or {}).get("content") or {}).get("parts") or [])
                    text_parts = [str(p.get("text", "")) for p in parts if p.get("text")]
                    answer = "\n".join(text_parts).strip()
                    if answer:
                        self._preferred_model = model
                        # Telegram has a message cap; keep concise.
                        return answer[:3600]
                except Exception:
                    continue
        return None

    def generate_ai_chat_reply(
        self,
        user_text: str,
        summary: DashboardSummary,
        disciplinas_map: Dict[int, dict],
        now: datetime,
        chat_id: Optional[str] = None,
    ) -> Optional[str]:
        if not BOT_AI_ENABLED or not self._gemini_keys:
            return None

        user_text = (user_text or "").strip()
        if not user_text:
            return None

        def task_line(task: dict) -> str:
            status = str(task.get("situacao") or "sem status").strip()
            return f"{self.format_task_natural(task, disciplinas_map)} | status: {status}"

        week_items = summary.due_today + summary.due_week
        overdue_items = summary.overdue
        pending_items = summary.pending

        lines: List[str] = []
        lines.append(f"Data de referencia: {now.date()}")
        lines.append(
            f"Resumo: vencidas={len(overdue_items)}, hoje={len(summary.due_today)}, semana={len(summary.due_week)}, pendentes={len(pending_items)}"
        )
        lines.append("")
        lines.append("Tarefas vencidas:")
        if overdue_items:
            for task in overdue_items[:8]:
                lines.append(f"- {task_line(task)}")
        else:
            lines.append("- nenhuma")
        lines.append("")
        lines.append("Tarefas desta semana (inclui hoje):")
        if week_items:
            for task in week_items[:12]:
                lines.append(f"- {task_line(task)}")
        else:
            lines.append("- nenhuma")
        lines.append("")
        lines.append("Pendentes sem prazo claro para esta semana:")
        if pending_items:
            for task in pending_items[:8]:
                lines.append(f"- {task_line(task)}")
        else:
            lines.append("- nenhuma")

        tasks_context = "\n".join(lines)
        prompt = (
            "Responda ao usuario com base no contexto de tarefas abaixo.\n"
            "Use esse contexto como fonte principal para responder perguntas sobre atividades, prazos e prioridades.\n"
            "Se a pergunta envolver tarefas, cite itens concretos (nome, prazo e status).\n\n"
            "CONTEXTO DAS TAREFAS DA SEMANA:\n"
            + tasks_context
            + "\n\nPERGUNTA DO USUARIO:\n"
            + user_text
        )

        endpoint_tpl = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
        model_order = self.get_model_order()

        for model in model_order:
            for key in self._gemini_keys:
                try:
                    url = endpoint_tpl.format(model=model, key=key)
                    payload = {
                        "contents": [{"role": "user", "parts": [{"text": prompt}]}]
                    }
                    resp = requests.post(url, json=payload, timeout=25)
                    if resp.status_code >= 400:
                        continue
                    body = resp.json()
                    candidates = body.get("candidates") or []
                    if not candidates:
                        continue
                    parts = (((candidates[0] or {}).get("content") or {}).get("parts") or [])
                    text_parts = [str(p.get("text", "")) for p in parts if p.get("text")]
                    answer = "\n".join(text_parts).strip()
                    if answer:
                        self._preferred_model = model
                        return answer
                except Exception:
                    continue
        return None

    @staticmethod
    def split_text_for_telegram(text: str, max_len: int = 3500) -> List[str]:
        raw = str(text or "").replace("*", "").strip()
        if not raw:
            return []
        if len(raw) <= max_len:
            return [raw]

        chunks: List[str] = []
        remaining = raw
        while remaining:
            if len(remaining) <= max_len:
                chunks.append(remaining)
                break
            cut = remaining.rfind("\n\n", 0, max_len)
            if cut < 800:
                cut = remaining.rfind("\n", 0, max_len)
            if cut < 400:
                cut = max_len
            chunks.append(remaining[:cut].strip())
            remaining = remaining[cut:].strip()
        return [c for c in chunks if c]

    async def reply_text_chunks(self, message, text: str) -> None:
        parts = self.split_text_for_telegram(text)
        for part in parts:
            await message.reply_text(part)

    @staticmethod
    def synthesize_speech_ogg(text: str) -> Optional[bytes]:
        raw = str(text or "").strip()
        if not raw:
            return None

        wav_path = None
        ogg_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as wav_tmp:
                wav_path = wav_tmp.name
            with tempfile.NamedTemporaryFile(delete=False, suffix=".ogg") as ogg_tmp:
                ogg_path = ogg_tmp.name

            # Offline and free TTS engine.
            p1 = subprocess.run(
                ["espeak-ng", "-v", "pt-br", "-s", "165", "-w", wav_path, raw],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            if p1.returncode != 0:
                return None

            # Telegram voice note friendly format.
            p2 = subprocess.run(
                [
                    "ffmpeg",
                    "-y",
                    "-i",
                    wav_path,
                    "-c:a",
                    "libopus",
                    "-b:a",
                    "32k",
                    "-vbr",
                    "on",
                    ogg_path,
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            if p2.returncode != 0:
                return None

            with open(ogg_path, "rb") as f:
                return f.read()
        except Exception:
            return None
        finally:
            for path in (wav_path, ogg_path):
                if path:
                    try:
                        os.remove(path)
                    except Exception:
                        pass

    @staticmethod
    async def synthesize_speech_edge_mp3(text: str) -> Optional[bytes]:
        raw = str(text or "").strip()
        if not raw:
            return None

        try:
            import edge_tts
        except Exception:
            return None

        mp3_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as mp3_tmp:
                mp3_path = mp3_tmp.name

            communicate = edge_tts.Communicate(raw, voice="pt-BR-FranciscaNeural")
            await communicate.save(mp3_path)

            with open(mp3_path, "rb") as f:
                return f.read()
        except Exception:
            return None
        finally:
            if mp3_path:
                try:
                    os.remove(mp3_path)
                except Exception:
                    pass

    async def synthesize_speech_edge_ogg(self, text: str) -> Optional[bytes]:
        mp3_audio = await self.synthesize_speech_edge_mp3(text)
        if not mp3_audio:
            return None

        mp3_path = None
        ogg_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as mp3_tmp:
                mp3_path = mp3_tmp.name
                mp3_tmp.write(mp3_audio)
            with tempfile.NamedTemporaryFile(delete=False, suffix=".ogg") as ogg_tmp:
                ogg_path = ogg_tmp.name

            p = subprocess.run(
                [
                    "ffmpeg",
                    "-y",
                    "-i",
                    mp3_path,
                    "-c:a",
                    "libopus",
                    "-b:a",
                    "32k",
                    "-vbr",
                    "on",
                    ogg_path,
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            if p.returncode != 0:
                return None

            with open(ogg_path, "rb") as f:
                return f.read()
        except Exception:
            return None
        finally:
            for path in (mp3_path, ogg_path):
                if path:
                    try:
                        os.remove(path)
                    except Exception:
                        pass

    async def reply_voice_or_text(self, message, text: str) -> None:
        if BOT_REPLY_AUDIO_ONLY:
            spoken_text = str(text or "").strip()
            if BOT_TTS_MAX_CHARS > 0:
                spoken_text = spoken_text[:BOT_TTS_MAX_CHARS]
            if BOT_TTS_ENGINE == "edge":
                audio_ogg = None
                try:
                    audio_ogg = await asyncio.wait_for(
                        self.synthesize_speech_edge_ogg(spoken_text),
                        timeout=max(4, BOT_TTS_EDGE_TIMEOUT_SEC),
                    )
                except Exception:
                    audio_ogg = None
                if audio_ogg:
                    bio = io.BytesIO(audio_ogg)
                    bio.name = "reply.ogg"
                    try:
                        await message.reply_voice(voice=bio)
                        return
                    except Exception:
                        pass

            # Fallback local/offline.
            audio_ogg = self.synthesize_speech_ogg(spoken_text)
            if audio_ogg:
                bio = io.BytesIO(audio_ogg)
                bio.name = "reply.ogg"
                try:
                    await message.reply_voice(voice=bio)
                    return
                except Exception:
                    pass
        await self.reply_text_chunks(message, text)

    def _get_whisper_model(self):
        if self._whisper_model is not None:
            return self._whisper_model
        try:
            from faster_whisper import WhisperModel

            self._whisper_model = WhisperModel(
                WHISPER_MODEL_SIZE,
                device="cpu",
                compute_type=WHISPER_COMPUTE_TYPE,
            )
            return self._whisper_model
        except Exception:
            self._whisper_model = None
            return None

    def transcribe_audio_with_whisper(self, audio_bytes: bytes, mime_type: str = "audio/ogg") -> Optional[str]:
        if not audio_bytes:
            return None
        model = self._get_whisper_model()
        if model is None:
            return None

        suffix = ".ogg"
        mt = (mime_type or "").lower()
        if "mpeg" in mt or "mp3" in mt:
            suffix = ".mp3"
        elif "wav" in mt:
            suffix = ".wav"
        elif "mp4" in mt or "m4a" in mt:
            suffix = ".m4a"

        tmp_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as f:
                f.write(audio_bytes)
                tmp_path = f.name
            segments, _ = model.transcribe(
                tmp_path,
                language="pt",
                vad_filter=True,
                beam_size=1,
            )
            text = " ".join((seg.text or "").strip() for seg in segments).strip()
            return text[:1200] if text else None
        except Exception:
            return None
        finally:
            if tmp_path:
                try:
                    os.remove(tmp_path)
                except Exception:
                    pass

    def transcribe_audio_with_gemini(self, audio_bytes: bytes, mime_type: str = "audio/ogg") -> Optional[str]:
        if not BOT_AI_ENABLED or not self._gemini_keys:
            return None
        if not audio_bytes:
            return None

        b64_audio = base64.b64encode(audio_bytes).decode("ascii")
        prompt = (
            "Transcreva este audio em portugues do Brasil.\n"
            "Retorne apenas o texto transcrito, sem explicacoes."
        )
        endpoint_tpl = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
        model_order = self.get_model_order()

        for model in model_order:
            for key in self._gemini_keys:
                try:
                    url = endpoint_tpl.format(model=model, key=key)
                    payload = {
                        "contents": [
                            {
                                "role": "user",
                                "parts": [
                                    {"text": prompt},
                                    {
                                        "inline_data": {
                                            "mime_type": mime_type or "audio/ogg",
                                            "data": b64_audio,
                                        }
                                    },
                                ],
                            }
                        ],
                        "generationConfig": {
                            "temperature": 0.1,
                            "maxOutputTokens": 300,
                        },
                    }
                    resp = requests.post(url, json=payload, timeout=45)
                    if resp.status_code >= 400:
                        continue
                    body = resp.json()
                    candidates = body.get("candidates") or []
                    if not candidates:
                        continue
                    parts = (((candidates[0] or {}).get("content") or {}).get("parts") or [])
                    text_parts = [str(p.get("text", "")).strip() for p in parts if p.get("text")]
                    transcript = "\n".join([p for p in text_parts if p]).strip()
                    if transcript:
                        return transcript[:1200]
                except Exception:
                    continue
        return None

    def transcribe_audio(self, audio_bytes: bytes, mime_type: str = "audio/ogg") -> Optional[str]:
        provider = BOT_AUDIO_STT_PROVIDER
        if provider == "gemini":
            return self.transcribe_audio_with_gemini(audio_bytes, mime_type=mime_type)

        # Default: local Whisper first, fallback to Gemini.
        local_text = self.transcribe_audio_with_whisper(audio_bytes, mime_type=mime_type)
        if local_text:
            return local_text
        return self.transcribe_audio_with_gemini(audio_bytes, mime_type=mime_type)

    async def cmd_start(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)
        user_name = self.get_user_name(int(cfg.get("id_usuario") or BOT_DEFAULT_USER_ID))
        text = (
            f"Pronto, {user_name}. Vou te responder de forma objetiva e organizada.\n\n"
            f"Usuario: {cfg.get('id_usuario')} | Timezone: {cfg.get('timezone')}\n\n"
            "Comandos principais:\n"
            "/hoje | /semana | /urgentes | /plano\n"
            "/agenda | /disciplinas | /config | /horario HH:MM\n\n"
            "Também pode mandar mensagem normal, tipo: 'o que priorizo hoje?'"
        )
        await update.message.reply_text(text)

    async def cmd_help(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        await self.cmd_start(update, context)

    async def cmd_hoje(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)
        user_name = self.get_user_name(int(cfg.get("id_usuario") or BOT_DEFAULT_USER_ID))
        tz = ZoneInfo(cfg.get("timezone") or BOT_DEFAULT_TIMEZONE)
        now = datetime.now(tz)
        summary, disciplinas_map = self.build_summary(int(cfg["id_usuario"]), now)
        today_priority = self.build_today_priority_list(summary)

        lines = [f"{user_name}, resumo de hoje ({now.date()}):"]
        lines.append(
            f"Resumo: vencidas {len(summary.overdue)} | hoje {len(summary.due_today)} | semana {len(summary.due_week)} | andamento {len(summary.in_progress)}"
        )
        lines.append("")
        if today_priority:
            lines.append("Ordem sugerida:")
            for item in today_priority[:5]:
                lines.append(self.format_task_line(item, disciplinas_map))
        else:
            lines.append("Sem tarefa critica para hoje.")

        await update.message.reply_text("\n".join(lines))

    async def cmd_semana(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)
        user_name = self.get_user_name(int(cfg.get("id_usuario") or BOT_DEFAULT_USER_ID))
        tz = ZoneInfo(cfg.get("timezone") or BOT_DEFAULT_TIMEZONE)
        now = datetime.now(tz)
        summary, disciplinas_map = self.build_summary(int(cfg["id_usuario"]), now)
        end_week = now.date() + timedelta(days=7)

        in_progress_week = []
        for task in summary.in_progress:
            due = parse_date_only(task.get("data_fim"))
            if due is not None and due <= end_week:
                in_progress_week.append(task)
        in_progress_week = sorted(
            in_progress_week,
            key=lambda r: parse_date_only(r.get("data_fim")) or date.max,
        )

        lines = [f"{user_name}, semana ate {end_week}:"]
        lines.append(
            f"Resumo: vencidas {len(summary.overdue)} | hoje {len(summary.due_today)} | 7 dias {len(summary.due_week)} | andamento {len(in_progress_week)}"
        )
        lines.append("")

        if in_progress_week:
            lines.append("Em andamento:")
            for item in in_progress_week[:5]:
                lines.append(self.format_task_line(item, disciplinas_map))
            lines.append("")

        if summary.due_week:
            lines.append("Proximos prazos:")
            for item in summary.due_week[:8]:
                lines.append(self.format_task_line(item, disciplinas_map))
        else:
            lines.append("Sem prazo para os proximos 7 dias.")
        await update.message.reply_text("\n".join(lines))

    async def cmd_urgentes(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)
        user_name = self.get_user_name(int(cfg.get("id_usuario") or BOT_DEFAULT_USER_ID))
        tz = ZoneInfo(cfg.get("timezone") or BOT_DEFAULT_TIMEZONE)
        now = datetime.now(tz)
        summary, disciplinas_map = self.build_summary(int(cfg["id_usuario"]), now)

        critical = summary.overdue + summary.due_today
        lines = [f"{user_name}, urgentes agora: {len(critical)}"]
        if not critical:
            lines.append("Nenhuma tarefa critica no momento.")
        else:
            for item in critical[:8]:
                lines.append(self.format_task_line(item, disciplinas_map))
        await update.message.reply_text("\n".join(lines))

    async def cmd_disciplinas(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)
        tz = ZoneInfo(cfg.get("timezone") or BOT_DEFAULT_TIMEZONE)
        today = datetime.now(tz).date()

        resp = (
            self.supabase.table("disciplina")
            .select("id, nome, situation, date_inicio, date_fim, canvas_sync, tipo_disciplina")
            .eq("canvas_sync", True)
            .execute()
        )
        rows = resp.data or []
        active = []
        approved = []
        for row in rows:
            status = normalize_text(row.get("situation"))
            if "aprov" in status or "conclu" in status or "finaliz" in status:
                approved.append(row)
            elif status == "estudando" and is_disciplina_in_study_period(row, today, require_valid_dates=True):
                active.append(row)

        lines = [
            "Disciplinas (Canvas):",
            f"- Em estudo (periodo ativo): {len(active)}",
            f"- Aprovadas/finalizadas: {len(approved)}",
            "",
            "Em estudo:",
        ]
        for row in active[:10]:
            lines.append(f"- {row.get('nome')} | {row.get('date_inicio')} ate {row.get('date_fim')}")
        await update.message.reply_text("\n".join(lines))

    async def cmd_agenda(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)
        user_name = self.get_user_name(int(cfg.get("id_usuario") or BOT_DEFAULT_USER_ID))
        tz = ZoneInfo(cfg.get("timezone") or BOT_DEFAULT_TIMEZONE)
        now = datetime.now(tz)
        summary, _ = self.build_summary(int(cfg["id_usuario"]), now)

        text = (
            f"Agenda de {user_name} ({now.date()}):\n"
            f"- Vencidas: {len(summary.overdue)}\n"
            f"- Hoje: {len(summary.due_today)}\n"
            f"- Semana: {len(summary.due_week)}\n"
            f"- Em andamento: {len(summary.in_progress)}\n"
            f"- Pendentes: {len(summary.pending)}"
        )
        await update.message.reply_text(text)

    async def cmd_plano(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)
        tz = ZoneInfo(cfg.get("timezone") or BOT_DEFAULT_TIMEZONE)
        now = datetime.now(tz)
        summary, disciplinas_map = self.build_summary(int(cfg["id_usuario"]), now)
        ai_text = self.generate_ai_plan(summary, disciplinas_map, now)

        if ai_text:
            await update.message.reply_text(f"Plano inteligente:\n\n{ai_text}")
            return

        await update.message.reply_text(
            "IA indisponível no momento. Use /hoje e /semana enquanto eu mantenho os alertas automáticos."
        )

    async def cmd_modelo(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        model, msg = self.probe_first_working_model()
        order = ", ".join(self.get_model_order()[:6])
        suffix = f"\nOrdem tentativa: {order}"
        if model:
            await update.message.reply_text(msg + suffix)
            return
        await update.message.reply_text(msg + suffix)

    async def cmd_usuario(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        if not update.effective_chat:
            return
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)

        if not context.args:
            uid = int(cfg.get("id_usuario") or BOT_DEFAULT_USER_ID)
            name = self.get_user_name(uid)
            await update.message.reply_text(
                f"Usuário atual deste chat:\n- id_usuario: {uid}\n- nome: {name}\n\n"
                "Para trocar: /usuario <id>\nExemplo: /usuario 3"
            )
            return

        raw = str(context.args[0]).strip()
        try:
            new_uid = int(raw)
        except Exception:
            await update.message.reply_text("ID inválido. Use número inteiro.\nExemplo: /usuario 3")
            return

        if new_uid <= 0:
            await update.message.reply_text("ID inválido. O id_usuario deve ser maior que zero.")
            return

        if not self.user_exists(new_uid):
            await update.message.reply_text(f"Usuário id={new_uid} não encontrado na tabela users.")
            return

        updated = self.update_chat_config(chat_id, {"id_usuario": new_uid})
        name = self.get_user_name(new_uid)
        await update.message.reply_text(
            f"Vinculação atualizada.\n- id_usuario: {updated.get('id_usuario')}\n- nome: {name}"
        )

    async def cmd_config(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        if not update.effective_chat:
            return
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)

        if not context.args:
            await update.message.reply_text(
                "Config atual:\n"
                f"- timezone: {cfg.get('timezone')}\n"
                f"- daily_enabled: {cfg.get('daily_enabled')}\n"
                f"- daily_time: {cfg.get('daily_time')}\n"
                f"- weekly_enabled: {cfg.get('weekly_enabled')}\n"
                f"- weekly_day: {cfg.get('weekly_day')} (0=Seg ... 6=Dom)\n"
                f"- weekly_time: {cfg.get('weekly_time')}\n"
                f"- urgent_enabled: {cfg.get('urgent_enabled')}\n"
                f"- urgency_hours: {cfg.get('urgency_hours')}\n\n"
                "Comandos:\n"
                "/config daily on|off\n"
                "/config weekly on|off\n"
                "/config urgent on|off\n"
                "/config timezone <Area/Cidade>\n"
                "/config daily_time HH:MM\n"
                "/config weekly_day 0-6\n"
                "/config weekly_time HH:MM\n"
                "/config urgency_hours <numero>"
            )
            return

        key = normalize_text(context.args[0])
        value = " ".join(context.args[1:]).strip() if len(context.args) > 1 else ""

        def parse_on_off(v: str) -> Optional[bool]:
            v = normalize_text(v)
            if v in ("on", "true", "1", "sim", "yes"):
                return True
            if v in ("off", "false", "0", "nao", "não", "no"):
                return False
            return None

        updates = {}
        err = None

        if key == "daily":
            flag = parse_on_off(value)
            if flag is None:
                err = "Uso: /config daily on|off"
            else:
                updates["daily_enabled"] = flag
        elif key == "weekly":
            flag = parse_on_off(value)
            if flag is None:
                err = "Uso: /config weekly on|off"
            else:
                updates["weekly_enabled"] = flag
        elif key == "urgent":
            flag = parse_on_off(value)
            if flag is None:
                err = "Uso: /config urgent on|off"
            else:
                updates["urgent_enabled"] = flag
        elif key == "timezone":
            if not value:
                err = "Uso: /config timezone Area/Cidade"
            else:
                try:
                    ZoneInfo(value)
                    updates["timezone"] = value
                except Exception:
                    err = f"Timezone inválida: {value}"
        elif key == "daily_time":
            t = parse_time_only(value, fallback=None) if value else None
            if t is None:
                err = "Uso: /config daily_time HH:MM"
            else:
                updates["daily_time"] = t.strftime("%H:%M:%S")
        elif key == "weekly_day":
            try:
                wd = int(value)
                if wd < 0 or wd > 6:
                    raise ValueError
                updates["weekly_day"] = wd
            except Exception:
                err = "Uso: /config weekly_day 0-6"
        elif key == "weekly_time":
            t = parse_time_only(value, fallback=None) if value else None
            if t is None:
                err = "Uso: /config weekly_time HH:MM"
            else:
                updates["weekly_time"] = t.strftime("%H:%M:%S")
        elif key == "urgency_hours":
            try:
                hours = int(value)
                if hours < 0 or hours > 168:
                    raise ValueError
                updates["urgency_hours"] = hours
            except Exception:
                err = "Uso: /config urgency_hours <0-168>"
        else:
            err = "Chave inválida. Use /config para ver opções."

        if err:
            await update.message.reply_text(err)
            return

        updated = self.update_chat_config(chat_id, updates)
        await update.message.reply_text(
            "Configuração atualizada.\n"
            f"- timezone: {updated.get('timezone')}\n"
            f"- daily_enabled: {updated.get('daily_enabled')} ({updated.get('daily_time')})\n"
            f"- weekly_enabled: {updated.get('weekly_enabled')} (dia {updated.get('weekly_day')}, {updated.get('weekly_time')})\n"
            f"- urgent_enabled: {updated.get('urgent_enabled')} (janela {updated.get('urgency_hours')}h)"
        )

    async def cmd_horario(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        if not update.effective_chat:
            return
        chat_id = str(update.effective_chat.id)

        if not context.args:
            cfg = self.get_config_for_chat(chat_id)
            await update.message.reply_text(
                f"Horário atual do resumo diário: {cfg.get('daily_time')}\n"
                "Para alterar: /horario HH:MM\n"
                "Exemplo: /horario 07:30"
            )
            return

        value = str(context.args[0]).strip()
        t = parse_time_only(value, fallback=None)
        if t is None:
            await update.message.reply_text("Formato inválido. Use /horario HH:MM (ex.: /horario 07:30)")
            return

        updated = self.update_chat_config(
            chat_id,
            {
                "daily_enabled": True,
                "daily_time": t.strftime("%H:%M:%S"),
            },
        )
        await update.message.reply_text(
            f"Pronto. Vou te enviar o resumo diário (com tarefas da semana) às {updated.get('daily_time')}."
        )

    async def on_free_text(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        if not update.message or not update.effective_chat:
            return

        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)
        user_name = self.get_user_name(int(cfg.get("id_usuario") or BOT_DEFAULT_USER_ID))
        tz = ZoneInfo(cfg.get("timezone") or BOT_DEFAULT_TIMEZONE)
        now = datetime.now(tz)
        summary, disciplinas_map = self.build_summary(int(cfg["id_usuario"]), now)
        user_text = update.message.text or ""
        normalized = normalize_text(user_text)
        priority = self.build_today_priority_list(summary)
        self._last_priority_by_chat[chat_id] = priority
        self._last_disciplinas_by_chat[chat_id] = disciplinas_map
        self.add_dialog_turn(chat_id, "usuario", user_text)

        ai_reply = self.generate_ai_chat_reply(user_text, summary, disciplinas_map, now, chat_id=chat_id)
        if ai_reply:
            await self.reply_voice_or_text(update.message, ai_reply)
            self.add_dialog_turn(chat_id, "assistente", ai_reply)
            return

        msg = "Nao consegui responder agora. Tenta reformular sua mensagem."
        await self.reply_text_chunks(update.message, msg)
        self.add_dialog_turn(chat_id, "assistente", msg)
        return

    async def on_audio_message(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        if not update.message or not update.effective_chat:
            return

        media = update.message.voice or update.message.audio
        if not media:
            await self.reply_text_chunks(update.message, "Nao consegui ler esse audio. Tente novamente.")
            return

        mime_type = getattr(media, "mime_type", None) or "audio/ogg"
        duration = int(getattr(media, "duration", 0) or 0)
        file_size = int(getattr(media, "file_size", 0) or 0)

        if BOT_AUDIO_MAX_SECONDS > 0 and duration > BOT_AUDIO_MAX_SECONDS:
            await self.reply_text_chunks(
                update.message,
                f"Audio muito longo ({duration}s). Envie ate {BOT_AUDIO_MAX_SECONDS}s para eu responder rapido."
            )
            return

        if BOT_AUDIO_MAX_BYTES > 0 and file_size > BOT_AUDIO_MAX_BYTES:
            await self.reply_text_chunks(
                update.message,
                "Arquivo de audio muito grande. Envie um audio menor ou em texto."
            )
            return

        try:
            telegram_file = await context.bot.get_file(media.file_id)
            audio_buffer = await telegram_file.download_as_bytearray()
            transcript = self.transcribe_audio(bytes(audio_buffer), mime_type=mime_type)
        except Exception:
            transcript = None

        if not transcript:
            await self.reply_text_chunks(
                update.message,
                "Nao consegui entender o audio. Pode tentar de novo ou mandar em texto?"
            )
            return

        responses = await self.handle_incoming_text(str(update.effective_chat.id), transcript)
        if not responses:
            await self.reply_text_chunks(
                update.message,
                "Entendi seu audio, mas nao consegui montar resposta agora. Tente reformular."
            )
            return

        for response in responses:
            if response:
                await self.reply_voice_or_text(update.message, response)

    def has_notification(self, chat_id: str, kind: str, dedupe_key: str) -> bool:
        try:
            resp = (
                self.supabase.table("bot_notifications_log")
                .select("id")
                .eq("telegram_chat_id", chat_id)
                .eq("notification_kind", kind)
                .eq("dedupe_key", dedupe_key)
                .limit(1)
                .execute()
            )
            return bool(resp.data)
        except Exception as exc:
            if self.is_schema_missing_error(exc):
                self.warn_schema_missing_once(exc)
                return False
            raise

    def mark_notification(self, chat_id: str, kind: str, dedupe_key: str, payload: dict) -> None:
        try:
            self.supabase.table("bot_notifications_log").upsert(
                {
                    "telegram_chat_id": chat_id,
                    "notification_kind": kind,
                    "dedupe_key": dedupe_key,
                    "payload": payload,
                },
                on_conflict="dedupe_key",
            ).execute()
        except Exception as exc:
            if self.is_schema_missing_error(exc):
                self.warn_schema_missing_once(exc)
                return
            raise

    async def run_scheduled_cycle(self) -> None:
        if not BOT_PROACTIVE_ENABLED:
            return
        try:
            resp = self.supabase.table("bot_config").select("*").execute()
            configs = resp.data or []
        except Exception as exc:
            if self.is_schema_missing_error(exc):
                self.warn_schema_missing_once(exc)
                return
            raise
        if not configs:
            return

        for cfg in configs:
            chat_id = str(cfg.get("telegram_chat_id") or "").strip()
            if not chat_id:
                continue
            try:
                await self._process_single_config(cfg)
            except Exception as exc:
                print(f"[bot] cycle error chat={chat_id}: {exc}")

    async def _process_single_config(self, cfg: dict) -> None:
        chat_id = str(cfg["telegram_chat_id"])
        user_id = int(cfg.get("id_usuario") or BOT_DEFAULT_USER_ID)
        user_name = self.get_user_name(user_id)
        tz = ZoneInfo(cfg.get("timezone") or BOT_DEFAULT_TIMEZONE)
        now = datetime.now(tz)
        summary, disciplinas_map = self.build_summary(user_id, now, strict_active_disciplines=True)

        daily_time = parse_time_only(cfg.get("daily_time"), time(7, 30))
        weekly_time = parse_time_only(cfg.get("weekly_time"), time(18, 0))
        weekly_day = int(cfg.get("weekly_day") if cfg.get("weekly_day") is not None else 6)
        urgency_hours = int(cfg.get("urgency_hours") if cfg.get("urgency_hours") is not None else 6)

        if cfg.get("daily_enabled", True) and now.time() >= daily_time:
            key = f"daily:{chat_id}:{now.date().isoformat()}"
            if not self.has_notification(chat_id, "daily", key):
                today_priority = self.build_today_priority_list(summary)
                msg_lines = [
                    f"{user_name}, plano de acao - {now.date()}",
                    "",
                    "Resumo:",
                    f"- Vencidas: {len(summary.overdue)}",
                    f"- Vencem hoje: {len(summary.due_today)}",
                    f"- Proximos 7 dias: {len(summary.due_week)}",
                    f"- Em andamento: {len(summary.in_progress)}",
                    "",
                ]

                if summary.overdue:
                    msg_lines.append("Prioridade maxima (vencidas):")
                    for task in summary.overdue[:3]:
                        msg_lines.append(self.format_task_line(task, disciplinas_map))
                    msg_lines.append("")

                if today_priority:
                    msg_lines.append("Fazer hoje (inclui semana), prioridade por pontuacao:")
                    for task in today_priority[:8]:
                        msg_lines.append(self.format_task_line(task, disciplinas_map))
                    msg_lines.append("")

                if summary.due_week:
                    msg_lines.append("Organizar para esta semana:")
                    for task in summary.due_week[:5]:
                        msg_lines.append(self.format_task_line(task, disciplinas_map))
                    msg_lines.append("")

                if not summary.overdue and not summary.due_today and not summary.due_week:
                    msg_lines.append("Sem tarefas criticas para hoje/semana. Foque em revisao.")

                ai_plan = self.generate_ai_plan(summary, disciplinas_map, now)
                if ai_plan:
                    msg_lines.extend(["", "Plano inteligente (IA):", ai_plan])

                msg = "\n".join(msg_lines)
                await self.application.bot.send_message(chat_id=chat_id, text=msg)
                self.mark_notification(chat_id, "daily", key, {"date": now.date().isoformat()})

        if cfg.get("weekly_enabled", True) and now.weekday() == weekly_day and now.time() >= weekly_time:
            week_key = now.strftime("%G-W%V")
            key = f"weekly:{chat_id}:{week_key}"
            if not self.has_notification(chat_id, "weekly", key):
                msg = (
                    f"Resumo semanal ({week_key}):\n"
                    f"- Vencidas: {len(summary.overdue)}\n"
                    f"- Hoje: {len(summary.due_today)}\n"
                    f"- Proximos 7 dias: {len(summary.due_week)}\n"
                    f"- Pendentes: {len(summary.pending)}"
                )
                await self.application.bot.send_message(chat_id=chat_id, text=msg)
                self.mark_notification(chat_id, "weekly", key, {"week": week_key})

        if cfg.get("urgent_enabled", True):
            now_date = now.date()
            for task in summary.due_today + summary.overdue:
                task_id = task.get("id")
                if task_id is None:
                    continue
                key = f"urgent:{chat_id}:{now_date.isoformat()}:{task_id}"
                if self.has_notification(chat_id, "urgent", key):
                    continue
                due = parse_date_only(task.get("data_fim"))
                if due is None:
                    continue
                if due < now_date or (due == now_date and urgency_hours >= 0):
                    text = (
                        "Alerta urgente:\n"
                        f"- {task.get('nome', 'Sem nome')}\n"
                        f"- Prazo: {task.get('data_fim')}\n"
                        f"- Situacao: {task.get('situacao')}"
                    )
                    await self.application.bot.send_message(chat_id=chat_id, text=text)
                    self.mark_notification(chat_id, "urgent", key, {"task_id": task_id})

    async def on_startup(self, _: Application) -> None:
        if not BOT_PROACTIVE_ENABLED:
            print("[bot] proactive notifications disabled")
            return
        self.scheduler.add_job(self.run_scheduled_cycle, "interval", seconds=BOT_POLL_SECONDS)
        self.scheduler.start()
        print(f"[bot] scheduler started (interval={BOT_POLL_SECONDS}s)")

    async def on_shutdown(self, _: Application) -> None:
        if self.scheduler.running:
            self.scheduler.shutdown(wait=False)
        print("[bot] scheduler stopped")

    def run(self) -> None:
        self.application.post_init = self.on_startup
        self.application.post_shutdown = self.on_shutdown
        self.application.run_polling(allowed_updates=Update.ALL_TYPES)

    async def handle_incoming_text(self, chat_id: str, text: str) -> List[str]:
        class _DummyChat:
            def __init__(self, cid: str) -> None:
                self.id = int(cid)

        class _DummyMessage:
            def __init__(self, txt: str, collector: List[str]) -> None:
                self.text = txt
                self._collector = collector

            async def reply_text(self, value: str) -> None:
                if value:
                    self._collector.append(str(value))

        class _DummyUpdate:
            def __init__(self, cid: str, txt: str, collector: List[str]) -> None:
                self.effective_chat = _DummyChat(cid)
                self.message = _DummyMessage(txt, collector)

        class _DummyContext:
            def __init__(self, args: Optional[List[str]] = None) -> None:
                self.args = args or []

        responses: List[str] = []
        update = _DummyUpdate(chat_id, text, responses)

        stripped = str(text or "").strip()
        if stripped.startswith("/"):
            parts = stripped.split()
            cmd = parts[0].split("@")[0].lower()
            args = parts[1:]
            ctx = _DummyContext(args)
            if cmd == "/start":
                await self.cmd_start(update, ctx)
            elif cmd == "/help":
                await self.cmd_help(update, ctx)
            elif cmd == "/hoje":
                await self.cmd_hoje(update, ctx)
            elif cmd == "/semana":
                await self.cmd_semana(update, ctx)
            elif cmd == "/urgentes":
                await self.cmd_urgentes(update, ctx)
            elif cmd == "/disciplinas":
                await self.cmd_disciplinas(update, ctx)
            elif cmd == "/agenda":
                await self.cmd_agenda(update, ctx)
            elif cmd == "/plano":
                await self.cmd_plano(update, ctx)
            elif cmd == "/modelo":
                await self.cmd_modelo(update, ctx)
            elif cmd == "/usuario":
                await self.cmd_usuario(update, ctx)
            elif cmd == "/config":
                await self.cmd_config(update, ctx)
            elif cmd == "/horario":
                await self.cmd_horario(update, ctx)
            else:
                responses.append("Comando não reconhecido. Use /help.")
        else:
            await self.on_free_text(update, _DummyContext([]))

        return responses


def main() -> None:
    bot = StudySecretaryBot()
    bot.run()


if __name__ == "__main__":
    main()
