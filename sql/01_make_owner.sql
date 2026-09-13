-- =========================================================
-- ZOMA OWNER SETUP
-- Run after 00_ZOMA_COMPLETE_SAFE.sql
-- =========================================================
insert into public.admins (user_id, role, is_active)
values (
  'ca51ecfb-fc07-449c-9e11-5c14968fc48a',
  'owner',
  true
)
on conflict (user_id) do update
set role='owner', is_active=true;

-- =========================================================
-- END 01_MAKE_OWNER.sql
-- =========================================================
