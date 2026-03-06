# Deploy do bot no Render

## Deploy automatico por push (Render Blueprint)

O repositorio agora tem `render.yaml`. Com isso, voce conecta uma vez e depois cada `git push` faz deploy automatico.

### Arquivos de automacao Render
- `render.yaml` (define servicos e `autoDeploy: true`)
- `api/run_cycle.py` (comando do cron)

### Ativacao (uma vez so)
1. No Render, clique em **New +** -> **Blueprint**.
2. Selecione este repositorio.
3. Confirme criacao dos servicos:
   - `jala-ai-webhook` (Web Service)
   - `jala-ai-cron` (Cron Job)
4. Em ambos, preencha secrets:
   - `TELEGRAM_BOT_TOKEN`
   - `SUPABASE_URL` (formato: `https://<project>.supabase.co`)
   - `SUPABASE_KEY`
   - opcional: `TELEGRAM_WEBHOOK_SECRET`
5. Salve e faça o primeiro deploy.

Depois disso, qualquer push na branch conectada dispara deploy automatico.

## Mapeamento de dados Canvas

Para evitar erro de classificacao de prazo/status, consulte:
- `docs/canvas_task_mapping.md`

## Suporte a audio no Telegram

O bot aceita mensagens de voz/audio e responde com o mesmo contexto de tarefas da semana.

Modo recomendado para chaves free:
- `BOT_AUDIO_STT_PROVIDER=local` (Whisper local no container)
- fallback automatico para Gemini se a transcricao local falhar

Variaveis uteis:
- `BOT_AUDIO_MAX_SECONDS` (padrao 60)
- `BOT_AUDIO_MAX_BYTES` (padrao 8388608)
- `WHISPER_MODEL_SIZE` (padrao `tiny`)
- `WHISPER_COMPUTE_TYPE` (padrao `int8`)
- `BOT_REPLY_AUDIO_ONLY` (padrao `true`, respostas da IA em audio)

## Ambiente 100% Docker (local ou servidor)

### Arquivos Docker adicionados
- `Dockerfile`
- `docker-compose.yml`
- `.dockerignore`
- `.env.example`

### 1) Preparar ambiente
```bash
cp .env.example .env
```
Preencha no `.env` ao menos:
- `TELEGRAM_BOT_TOKEN`
- `SUPABASE_URL`
- `SUPABASE_KEY`

Se quiser proteger endpoints:
- `TELEGRAM_WEBHOOK_SECRET`
- `CRON_SECRET`

### 2) Subir stack Docker (webhook + cron interno)
```bash
docker compose up -d --build
```

Servicos iniciados:
- `webhook` em `http://localhost:${WEBHOOK_PORT:-8080}/`
- `cron_api` em `http://localhost:${CRON_API_PORT:-8081}/`
- `cron_runner` chamando `cron_api` automaticamente a cada `BOT_POLL_SECONDS`

### 3) Logs
```bash
docker compose logs -f webhook cron_api cron_runner
```

### 4) Modo alternativo: polling (sem webhook/cron)
```bash
docker compose --profile polling up -d --build bot_polling
```
Esse modo roda `python telegram_bot.py` dentro do container.

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
