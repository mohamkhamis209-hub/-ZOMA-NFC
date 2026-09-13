# ZOMA — Complete Vanilla JS + Supabase

ZOMA is an NFC/QR smart-card platform built with plain HTML, CSS and JavaScript.

## Stack
- HTML5
- CSS3
- Vanilla JavaScript modules
- Supabase Auth / Postgres / Storage / RLS
- GitHub Pages compatible
- QRCode.js
- Web NFC where supported

## Setup
1. Run `sql/00_zoma_complete.sql` in Supabase SQL Editor.
2. Create/confirm your owner account in Authentication > Users.
3. Insert the owner row using the SQL shown in `sql/01_make_owner.sql`.
4. Copy `js/config.example.js` to `js/config.js`.
5. Put your Supabase URL and publishable/anon key in `js/config.js`.
6. Open `index.html` locally for a basic smoke test or publish to GitHub Pages.
7. In Supabase Auth URL configuration, add your GitHub Pages site URL to Site URL and Redirect URLs.

## Security
Never put a Supabase service-role key in this repository.
The browser must only use the publishable/anon key.
Admin authorization is checked with RLS and SECURITY DEFINER functions.

## GitHub Pages
The project is static and includes `.nojekyll`.
For project pages, set the site URL in Supabase to the exact GitHub Pages URL.

## Production notes
For phone/Card-ID login, the frontend calls a SECURITY DEFINER RPC that resolves a login identifier to an internal auth email. For high-scale production, move this lookup to an Edge Function with rate limiting and anti-enumeration responses.
