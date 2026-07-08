-- Persist the birthday chosen in Edit Profile. The app's EditProfileNotifier
-- auto-detects this column and saves/loads it; without it the birthday only
-- drove the age field.
alter table public.profiles
  add column if not exists birth_date date;

comment on column public.profiles.birth_date is
  'User date of birth chosen via the Edit Profile birthday picker.';
