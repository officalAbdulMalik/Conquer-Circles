-- Add settings columns to public.profiles
alter table public.profiles
  add column if not exists theme text not null default 'Light',
  add column if not exists units text not null default 'Metric',
  add column if not exists daily_alerts boolean not null default true,
  add column if not exists reminders boolean not null default false;
