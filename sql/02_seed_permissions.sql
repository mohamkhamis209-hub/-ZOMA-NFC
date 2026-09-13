-- =========================================================
-- ZOMA PERMISSIONS SEED
-- IMPORTANT: admin_id is taken from public.admins.id.
-- Do NOT paste the auth user UUID into admin_id.
-- =========================================================
insert into public.admin_permissions
  (admin_id, module, can_view, can_edit)
select
  a.id,
  v.module,
  true,
  true
from public.admins a
cross join (
  values
    ('orders'),
    ('customers'),
    ('cards'),
    ('designs'),
    ('messages'),
    ('admins'),
    ('analytics'),
    ('data')
) as v(module)
where a.user_id='ca51ecfb-fc07-449c-9e11-5c14968fc48a'
on conflict (admin_id,module) do update
set
  can_view=excluded.can_view,
  can_edit=excluded.can_edit;

-- =========================================================
-- END 02_SEED_PERMISSIONS.sql
-- =========================================================
