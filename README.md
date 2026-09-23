# Log4tells — FINAL WEB V1

This is the clean **GitHub Pages + Supabase** deployment for `log4tells.com`.

## Upload layout

Upload the CONTENTS of this package folder directly to the ROOT of your GitHub Pages repository:

```text
index.html
app.js
styles.css
supabase-config.js
SUPABASE-SETUP.sql
CNAME
manifest.webmanifest
icon.svg
robots.txt
sitemap.xml
README.md
```

There are no nested source folders in this deployment.

## 1 — Supabase

Open your Log4tells Supabase project → SQL Editor and run `SUPABASE-SETUP.sql`. The script is intentionally re-runnable: it safely replaces the policies created by this package if you already ran an earlier version.

Then get:
- Project URL
- Publishable key (`sb_publishable_...`) from Settings → API Keys

A legacy `anon` key also works, but publishable keys are the current browser-facing key.

## 2 — Configure

Open `supabase-config.js` and replace the two empty strings with your real Supabase values.

Never put a `service_role` or `sb_secret_...` key in a browser file.

## 3 — GitHub Pages

Settings → Pages:
- Deploy from a branch
- `main`
- `/ (root)`

The included `CNAME` preserves `log4tells.com`.

## 4 — What is live

With Supabase configured:
- email/password accounts
- persistent profiles
- publish tells
- follow/unfollow
- reactions
- save context
- feed modes
- feed recipe/preferences
- not-interested feedback
- RLS-protected data

Without Supabase configuration, the site deliberately shows a polished demo feed instead of a broken page.

## 5 — Product rule

**See your social world. Choose how it is ranked. Know why it is here.**

Facebook is an adversarial reference, not a dependency.

## 6 — Current limitation

The first ranking implementation is intentionally transparent and lightweight. It is not a hidden machine-learning system. We establish the user-control contract first, then make ranking more sophisticated later.
