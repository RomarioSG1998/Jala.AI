FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    BOT_AI_ENABLED=true \
    OT_AI_ENABLED=true \
    BOT_AUDIO_STT_PROVIDER=gemini \
    BOT_DEFAULT_TIMEZONE=America/Sao_Paulo \
    BOT_DEFAULT_USER_ID=1 \
    GEMINI_MODELS=gemini-flash-latest,gemini-2.5-flash,gemini-2.5-pro \
    SUPABASE_URL=https://zzrylgsjksrjotgcwavt.supabase.co \
    SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6cnlsZ3Nqa3Nyam90Z2N3YXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4Mjc0OTYsImV4cCI6MjA2NDQwMzQ5Nn0.caBlCmOqKonuxTPacPIHH1FeVZFr8AJKwpz_v1Q3BwM \
    TELEGRAM_BOT_TOKEN=8659979783:AAG7lIs2HSSAEOIgu4Kvmcf8iSt487U1Yvs

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg espeak-ng \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY . /app

# Default command for platforms like Render Docker service.
# docker-compose overrides this command per service.
CMD ["sh", "-c", "gunicorn api.telegram_webhook:app --bind 0.0.0.0:${PORT:-8080} --workers ${WEB_CONCURRENCY:-1} --threads 4 --timeout 120"]
