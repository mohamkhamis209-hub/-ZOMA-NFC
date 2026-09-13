# ZOMA — Latest GitHub Pages Build

## 1) Database first
Run these in Supabase SQL Editor, in order:
1. `sql/00_zoma_complete_safe.sql`
2. `sql/01_make_owner.sql`
3. `sql/02_seed_permissions.sql`

The latest permission RPC uses the parameter names `requested_module` and `requested_action`.
Do NOT run `DROP FUNCTION ... CASCADE` for this function.

## 2) Frontend
Upload the contents of this folder to the root of the GitHub Pages repository. Keep `.nojekyll`.

`js/config.js` already contains the project URL and publishable/anon key. Never put a Supabase service_role key in the frontend.

## 3) Pages
Customer: index, register, login, dashboard, designs, order, card.
Admin: admin/index, orders, customers, cards, designs, messages, admins, analytics, data.

## 4) Core behavior
- Customer login supports email, phone, and Card ID.
- Confirming an order creates a Card ID and public slug through the database RPC.
- Card URL is the same URL used for QR/NFC.
- Admin can suspend/reactivate/replace cards and write NFC when Web NFC is available.
