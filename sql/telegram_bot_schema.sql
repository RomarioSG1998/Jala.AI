-- Telegram Bot Support Tables
-- Execute in Supabase SQL Editor.

create table if not exists public.bot_config (
  id bigserial primary key,
  id_usuario bigint not null,
  telegram_chat_id text not null unique,
  timezone text not null default 'America/Sao_Paulo',
  daily_enabled boolean not null default true,
  weekly_enabled boolean not null default true,
  urgent_enabled boolean not null default true,
  daily_time time not null default '07:30:00',
  weekly_day smallint not null default 0, -- 0=Monday ... 6=Sunday
  weekly_time time not null default '18:00:00',
  urgency_hours integer not null default 6,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_bot_config_user on public.bot_config (id_usuario);
create index if not exists idx_bot_config_daily_enabled on public.bot_config (daily_enabled);
create index if not exists idx_bot_config_weekly_enabled on public.bot_config (weekly_enabled);
create index if not exists idx_bot_config_urgent_enabled on public.bot_config (urgent_enabled);

create table if not exists public.bot_notifications_log (
  id bigserial primary key,
  telegram_chat_id text not null,
  notification_kind text not null, -- daily | weekly | urgent
  dedupe_key text not null unique,
  payload jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_bot_log_chat_kind on public.bot_notifications_log (telegram_chat_id, notification_kind);
create index if not exists idx_bot_log_created_at on public.bot_notifications_log (created_at desc);

-- Keep updated_at current.
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_bot_config_updated_at on public.bot_config;
create trigger trg_bot_config_updated_at
before update on public.bot_config
for each row execute function public.set_updated_at();
