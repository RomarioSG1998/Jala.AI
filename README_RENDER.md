# Deploy do bot no Render

## Arquivos desta pasta
- `telegram_bot.py`
- `requirements.txt`
- `api/telegram_webhook.py`
- `api/telegram_cron.py`
- `sql/telegram_bot_schema.sql`
- `.env.example`

## Variaveis de ambiente (Render)
Obrigatorias:
- `TELEGRAM_BOT_TOKEN`
- `SUPABASE_URL`
- `SUPABASE_KEY`

Recomendadas:
- `BOT_DEFAULT_USER_ID=1`
- `BOT_DEFAULT_TIMEZONE=America/Sao_Paulo`
- `BOT_AI_ENABLED=true`
- `GEMINI_MODELS=gemini-flash-latest,gemini-2.5-flash,gemini-2.5-pro`
- `TELEGRAM_WEBHOOK_SECRET=<segredo_webhook>`
- `CRON_SECRET=<segredo_cron>`

## 1) Banco (Supabase)
Execute `sql/telegram_bot_schema.sql` no SQL Editor do Supabase.

## 2) Web Service (webhook)
- Runtime: Python
- Build Command: `pip install -r requirements.txt`
- Start Command: `gunicorn api.telegram_webhook:app --bind 0.0.0.0:$PORT`

## 3) Cron Job (ciclo agendado)
Crie um Cron Job no Render:
- Command:
  `curl -sS -X POST "$WEBHOOK_OR_CRON_URL" -H "Authorization: Bearer $CRON_SECRET"`

Obs: `$WEBHOOK_OR_CRON_URL` deve apontar para o endpoint do serviço que roda `api/telegram_cron.py`, caso voce publique esse endpoint como Web Service separado.

Alternativa simples: em vez de endpoint cron, rode um Worker com:
- Build Command: `pip install -r requirements.txt`
- Start Command: `python telegram_bot.py`

