#!/usr/bin/env python3
import os
import re
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


TELEGRAM_BOT_TOKEN = env_str("TELEGRAM_BOT_TOKEN")
SUPABASE_URL = env_str("SUPABASE_URL")
SUPABASE_KEY = env_str("SUPABASE_KEY")
BOT_DEFAULT_USER_ID = env_int("BOT_DEFAULT_USER_ID", 1)
BOT_DEFAULT_TIMEZONE = env_str("BOT_DEFAULT_TIMEZONE", "America/Sao_Paulo")
BOT_POLL_SECONDS = env_int("BOT_POLL_SECONDS", 60)
BOT_AI_ENABLED = env_str("BOT_AI_ENABLED", "true").lower() in ("1", "true", "yes", "on")
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


def is_done_task(status: str) -> bool:
    s = normalize_text(status)
    return any(x in s for x in ("conclu", "entregue", "corrigida", "finalizada"))


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

    def build_summary(self, user_id: int, now: datetime) -> Tuple[DashboardSummary, Dict[int, dict]]:
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
            status = normalize_text(task.get("situacao"))
            if is_done_task(status):
                continue

            disc_id = task.get("id_disciplina")
            try:
                disc_id_int = int(disc_id)
            except Exception:
                disc_id_int = None
            disciplina = disciplinas_map.get(disc_id_int) if disc_id_int is not None else None

            # Only include tasks from disciplines that are truly active for alerts.
            if not is_disciplina_active_for_alerts(disciplina, today):
                continue

            due = parse_date_only(task.get("data_fim"))
            if "andamento" in status:
                in_progress.append(task)
            if "pendente" in status or "nao entregue" in status:
                pending.append(task)

            if due is None:
                continue
            if due < today:
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
        lines = [f"Prioridades de hoje ({now.date()}):"]
        lines.append(f"- Vencidas: {len(summary.overdue)}")
        lines.append(f"- Vencem hoje: {len(summary.due_today)}")
        lines.append(f"- Semana no radar: {len(summary.due_week)}")
        lines.append("")
        if not priority:
            lines.append("Sem tarefas críticas para hoje.")
            return "\n".join(lines)
        lines.append("Ordem de execução (pontuação > prazo):")
        for task in priority[:8]:
            lines.append(self.format_task_line(task, disciplinas_map))
        return "\n".join(lines)

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
        return f"- {task.get('nome', 'Sem nome')} | {disc_name} | prazo: {due}{peso_txt}"

    def _build_ai_prompt(self, summary: DashboardSummary, disciplinas_map: Dict[int, dict], now: datetime) -> str:
        def section(title: str, tasks: List[dict], limit: int) -> str:
            lines = [f"{title} ({len(tasks)}):"]
            for task in tasks[:limit]:
                lines.append(self.format_task_line(task, disciplinas_map))
            if not tasks:
                lines.append("- nenhuma")
            return "\n".join(lines)

        return (
            "Você é um secretário de estudos objetivo. Responda em português do Brasil.\n"
            "Monte um plano de execução para hoje e para os próximos 7 dias.\n"
            "Formato obrigatório:\n"
            "1) Foco de hoje (máx 5 bullets)\n"
            "2) Risco da semana (máx 5 bullets)\n"
            "3) Ordem sugerida de execução (máx 6 itens numerados)\n"
            "4) Avisos de prazo (curto e direto)\n"
            "Sem introdução longa.\n\n"
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
                            "maxOutputTokens": 700
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
    ) -> Optional[str]:
        if not BOT_AI_ENABLED or not self._gemini_keys:
            return None

        user_text = (user_text or "").strip()
        if not user_text:
            return None

        context_lines = [
            f"Hoje: {now.date()}",
            f"Vencidas: {len(summary.overdue)}",
            f"Hoje: {len(summary.due_today)}",
            f"Semana: {len(summary.due_week)}",
            f"Em andamento: {len(summary.in_progress)}",
            "",
            "Top tarefas de hoje/semana priorizadas por pontuacao:",
        ]
        top_items = self.build_today_priority_list(summary)[:8]
        if top_items:
            for task in top_items:
                context_lines.append(self.format_task_line(task, disciplinas_map))
        else:
            context_lines.append("- Sem tarefas urgentes no momento.")

        prompt = (
            "Você é um secretário pessoal de estudos no Telegram.\n"
            "Responda de forma natural, objetiva, amigável e útil, em português do Brasil.\n"
            "Se o usuário pedir organização, devolva em passos acionáveis.\n"
            "Se o usuário perguntar por prazo, destaque urgências primeiro.\n"
            "Evite resposta longa demais (máx. ~12 linhas).\n\n"
            "Contexto de tarefas do usuário:\n"
            + "\n".join(context_lines)
            + "\n\nMensagem do usuário:\n"
            + user_text
        )

        endpoint_tpl = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
        model_order = self.get_model_order()

        for model in model_order:
            for key in self._gemini_keys:
                try:
                    url = endpoint_tpl.format(model=model, key=key)
                    payload = {
                        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
                        "generationConfig": {
                            "temperature": 0.5,
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
                        return answer[:2500]
                except Exception:
                    continue
        return None

    async def cmd_start(self, update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        chat_id = str(update.effective_chat.id)
        cfg = self.get_config_for_chat(chat_id)
        user_name = self.get_user_name(int(cfg.get("id_usuario") or BOT_DEFAULT_USER_ID))
        text = (
            f"Bot secretário ativado, {user_name}.\n\n"
            f"Usuario vinculado: {cfg.get('id_usuario')}\n"
            f"Timezone: {cfg.get('timezone')}\n\n"
            "Comandos:\n"
            "/hoje - tarefas vencidas e de hoje\n"
            "/semana - tarefas dos proximos 7 dias\n"
            "/urgentes - tarefas criticas\n"
            "/disciplinas - status das disciplinas\n"
            "/agenda - resumo completo\n"
            "/plano - plano inteligente com IA\n"
            "/modelo - verifica modelo Gemini ativo\n"
            "/usuario - ver/trocar id_usuario deste chat\n"
            "/config - ver/alterar preferencias\n"
            "/horario HH:MM - define horario do resumo diario"
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
        lines.append(f"- Vencidas: {len(summary.overdue)}")
        lines.append(f"- Vencem hoje: {len(summary.due_today)}")
        lines.append(f"- Semana no radar de hoje: {len(summary.due_week)}")
        lines.append(f"- Em andamento: {len(summary.in_progress)}")
        lines.append("")
        if today_priority:
            lines.append("Fazer hoje (inclui semana), prioridade por pontuacao:")
            for item in today_priority[:8]:
                lines.append(self.format_task_line(item, disciplinas_map))

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

        lines = [f"{user_name}, planejamento da semana (ate {(now.date() + timedelta(days=7))}):"]
        lines.append(f"- Vencidas: {len(summary.overdue)}")
        lines.append(f"- Hoje: {len(summary.due_today)}")
        lines.append(f"- Proximos 7 dias: {len(summary.due_week)}")
        lines.append(f"- Em andamento na semana: {len(in_progress_week)}")
        lines.append("")

        if in_progress_week:
            lines.append("Atividades em andamento (semana):")
            for item in in_progress_week:
                lines.append(self.format_task_line(item, disciplinas_map))
            lines.append("")

        if summary.due_week:
            lines.append("Demais tarefas dos proximos 7 dias:")
            for item in summary.due_week:
                lines.append(self.format_task_line(item, disciplinas_map))
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
            for item in critical[:15]:
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

        # Automatic guidance on every user text message.
        await update.message.reply_text(self.build_runtime_info_text(cfg, user_name))

        if is_greeting_text(user_text):
            await update.message.reply_text(
                f"Oi, {user_name}. Manda \"o que tenho hoje\" que eu te passo as prioridades direto."
            )
            return

        # Follow-up curto para continuar o último contexto de tarefas.
        if normalized in {"quais", "quais?", "e quais", "quero ver", "me mostra"}:
            last_priority = self._last_priority_by_chat.get(chat_id) or []
            last_map = self._last_disciplinas_by_chat.get(chat_id) or {}
            if last_priority:
                lines = ["Aqui estão as prioridades:"]
                for task in last_priority[:8]:
                    lines.append(self.format_task_line(task, last_map))
                await update.message.reply_text("\n".join(lines))
                return

        if is_planning_request(user_text):
            priority = self.build_today_priority_list(summary)
            self._last_priority_by_chat[chat_id] = priority
            self._last_disciplinas_by_chat[chat_id] = disciplinas_map
            await update.message.reply_text(self.build_priority_text(summary, disciplinas_map, now))
            return

        if not is_planning_request(user_text):
            ai_reply = self.generate_ai_chat_reply(user_text, summary, disciplinas_map, now)
            if ai_reply:
                await update.message.reply_text(ai_reply)
                return
            await update.message.reply_text(
                "Posso te ajudar com estudos e prazos. Tente /plano, /hoje ou /semana."
            )
            return

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
        summary, disciplinas_map = self.build_summary(user_id, now)

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
