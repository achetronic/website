# AGENTS.md

Guide for AI agents (and humans) working on this repository.

## What this is

Personal website / blog of **achetronic** at <https://achetronic.com>, built
with **Hugo** (extended, ≥ 0.128, pinned to `0.155.3` in CI/Docker) using a
hand-crafted theme (`themes/tty`). Content is in **Spanish**. No npm, no
JS framework, no third-party trackers, no consent banner. The site
ships a single cookieless analytics beacon (Umami) configured in
`hugo.yaml`. It only loads in production builds (so `make serve`
stays clean) and renders nothing if the params are removed.

Stack:

- Hugo extended (static site generator)
- Custom theme `tty` under `themes/tty/`
- Vercel **Geist + Geist Mono** variable fonts served locally
- Plain CSS (CSS custom properties), one progressive-enhancement JS file
- CI/CD: GitHub Actions → GitHub Pages (HTML) + GHCR (multi-arch OCI image)
- Container runtime: `nginx:1.27-alpine` (non-root, port 8080)

## REQUIRED reading before changing visuals or theme

`./design-system.md` (sibling file inside `.agents/`) is the **single
source of truth** for the visual + UX language. If you touch CSS,
layouts, partials, shortcodes or anything that affects how the site
looks/behaves, read it **first** and update it **in the same change**
if you alter:

- The color palette
- Fonts
- The box model (radius, shadow, padding)
- New components
- New external dependencies (JS, fonts, icons)
- Theme toggle, keyboard or focus handling
- Animations / transitions

Hard rules from the design system (do **not** violate without updating
that doc):

- No `border-radius` (square corners, except an explicit `0px` reset)
- No `box-shadow` (the polaroid figure is the only exception)
- No gradients, no `backdrop-filter`, no glass effects
- No emoji, no SVG brand logos, no icon libraries
- No Google Fonts / external CDNs
- Whole site is greyscale; the only chromatic accent is `--hl`,
  reserved exclusively for **string and number literals inside code blocks**
- Font weights restricted to 400 / 500 / 600 (never ≥ 700)
- No `transform: translateY()` on hover (cards/buttons stay still)
- Always solid borders, never dashed
- Never use `|` as inline separator — use `·` or hairlines `--rule`

Full anti-pattern list lives in §12 of the design system doc.

## Commands (Make targets)

`make help` lists everything. Most-used:

| target              | what                                                          |
|---------------------|---------------------------------------------------------------|
| `make check`        | verify Hugo is installed                                      |
| `make install-hugo` | print install instructions for Hugo extended                  |
| `make serve`        | dev server on `:1313` with drafts + live reload (alias `dev`) |
| `make preview`      | dev server, production-like (no drafts, minified)             |
| `make build`        | build into `public/` (drafts included)                        |
| `make build-prod`   | CI-equivalent build (`hugo --gc --minify`, prod environment)  |
| `make new SLUG=foo` | scaffold `content/posts/foo.md` from `archetypes/default.md`  |
| `make clean`        | remove `public/` and `.hugo_build.lock`                       |
| `make clean-all`    | clean + remove `resources/` cache                             |
| `make stats`        | post / draft / word / line counts                             |
| `make lint`         | validate `hugo.yaml` (`hugo config --quiet`)                  |
| `make check-links`  | run `lychee --offline` on built `public/` (if installed)      |
| `make deploy-check` | full prod build, mirrors what CI runs                         |
| `make docker-build` | build OCI image `$(IMAGE):$(TAG)` (default `achetronic/website:local`) |
| `make docker-run`   | build + run image on `:8080`                                  |
| `make docker-push`  | retag and push to `ghcr.io/$(IMAGE):$(TAG)`                   |
| `make open`         | open <http://localhost:1313> in the browser                   |

Useful overrides: `HUGO`, `HUGO_VERSION`, `PORT` (default `1313`),
`BIND` (default `0.0.0.0`), `BASEURL`, `IMAGE`, `TAG`. Example:
`make serve PORT=8080`, `make docker-build IMAGE=mything TAG=v1.2.3`.

There is **no test suite**. "Verifying a change" means: `make lint`,
then `make serve` (visual check) or `make build-prod` (CI-equivalent).

## Repository layout

```
.
├── Makefile                    # all recipes
├── Dockerfile                  # multi-stage: alpine→Hugo build → nginx:1.27-alpine
├── hugo.yaml                   # site config (params, menus, taxonomies, markup, pagination)
├── archetypes/default.md       # template for `hugo new`
├── content/
│   └── posts/                  # blog posts → /posts/<slug>/
│       ├── _index.md           # list page front-matter
│       └── *.md
├── static/                     # served verbatim at /
│   ├── favicon.png             # main favicon (256×256)
│   ├── favicon-dark.png        # white variant for dark color schemes
│   ├── favicon.ico             # legacy multi-size fallback
│   ├── apple-touch-icon.png    # iOS home-screen icon (180×180)
│   └── images/
├── assets/                     # currently empty (project-level Hugo assets)
├── data/                       # currently empty
├── i18n/                       # currently empty
├── layouts/                    # currently empty (project overrides go here)
├── themes/tty/                 # custom theme — see §"Theme structure"
├── resources/_gen/             # Hugo's generated assets cache (gitignored)
├── public/                     # build output (gitignored)
├── .agents/
│   └── design-system.md        # MANDATORY reading for design changes
└── .github/workflows/
    ├── deploy.yml              # GitHub Pages (push to main)
    └── oci.yml                 # multi-arch OCI image to GHCR (push to main + tags v*)
```

The top-level `assets/`, `data/`, `i18n/`, `layouts/` directories exist
but are **empty**. They are reserved for project-level overrides of the
theme. New layouts/partials should normally go inside the theme
(`themes/tty/layouts/...`); only override at the project level if you
need to diverge from the theme without forking it.

## Theme structure (`themes/tty/`)

```
themes/tty/
├── theme.toml
├── archetypes/                  # theme-level archetypes (the project archetype takes precedence)
├── assets/
│   ├── css/
│   │   ├── main.css             # all design tokens + components (single source)
│   │   └── syntax.css           # chroma syntax-highlight palette
│   └── js/
│       └── terminal.js          # progressive enhancements (see below)
├── static/
│   └── fonts/
│       ├── Geist-Variable.woff2
│       └── GeistMono-Variable.woff2
└── layouts/
    ├── 404.html
    ├── index.html               # home (hero + social link grid)
    ├── _default/
    │   ├── baseof.html          # html shell, body classes, reading-progress, skip-link
    │   ├── list.html            # /posts/, /tags/, /tags/<term>/
    │   ├── single.html          # /posts/<slug>/
    │   └── _markup/
    │       ├── render-heading.html      # adds `#` anchor link to every heading
    │       └── render-codeblock.html    # wraps chroma in <div class="codeblock" data-lang="…">
    ├── partials/
    │   ├── head.html            # meta, favicon variants, font preload, theme bootstrap, fingerprinted CSS
    │   ├── header.html          # topbar (brand mark + nav + theme toggle)
    │   ├── footer.html          # bottom bar (copyright + RSS link)
    │   ├── analytics.html       # optional Umami beacon, prod-only, opt-in
    │   └── scripts.html
    └── shortcodes/
        └── callout.html         # {{< callout type="warning" title="…" >}}…{{< /callout >}}
```

`terminal.js` (despite the name, no fake-terminal effects) wires:

- `setupReadingProgress()` — scroll-driven 1px fixed bar (only on post single)
- `setupCodeCopy()` — injects a `copy` button into every `.codeblock`
- `setupThemeToggle()` — flips `<html data-theme>` between `dark`/`light`,
  persists to `localStorage` under key `theme`
- `setupLightbox()` — click-to-zoom on post images (Esc / click-outside to close)
- `using-keyboard` class on `<html>` for focus rings on Tab only

JS is **enhancement-only**. Content must remain fully readable without it.

## Body-class & layout-width contract

`baseof.html` sets a body class based on page kind:

| body class      | url(s)                                        | column    |
|-----------------|-----------------------------------------------|-----------|
| `page-home`     | `/`                                           | wide 760  |
| `page-posts`    | `/posts/`, `/posts/<slug>/`, `/tags/`, `/tags/<x>/` | wide 760 |
| `page-default`  | everything else                               | 600       |

These are consumed by `main.css`. Don't change them without coordinating
with the design-system doc.

## Writing a post

```bash
make new SLUG=mi-articulo
```

This creates `content/posts/mi-articulo.md` from
`archetypes/default.md` with front-matter:

```yaml
---
title: "Mi Articulo"
date: <auto>
draft: true
description: ""
tags: []
categories: []
---
```

While `draft: true`, the post is only visible under `make serve`
(`--buildDrafts`). For production, set `draft: false`.

Commonly used front-matter keys: `title`, `slug`, `date`, `lastmod`,
`draft`, `description`, `tags`, `categories`, `series`, `canonical`
(for posts originally published elsewhere — preserve original `date`
and add `canonical` URL).

Available shortcodes:

```markdown
{{</* callout type="warning" title="Heads up" */>}}
This block stands out.
{{</* /callout */>}}
```

`callout` types: `info` (default), `tip`, `warning`, `danger`.

## Conventions and gotchas

- **Language**: UI strings, comments and content are **Spanish**.
  Capitalization rules for UI labels live in §3.5 of the design-system
  doc (`Inicio`, `Publicaciones`, `Anterior`, `Siguiente`,
  `Filtrar por etiqueta`, `Publicación · YYYY`, `Saltar al contenido`,
  etc.). Tags and table headers are **lowercase**. Pills (`PUBLICACIÓN`,
  `BASH`, `<th>`, `<mark>`) are **UPPERCASE** with letterspacing.
- **Slugs are ASCII-only** (no accents). E.g. `mi-extraño-arranque-dual`
  → `mi-extrano-arranque-dual`.
- **CSS is fingerprinted** in `head.html` via
  `resources.Get | resources.Minify | resources.Fingerprint` and ships
  with SRI integrity hashes. Don't add stylesheets via raw `<link>`
  — go through Hugo's resource pipeline.
- **Fonts are preloaded** in `<head>` with `crossorigin` to avoid FOUT.
  If you add a font, preload it the same way (and update the design-system doc).
- **Theme toggle bootstraps before first paint** via an inline blocking
  script in `head.html`. This is intentional — moving it breaks
  no-flash dark/light. Storage key is `theme`; values are `light` /
  `dark`. **Default is `light`**; the bootstrap only switches to `dark`
  if `prefers-color-scheme: dark` matches and the user has not chosen
  a theme yet.
- **Code blocks** are wrapped by `render-codeblock.html` into
  `<div class="codeblock" data-lang="BASH">…</div>`. The language
  pill (`BASH`, `GO`, `YAML`…) is rendered via CSS `::before` on
  `[data-lang]`. Line numbers are disabled in `hugo.yaml`
  (`lineNos: false`) — don't enable them.
- **Markup `unsafe: true`** is set in `hugo.yaml` so raw HTML in
  Markdown is allowed. Don't paste untrusted HTML into posts.
- **Page title in the browser tab** is hardcoded to `Achetronic` in
  `head.html` (no `Title :: Site` pattern). `og:title` and meta tags
  still use the per-page title for SEO and social previews.
- **Brand mark** (small head-only logo) sits at the top-left of the
  topbar on every page **except** `/` (where the big `hero-logo` is
  already present). The PNG (`static/images/achetronic-mark.png`) is
  black; in dark mode `.brand-mark` is `filter: invert(1)` to flip it
  to white.
- **Pagination** is built-in Hugo. `pagination.pagerSize: 10` in
  `hugo.yaml`. The list template (`_default/list.html`) uses
  `.Paginate $allPages` and renders a `<nav class="pager">` below the
  grid when there is more than one page. Post numbering is preserved
  across pages (post `01` stays `01` on page 2).
- **Favicon** is served as multiple PNG / ICO variants under `static/`
  (`favicon.png`, `favicon-dark.png`, `favicon.ico`,
  `apple-touch-icon.png`). The dark variant is wired with
  `media="(prefers-color-scheme: dark)"` so browser tabs flip with the
  OS scheme, not with our `data-theme`. Regenerate them with the
  small Pillow snippet in git history if the head logo changes.
- **RSS link** lives in the footer (`footer.html`) as a small text +
  Unicode glyph. It points to `/index.xml` (Hugo's default site feed).
  Don't replace the glyph with an SVG icon — see design-system
  anti-patterns.
- **Analytics** ships a single optional beacon partial
  (`themes/tty/layouts/partials/analytics.html`). Currently wires
  Umami via `params.umamiWebsiteId` + `params.umamiSrc`. The partial
  only renders in `hugo.Environment "production"` **and** when both
  params are set. `make serve` and dev builds never load it. To swap
  provider, edit the partial; to disable, remove the params from
  `hugo.yaml`.
- **Imported posts** (e.g. from Medium): preserve original `date`,
  add `canonical`, download images locally to
  `static/images/posts/<slug>/`, ASCII-only slug. See §14 of the
  design-system doc.
- **Single responsive breakpoint** at `600px`. Don't add new
  breakpoints without justification.
- **Empty top-level dirs** (`assets/`, `data/`, `i18n/`, `layouts/`)
  are not a mistake — they're reserved for project-level overrides.

## Build/deploy gotchas

- CI installs Hugo extended `0.155.3` (from `HUGO_VERSION` env in
  `.github/workflows/deploy.yml` and as `ARG HUGO_VERSION` in
  `Dockerfile`). If you bump it, bump it in **all three** places
  (`Makefile`, `deploy.yml`, `Dockerfile`).
- `make deploy-check` runs the **same** build CI runs — use it before
  pushing big changes.
- `deploy.yml` uses `actions/configure-pages@v5` and passes its
  `base_url` to Hugo via `--baseURL`. Don't hardcode `baseURL` for
  CI builds.
- `oci.yml` builds multi-arch (`linux/amd64`, `linux/arm64`) with
  QEMU + Buildx, generates **SBOM + provenance**, and **signs with
  cosign keyless (OIDC)**. Don't disable signing/attestation without
  a reason.
- The Dockerfile bakes an inline nginx config into the runtime image
  via a `cat > /etc/nginx/conf.d/default.conf <<'EOF'` heredoc. If
  you need to change cache headers / security headers / gzip rules,
  edit it there. The image runs as user `nginx` (uid 101) on port
  **8080** (not 80).
- `.dockerignore` is in place; build artifacts (`public/`,
  `resources/_gen/`, `.hugo_build.lock`) are gitignored.

## Analytics

The site ships a single cookieless beacon (Umami). It is configured
from `hugo.yaml`:

```yaml
params:
  umamiWebsiteId: "<id>"
  umamiSrc: "https://your-umami-host/script.js"
```

Rules:

- The partial only renders in `hugo.Environment "production"` builds
  (so dev never leaks pings).
- Both values are public by design (the snippet runs in the visitor's
  browser). Safe to commit.
- Umami is cookieless, no PII, no consent banner needed under RGPD.
- To disable for an environment, drop the params (or override them in
  a `config/<env>/params.yaml` file).
- To swap provider, edit
  `themes/tty/layouts/partials/analytics.html`. Keep the partial small
  and the env guard intact.

## When in doubt

1. Look for a similar component already in `themes/tty/layouts/` or
   `main.css`; match its structure.
2. Re-read the relevant section of `.agents/design-system.md`.
3. Run `make serve` and check both `dark` and `light` themes (toggle
   in topbar). Check both desktop (`> 600px`) and mobile (`≤ 600px`).
4. Run `make build-prod` and skim `public/` for surprises.

## License

Code: MIT (`LICENSE`). Content: CC BY-NC-SA 4.0 unless a post overrides it.
