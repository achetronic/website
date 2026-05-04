# achetronic blog · design system

> Single source of truth for the visual and UX language of the blog.
> Any agent (human or AI) working on the codebase **must** follow these
> rules. If you change the design, **update this file in the same change**.
>
> This document describes the **current state** of the blog after multiple
> design iterations. Earlier explorations (terminal-emulator look, tmux
> status bars, ASCII art) have been intentionally discarded.

---

## 1. Philosophy

Three rules, in priority order:

1. **Sober before flashy.** This is a reading site, not a marketing landing.
   If a decoration does not improve readability or hierarchy, remove it.
2. **Square before rounded.** No `border-radius` anywhere (except a `0px`
   declaration where overriding a default). Boxes are boxes.
3. **Volumetric coherence.** Every "content block" (card, code block, table,
   post header, post nav, callout, filter, footnote block) uses the **same
   primitive**: 1px border `--rule`, transparent background, generous
   padding, subtle hover with `--bg-1`.

The blog must **not** look like:

- A SaaS product landing (rounded cards, gradients, glow shadows).
- A macOS-style window theme (window controls, blur, glass effect).
- An emulated terminal (ASCII art, tmux bars, blinking cursors,
  fake shell prompts). This phase was deliberately abandoned.
- A tutorial blog full of icons, badges and emoji.

Two important exceptions to the "square + flat" rule are deliberately
allowed because they read as **physical objects**, not UI:

- **Polaroid figures** — see §6.10. Soft drop shadow allowed.
- **Inverted pills** (`PUBLICACIÓN · 2025`, `BASH`, `<th>` headers,
  `<mark>`) — white background with dark text, sharp corners.

---

## 2. Color palette

CSS custom properties defined at the top of `themes/tty/assets/css/main.css`.

### 2.1 Light theme (default)

```css
:root,
:root[data-theme="light"] {
  --bg:        #f4f4f4;
  --bg-1:      #ececec;
  --bg-2:      #e2e2e2;
  --rule:      #d8d8d8;
  --rule-2:    #c2c2c2;

  --fg:        #0a0a0a;
  --fg-2:      #2a2a2a;
  --fg-3:      #555555;
  --fg-4:      #888888;
  --fg-5:      #b0b0b0;

  --hl:        #4a6b00;   /* unique color accent — strings & numbers in code only */
}
```

### 2.2 Dark theme (toggle)

```css
:root[data-theme="dark"] {
  --bg:        #0a0a0a;
  --bg-1:      #131313;
  --bg-2:      #1a1a1a;
  --rule:      #1f1f1f;
  --rule-2:    #2a2a2a;

  --fg:        #f0f0f0;
  --fg-2:      #c8c8c8;
  --fg-3:      #888888;
  --fg-4:      #555555;
  --fg-5:      #333333;

  --hl:        #c5d96a;
}
```

The achetronic logo PNG is black on transparent. In **light** mode it
renders as-is. In **dark** mode the small `.brand-mark` head in the
topbar is inverted via `filter: invert(1)` so it reads white on the
dark background. The big `.hero-logo` on the home stays black; if
you ever need to invert it for dark mode, add it under the same
`:root[data-theme="dark"]` selector group.

```css
:root[data-theme="dark"] .brand-mark { filter: invert(1); }
```

### 2.3 Color rule

The whole site is painted with greys. The only chromatic accent
permitted is `--hl`, reserved exclusively for **string and number
literals inside code blocks**. Nothing else uses it.

---

## 3. Typography

**Vercel's Geist + Geist Mono variable fonts**, served locally from
`themes/tty/static/fonts/`. No Google Fonts, no CDN.

```css
@font-face {
  font-family: "Geist";
  font-weight: 100 900;
  font-display: swap;
  src: url("/fonts/Geist-Variable.woff2") format("woff2-variations"),
       url("/fonts/Geist-Variable.woff2") format("woff2");
}
@font-face {
  font-family: "Geist Mono";
  font-weight: 100 900;
  font-display: swap;
  src: url("/fonts/GeistMono-Variable.woff2") format("woff2-variations"),
       url("/fonts/GeistMono-Variable.woff2") format("woff2");
}
```

Both are **preloaded** in `<head>` to avoid FOUT:

```html
<link rel="preload" href="/fonts/Geist-Variable.woff2" as="font"
      type="font/woff2" crossorigin>
<link rel="preload" href="/fonts/GeistMono-Variable.woff2" as="font"
      type="font/woff2" crossorigin>
```

CSS variables:

```css
--sans:  "Geist", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont,
         "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
--mono:  "Geist Mono", ui-monospace, "JetBrains Mono", "SF Mono", Menlo,
         Consolas, "DejaVu Sans Mono", monospace;
--serif: ui-serif, Georgia, "Iowan Old Style", "Palatino Linotype",
         Palatino, serif;
```

`body` activates Geist's stylistic alternates:

```css
font-feature-settings: "ss01", "ss03", "cv11";
```

### 3.1 Font usage matrix

| family | usage                                                              |
| ------ | ------------------------------------------------------------------ |
| sans   | body text, headings, navigation, descriptions, captions            |
| mono   | code, dates, meta (reading time, words), tags, pills, post-num, footnotes |
| serif  | **only blockquotes** inside posts (italic)                         |

### 3.2 Weights

Allowed: `400` (regular), `500` (medium), `600` (semibold).
**Never use `700` or higher.**

### 3.3 Type scale (canonical sizes)

| element                       | size     | weight | letter-spacing |
| ----------------------------- | -------- | ------ | -------------- |
| body                          | 16px     | 400    | 0              |
| brand (topbar)                | 0.95rem  | 600    | -0.005em       |
| topnav-link                   | 0.9rem   | 400    | 0              |
| post-title (single)           | 1.85rem  | 600    | -0.022em       |
| page-title (lists)            | 1.6rem   | 600    | -0.018em       |
| post-card-title (in list)     | 1.1rem   | 600    | -0.01em        |
| post-content h1               | 1.4rem   | 600    | -0.012em       |
| post-content h2               | 1.2rem   | 600    | -0.012em       |
| post-content h3               | 1.05rem  | 600    | -0.012em       |
| post-content h4               | 0.78rem  | 600    | 0.1em (UPPER)  |
| post-content h5               | 0.82rem  | 600    | 0.08em (UPPER) |
| post-content h6               | 0.78rem  | 500    | 0.1em (UPPER)  |
| meta / date / mono labels     | 0.75rem  | 400    | 0              |
| pill labels (`PUBLICACIÓN`)   | 0.65–0.7rem | 600  | 0.08–0.12em    |

### 3.4 Line heights

- body: **1.7**
- post-content: **1.65**
- titles: **1.18 – 1.35**
- mono / code / dates: **1.6 – 1.75**

### 3.5 Capitalization rules (Spanish UI)

- Menu names and section titles: **Capitalized** (`Inicio`,
  `Publicaciones`, `Filtrar por etiqueta`, `Anterior`, `Siguiente`,
  `Publicación · 2025`, `Saltar al contenido`, `Cambiar tema`,
  `Copiar al portapapeles`).
- Tags and link names in cards: **lowercase** (`github`, `youtube`).
  Tags carry a `#` prefix added via CSS pseudo-element.
- Table headers: **lowercase** (`ns · aísla · flag`).
- Taxonomy term titles in URL: **lowercase with `#`** prefix
  (`#linux`, `#sre`).
- Pills (white-on-dark badges): **UPPERCASE** with letterspacing
  (`PUBLICACIÓN`, `BASH`, `GO`, `YAML`).
- Post-num in card list: **two-digit zero-padded** (`01`, `02`, `03`)
  in mono `--fg-4`.

---

## 4. Layout

```css
--maxw:      600px;   /* default column (post single, narrow lists) */
--maxw-wide: 760px;   /* home, /posts/, /tags/, /tags/<x>/ */
--gutter:    1.75rem; /* horizontal padding for all containers */
```

Body class (set in `themes/tty/layouts/_default/baseof.html`):

```go
{{ if .IsHome }}page-home
{{ else if eq .Section "posts" }}page-posts
{{ else if or (eq .Kind "taxonomy") (eq .Kind "term") }}page-posts
{{ else }}page-default{{ end }}
```

| body class      | url                                  | maxw      |
| --------------- | ------------------------------------ | --------- |
| `page-home`     | `/`                                  | wide 760  |
| `page-posts`    | `/posts/`, `/posts/<slug>/`, `/tags/`, `/tags/<x>/` | wide 760  |
| `page-default`  | everything else                      | 600       |

`.content`, `.topbar-inner` and `.bottom-inner` share the same
`max-width` so everything aligns to the same column.

Vertical padding of the main column:

- `page-default`: `5rem 7rem` (top / bottom)
- `page-home`, `page-posts`: `7rem 9rem`

Topbar `padding: 2.25rem var(--gutter) 1.25rem`. Footer `padding:
2.5rem var(--gutter) 4rem`.

---

## 5. Box system (the universal rule)

> **Every content block is built the same way.**

Canonical "box" definition:

```css
.box {
  border: 1px solid var(--rule);
  background: transparent;
  padding: 1.85rem 1.85rem 1.65rem;
  /* never: border-radius, box-shadow, gradient, filter, transform */
}
.box:hover {
  background: var(--bg-1);
  /* never: translateY, scale (except on figures and link/post arrows) */
}
```

Components that follow this primitive:

| component            | class             | padding                    | hover  |
| -------------------- | ----------------- | -------------------------- | ------ |
| Link card (home)     | `.link-card`      | `1.85rem 1.85rem 1.75rem`  | `bg-1` |
| Post card (list)     | `.post-card`      | `1.85rem 1.85rem 1.65rem`  | `bg-1` |
| Post header (single) | `.post-head`      | `2.5rem 1.85rem 1.75rem`   | —      |
| Post nav cell        | `.post-nav-card`  | `1.4rem 1.6rem`            | `bg-1` |
| Code block wrapper   | `.codeblock`      | `1.6rem 1.8rem` (on `pre`) | —      |
| Table                | `table`           | cells `0.85rem 1.2rem`     | —      |
| Filter (collapsible) | `.filter`         | `0.65rem 0.9rem` (summary) | —      |
| Aside                | `aside`           | `1rem 1.25rem`             | —      |
| Callout              | `.callout`        | `0.8rem 1rem`              | —      |
| Footnote-ref         | `.footnote-ref`   | `0 0.25rem`                | —      |

### 5.1 Border styles

- **Single box** (post head, code block, table, filter, aside, callout):
  `border: 1px solid var(--rule)` all around.
- **Adjacent cells in a grid** (link-grid on home, post-nav, post-grid):
  one outer border on the container, plus `border-right` and/or
  `border-bottom` on each cell. Last cell drops the relevant border.

```css
.link-grid { border: 1px solid var(--rule); }
.link-card {
  border-right:  1px solid var(--rule);
  border-bottom: 1px solid var(--rule);
}
.link-card:last-child { border-right: none; }
```

### 5.2 Internal hairlines

When separating sub-areas inside a single box (for example
`post-foot`'s `·` separators, `post-nav` cell separator), use **the
same color `--rule`**. Never a darker or lighter shade.

---

## 6. Components

### 6.1 Topbar

```html
<header class="topbar">
  <div class="topbar-inner">
    <a href="/" class="brand" aria-label="achetronic — inicio">
      <img src="/images/achetronic-mark.png"
           alt="" class="brand-mark" aria-hidden="true">
    </a>
    <nav class="topnav">
      <a class="topnav-link active">Inicio</a>
      <a class="topnav-link">Publicaciones</a>
      <button class="theme-toggle" aria-label="Cambiar tema">
        <span class="theme-toggle-icon"></span>
      </button>
    </nav>
  </div>
</header>
```

Rules:

- **No** `position: sticky`, no `backdrop-filter`, no `box-shadow`.
- **No** `border-bottom`. Separation from content is done via vertical
  padding on `.topbar-inner` (`2.25rem` top / `1.25rem` bottom).
- `.brand` itself has no text — it wraps the small head-only logo
  (`.brand-mark`, the head crop of the logo, ~2.4rem tall).
  - In **light** mode the PNG renders black on the bg.
  - In **dark** mode it is inverted via `filter: invert(1)`.
  - On the **home** (`page-home`), the brand mark is hidden because
    the big `.hero-logo` is already present (`display: none`).
- `.topnav-link` color `--fg-3`, `.active` is `--fg`. Hover: `--fg`.
  **No underline** in topbar.
- Topbar inner inherits the page max-width (so it visually aligns
  to the body column).

### 6.2 Theme toggle

Square button at the end of the topnav. Icon is half-filled rectangle
(yin-yang abstraction), 0.7rem, drawn with `linear-gradient`:

```css
.theme-toggle {
  width: 1.6rem;
  height: 1.6rem;
  border: 1px solid var(--rule-2);
  background: transparent;
  /* no radius */
}
.theme-toggle-icon {
  width: 0.7rem;
  height: 0.7rem;
  border: 1px solid currentColor;
  background: linear-gradient(to right, currentColor 50%, transparent 50%);
}
```

Logic in `themes/tty/assets/js/terminal.js` (`setupThemeToggle`):

1. On click → flip `data-theme` between `dark` and `light` on `<html>`.
2. Save the choice in `localStorage` under key `theme`.
3. An inline script in `<head>` reads `localStorage` (or
   `prefers-color-scheme` as fallback) **before first paint** to avoid
   flash. See `themes/tty/layouts/partials/head.html`.

### 6.3 Hero (home only)

```html
<section class="hero">
  <img class="hero-logo" ...>
  <p class="hero-tagline">...</p>
  <div class="hero-actions">
    <a class="btn btn-primary" href="/posts/">leer publicaciones →</a>
  </div>
</section>
```

- Logo **centered**, max-width `380px`, in dark mode
  `filter: invert(1) brightness(0.95)`.
- Spacing: logo → tagline = `3rem`, tagline → actions = `3.5rem`,
  hero → next section = `7rem`.

### 6.4 Buttons

```css
.btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.85rem 1.6rem;
  border: 1px solid var(--rule-2);
  /* no border-radius */
}
.btn-primary { background: var(--fg); color: var(--bg); border-color: var(--fg); }
.btn-primary:hover { background: transparent; color: var(--fg); }
.btn-ghost   { color: var(--fg-2); }
.btn-ghost:hover { color: var(--fg); border-color: var(--fg); }
```

Rules: square. Primary inverts on hover. **No** `transform`, **no**
`box-shadow`.

### 6.5 Link cards (home)

```html
<a class="link-card" href="...">
  <span class="link-card-name">github</span>
  <span class="link-card-url">github.com/achetronic</span>
  <span class="link-card-arrow">
    <svg class="link-card-square" viewBox="0 0 100 100">
      <rect x="3" y="3" width="94" height="94"
            fill="none" stroke="currentColor"
            stroke-width="1.5" stroke-linecap="round"
            stroke-linejoin="round"
            vector-effect="non-scaling-stroke"
            pathLength="100"/>
    </svg>
    <span class="link-card-arrow-glyph">↗</span>
  </span>
</a>
```

- Grid `repeat(auto-fit, minmax(240px, 1fr))`, **no gap** (hairlines
  separate cards inside a single outer border).
- Padding `1.85rem 1.85rem 1.75rem`.
- Hover: bg `--bg-1`, name → `--fg`, url → `--fg-2`, **square ring
  draws around the arrow** (see §7).
- URLs cleaned by Hugo regex `^(https?://(www\.)?|mailto:)` to hide
  scheme.

### 6.6 Post grid / cards (`/posts/`, `/tags/`)

```html
<a class="post-card" href="...">
  <span class="post-card-num">03</span>
  <h2 class="post-card-title">Title</h2>
  <p class="post-card-desc">Description</p>
  <div class="post-card-foot">
    <time class="post-card-date">02 oct 2025</time>
    <ul class="post-card-tags"><li>#linux</li><li>#sre</li></ul>
  </div>
  <span class="post-card-arrow">
    <svg class="post-card-square" viewBox="0 0 100 100">…rect…</svg>
    <span class="post-card-arrow-glyph">→</span>
  </span>
</a>
```

- Cards stacked vertically inside `.post-grid` with shared border.
- **Descending numeric counter** (`03`, `02`, `01`) in mono `--fg-4`.
  Highlights to `--fg-2` on hover.
- Title weight 600 1.1rem.
- Footer line: date in mono `--fg-4` (`02 oct 2025`, lowercase, no
  comma) followed by tags in mono `--fg-3` (no chips, no border, just
  `#linux #sre` separated by spaces).
- Hover: bg `--bg-1`, title underlined, **square ring draws around
  the `→` arrow** (see §7).

### 6.7 Post single — header

```html
<header class="post-head">
  <span class="post-num">Publicación · 2025</span>
  <h1 class="post-title">Title</h1>
  <p class="post-desc">Description</p>
  <div class="post-foot">
    <time class="post-date">02 oct 2025</time>
    <span class="post-foot-sep">·</span>
    <span>2 min</span>
    <span class="post-foot-sep">·</span>
    <span>387 palabras</span>
    <span class="post-foot-sep">·</span>
    <ul class="post-tags"><li><a>#linux</a></li>...</ul>
  </div>
</header>
```

- Box (1px border `--rule`).
- **`.post-num` is an inverted pill**: positioned `top: 0`,
  `transform: translateY(-50%)` (sits over the top border), background
  `--fg`, color `--bg`, mono uppercase, letterspacing `0.08em`.
  Format: `Publicación · YYYY`.
- Title 1.85rem.
- post-foot: single mono line with date · reading time · words ·
  tags, separated by `·` of color `--rule-2`.

### 6.8 Post content typography

```css
.post-content {
  font-size: 1rem;
  line-height: 1.65;
  color: var(--fg-2);
}
.post-content > * + * { margin-top: 1.65rem; }
.post-content p { margin: 0; }
```

Rules:

- Top margin between consecutive elements: `1.65rem`.
- Headings: `margin-top: 3.5rem`, `margin-bottom: 1.1rem`.
- Lists: `padding-left: 1.5rem`, `<li>` `margin: 0.55rem 0`,
  list markers in `--fg` (white).
- `<strong>` and `<em>` in `--fg`.
- Inline links: `color: --fg`, `underline` with
  `text-decoration-color: --fg-4`. Hover bumps to `--fg`.

### 6.9 Headings with anchors

Hugo render hook in
`themes/tty/layouts/_default/_markup/render-heading.html`:

```html
<h2 id="..." class="content-heading">
  <a class="heading-anchor" href="#...">#</a>
  Heading text
</h2>
```

CSS:

```css
.heading-anchor {
  position: absolute;
  left: -1.6rem;
  width: 1.4rem;
  font-family: var(--mono);
  color: var(--fg-4);
  opacity: 0;
}
.content-heading:hover .heading-anchor,
.heading-anchor:focus { opacity: 1; }
.heading-anchor:hover { color: var(--fg); }
@media (max-width: 720px) { .heading-anchor { display: none; } }
```

Hidden by default, appears on heading hover. Hidden on mobile.

### 6.10 Figures (two modes)

Selected via `:has()` (modern browsers, supported since 2022):

**With `figcaption`** — polaroid (bottom margin thicker for
handwritten-style caption area):

```css
.post-content figure:has(figcaption) {
  padding: 0.9rem 0.9rem 0;  /* no padding-bottom; figcaption fills it */
}
.post-content figure > figcaption {
  padding: 0.9rem 0.4rem 1.4rem;
  background: var(--fg);
  color: var(--bg-2);
  text-align: center;
  font-size: 0.92rem;
}
```

**Without `figcaption`** — plain photo with even white frame:

```css
.post-content figure {
  padding: 0.7rem;       /* uniform on all 4 sides */
  background: var(--fg);
  width: fit-content;
  max-width: 100%;
  box-shadow: 0 8px 24px -10px rgba(0,0,0,0.6),
              0 2px 6px rgba(0,0,0,0.3);
}
.post-content figure:hover { transform: scale(1.015); }
```

This is the **only place** `box-shadow` is used and the **only place**
`transform: scale()` is used (apart from arrow micro-interactions).
It is justified because the polaroid is deliberately a "physical
object" sitting on the page.

### 6.11 Inline code & code blocks

**Inline:**

```css
.post-content code {
  background: var(--bg-1);
  padding: 0.05rem 0.4rem;
  font-size: 0.86em;
  color: var(--fg);             /* not --hl: keeps it readable as text */
  border: 1px solid var(--rule);
}
```

**Block** — uses a Hugo render hook in
`themes/tty/layouts/_default/_markup/render-codeblock.html` that wraps
chroma's output in `<div class="codeblock" data-lang="BASH">`.

```css
.post-content .codeblock {
  position: relative;
  border: 1px solid var(--rule);
  background: transparent;
}
/* inverted pill with the language name (BASH, GO, YAML, JSON…) */
.post-content .codeblock[data-lang]::before {
  content: attr(data-lang);
  position: absolute;
  top: 0;
  left: 1.25rem;
  transform: translateY(-50%);
  padding: 0.2rem 0.6rem;
  background: var(--fg);
  color: var(--bg);
  font-family: var(--mono);
  font-size: 0.65rem;
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}
.post-content .codeblock pre {
  background: transparent !important;
  border: none !important;
  padding: 1.6rem 1.8rem !important;
  font-size: 0.85rem;
  line-height: 1.75;
}
```

Line numbers are **disabled** in `hugo.yaml` (`lineNos: false`).

### 6.12 Syntax highlighting palette

Defined in `themes/tty/assets/css/syntax.css`. Reduced to **5 levels of
grey + 1 unique accent (`--hl`)** for string and number literals.

```css
.chroma .k, .chroma .kc, .chroma .kt   { color: var(--fg);  weight: 500; }
.chroma .s, .chroma .s1, .chroma .s2   { color: var(--hl);  }
.chroma .mi, .chroma .mf, .chroma .mh  { color: var(--hl);  }
.chroma .nf, .chroma .fm, .chroma .nb  { color: var(--fg);  }
.chroma .c, .chroma .cm, .chroma .c1   { color: var(--fg-4); italic; }
.chroma .o, .chroma .ow                { color: var(--fg-3); }
.chroma .nv, .chroma .nx, .chroma .nn  { color: var(--fg-2); }
.chroma .nt                            { color: var(--fg);  }
.chroma .err                           { color: var(--fg);  bg subtle }
```

No yellow / orange / magenta / cyan accents allowed.

### 6.13 Tables

```css
.post-content table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid var(--rule);
}
.post-content th,
.post-content td {
  padding: 0.85rem 1.2rem;
  border-bottom: 1px solid var(--rule);
}
.post-content thead { background: var(--fg); }
.post-content th {
  color: var(--bg);
  background: var(--fg);
  font-family: var(--mono);
  font-weight: 600;
  font-size: 0.7rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}
```

`<thead>` is an inverted band — the same pill language used in
`PUBLICACIÓN · 2025` and code-block language labels, but stretched
across the row. `<code>` inside `<th>` gets darker translucent
background to remain readable.

### 6.14 Tags

```css
.tag {
  font-family: var(--mono);
  font-size: 0.75rem;
  color: var(--fg-3);
  text-decoration: none;
}
.tag::before { content: "#"; color: var(--fg-5); }
.tag:hover { color: var(--fg); }
```

No border, no background, no chips. Tags are mono text. The `#` is
added via pseudo-element.

### 6.15 Filter (collapsible on `/posts/`)

```html
<details class="filter">
  <summary class="filter-summary">
    <span class="filter-toggle"></span>
    <span class="filter-label">Filtrar por etiqueta</span>
    <span class="filter-count">9</span>
  </summary>
  <div class="filter-body">
    <ul class="tag-cloud">…</ul>
  </div>
</details>
```

- Square 1px box.
- `+` (closed) / `−` (open) in mono. Shown only on `/posts/` (hidden
  on `/tags/<term>/`).
- Body has `border-top` hairline when open.

### 6.16 Post nav (prev / next)

```html
<nav class="post-nav">
  <div class="post-nav-cell">
    <a class="post-nav-card">
      <span class="post-nav-label">← Anterior</span>
      <span class="post-nav-title">Title</span>
    </a>
  </div>
  <div class="post-nav-cell right">
    <a class="post-nav-card">
      <span class="post-nav-label">Siguiente →</span>
      <span class="post-nav-title">Title</span>
    </a>
  </div>
</nav>
```

- Grid `1fr 1fr`, no gap, single outer border.
- Right cell has `border-left: 1px solid --rule`. On mobile collapses
  to `border-top`.
- Hover: bg `--bg-1`, title underlined, **vertical white marker
  appears** — left side on the left cell, right side on the right
  cell (reinforces direction of travel). See §7.

### 6.17 Footer

```html
<footer class="bottom">
  <div class="bottom-inner">
    <div class="bottom-left">
      <span>achetronic</span>
      <span class="bottom-meta">— © 2025</span>
    </div>
    <div class="bottom-right">
      <a class="bottom-rss" href="/index.xml"
         rel="alternate" type="application/rss+xml">
        <span class="bottom-rss-icon" aria-hidden="true">◉</span>
        <span class="bottom-rss-label">RSS</span>
      </a>
    </div>
  </div>
</footer>
```

Two-column row:

- **Left**: `achetronic — © YYYY`.
- **Right**: small RSS link pointing to `/index.xml`. The icon is the
  Unicode glyph `◉` (no SVG/icon font), in mono, color `--fg-4`,
  hover `--fg-2`.

`border-top: 1px solid --rule`. Padding `2.5rem var(--gutter) 4rem`.
**No additional social links** in the footer (the link grid on home
already covers them).

### 6.18 Archive note (Medium pre-2026)

A short editorial note shown on `/posts/` only, between the page
header and the filter/listing. Single line, no background, no
borders, just an icon glyph and a sentence linking out to the
historic content on Medium.

```html
<aside class="archive-note" aria-label="Archivo histórico">
  <span class="archive-note-icon" aria-hidden="true">■</span>
  <p class="archive-note-body">
    Las publicaciones muy viejunas están disponibles en
    <a href="https://medium.com/@achetronic" rel="noopener" target="_blank">
      Medium<span class="archive-note-arrow" aria-hidden="true">↗</span>
    </a>
  </p>
</aside>
```

Rules:

- Inline-flex on the wrapper: glyph `■` (mono, `--fg-3`) + body text.
- Body text in `--fg-2`, ~`0.92rem`, line-height `1.55`.
- The Medium link uses mono and `nowrap`, with the `↗` glyph trailing
  in `--fg-3` (gets darker on hover, like the link grid arrows).
- **Don't add hairlines** above or below — kept deliberately quiet.
- Render only on the posts list page.

### 6.19 Pager (paginated listings)

Pagination block rendered at the bottom of `/posts/` (and tag term
pages) when `paginator.TotalPages > 1`. Three columns: prev label,
center meta, next label.

```html
<nav class="pager" aria-label="Paginación">
  <a class="pager-link pager-prev" rel="prev">← Anterior</a>
  <span class="pager-meta">Página 1 / 3</span>
  <a class="pager-link pager-next" rel="next">Siguiente →</a>
</nav>
```

When the prev or next is disabled, replace the `<a>` with a
`<span class="pager-link pager-disabled" aria-disabled="true">`.

Rules:

- `border-top: 1px solid --rule` and that's the only chrome.
- Mono, `0.82rem`. Meta is `--fg-3`, links are `--fg-2`, hover `--fg`.
- Size `pagination.pagerSize: 10` is set in `hugo.yaml`.
- Post numbers (`01`, `02`…) are computed against the **full** list
  size, not the page slice, so a post numbered `01` keeps reading as
  `01` on page 2. The `list.html` template handles this via:
  `globalIdx = total - ((PageNumber-1) * PagerSize + i)`.

### 6.20 Markdown-derived elements

All these are styled in `main.css` to keep the language consistent:

| element             | treatment                                                       |
| ------------------- | --------------------------------------------------------------- |
| `h1`–`h4`           | weight 600, white, hierarchy by size                            |
| `h5`, `h6`          | uppercase, tracked, `--fg-2` / `--fg-3`                         |
| `del` / `s`         | strikethrough `--fg-4`                                          |
| `ins` / `u`         | underline `--fg`                                                |
| `mark`              | **inverted pill** — bg `--fg`, color `--bg`                     |
| `abbr[title]`       | dotted underline, `cursor: help`                                |
| `sup` / `sub`       | mono small `--fg-3`                                             |
| `sup a` / `sub a`   | with 1px box (footnote-ref style)                               |
| `small`             | 0.85em `--fg-3`                                                 |
| `dl` / `dt` / `dd`  | grid `max-content 1fr`, `dt` mono uppercase                     |
| `details`           | square box, `+` / `−` mono toggle                               |
| `figure`            | polaroid (see §6.10)                                            |
| `aside`             | bg `--bg-1`, border-left 2px `--fg`                             |
| `kbd`               | small box `--bg-2`, border-bottom 2px                           |
| `var` / `samp`      | treated like inline `code`                                      |
| `q`                 | italic with `“…”` in `--fg-4` via `::before` / `::after`        |
| `cite`              | italic `--fg-3`                                                 |
| `video` / `audio` / `iframe` | block, max-width 100%, 1px border                      |
| `.footnotes`        | block at end of post, `border-top` 1px, label `Notas` uppercase |
| `.footnote-ref`     | small mono link with 1px border                                 |
| `input[checkbox]`   | custom: 0.95rem square, hand-drawn check                        |

### 6.21 Checkboxes (markdown task lists)

```css
.post-content input[type="checkbox"] {
  appearance: none;
  width: 0.95rem;
  height: 0.95rem;
  border: 1px solid var(--rule-2);
  background: transparent;
  position: relative;
}
.post-content input[type="checkbox"]:checked {
  background: var(--fg);
  border-color: var(--fg);
}
.post-content input[type="checkbox"]:checked::after {
  content: "";
  position: absolute;
  left: 0.22rem;
  top: 0.04rem;
  width: 0.3rem;
  height: 0.55rem;
  border: solid var(--bg);
  border-width: 0 1.5px 1.5px 0;
  transform: rotate(45deg);
}
.post-content li:has(> input[type="checkbox"]:checked) {
  color: var(--fg-3);
}
```

The `<li>` containing a checked checkbox is dimmed but **not
strikethrough** (this is a task list, not a to-do).

---

## 7. Animations & micro-interactions

### 7.1 Allowed transitions

Strictly limited to:

```css
transition: background .15s ease;            /* card hover */
transition: color .15s ease;                  /* links, arrows */
transition: text-decoration-color .12s ease;  /* underlines */
transition: opacity .15s–.25s ease;           /* arrows, lightbox, anchors */
transition: stroke-dashoffset 1.5s cubic-bezier(0.4, 0, 0.2, 1); /* SVG drawings */
transition: transform .08s linear;            /* reading progress (fast & linear) */
transition: transform .2s ease;               /* polaroid hover scale */
transition: transform .15s ease;              /* skip link slide-in */
```

### 7.2 Forbidden

- `transform: translateY()` on card or button hover.
- `box-shadow` anywhere except the `.post-content figure` polaroid.
- `filter: blur()` or `backdrop-filter`.
- `@keyframes` animations (no blinking, no fades, no slide-ins).

### 7.3 SVG square ring (link-card and post-card)

Both `.link-card` and `.post-card` contain a square SVG frame around
their arrow icon (`↗` for external, `→` for internal navigation).

```html
<svg class="link-card-square" viewBox="0 0 100 100">
  <rect x="3" y="3" width="94" height="94"
        fill="none" stroke="currentColor"
        stroke-width="1.5" stroke-linecap="round"
        stroke-linejoin="round"
        vector-effect="non-scaling-stroke"
        pathLength="100"/>
</svg>
```

CSS:

```css
.link-card-square,
.post-card-square {
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  color: var(--fg);
  overflow: visible;
  stroke-dasharray: 100;
  stroke-dashoffset: 100;
  /* Default (hover-out) — instantly reset the dashoffset so on next
   * hover-in the ring draws from the start; only fade the opacity. */
  transition: stroke-dashoffset 0s linear,
              opacity .15s ease;
  opacity: 0;
  shape-rendering: geometricPrecision;
}
.link-card:hover .link-card-square,
.post-card:hover .post-card-square {
  stroke-dashoffset: 0;
  opacity: 1;
  /* Hover-in — slow draw of the ring */
  transition: stroke-dashoffset 1.5s cubic-bezier(0.4, 0, 0.2, 1),
              opacity .25s ease;
}
```

Why the asymmetric transitions: with a single 1.5s transition,
moving the cursor in/out quickly causes the dash to "rewind" slowly
on hover-out. The fix is to use `0s linear` for `stroke-dashoffset`
in the resting state (instant reset) and only apply the slow
cubic-bezier inside `:hover`. Opacity keeps a quick fade either way.

Key tricks:

- **`pathLength="100"`** normalizes any rectangle perimeter to 100
  units → can use `dasharray: 100` regardless of size.
- **`vector-effect: non-scaling-stroke`** keeps stroke width in real
  pixels regardless of viewBox scaling → no pixelation.
- **`stroke-linecap: round`** + **`stroke-linejoin: round`** smooth
  corners and the dash start/end point.
- Container size: `1.4rem × 1.4rem`. Glyph sits at the center. Glyph
  does **not** translate on hover (kept still while ring draws).

### 7.4 Vertical white marker (post-nav)

Each nav cell has a `::before` pseudo-element with `width: 2px` of
`--fg`, scaled `Y(0)` by default and `Y(1)` on hover.

- Left cell marker: `left: 0`, `transform-origin: 0 0`.
- Right cell marker: `right: 0`, `transform-origin: 0 0`.

This reinforces direction of travel (back / forward).

### 7.5 Reading progress bar

Only on post single (`<div class="reading-progress">` injected by
`baseof.html` only when `kind: page` and `Section: posts`).

```css
.reading-progress {
  position: fixed;
  top: 0; left: 0; right: 0;
  height: 1px;
  background: var(--fg);
  transform: scaleX(0);
  transform-origin: 0 0;
  transition: transform .08s linear;
  z-index: 150;
}
```

Updated on `scroll` event in `setupReadingProgress()`. Linear timing
(not eased) because the bar represents a literal scroll position.

### 7.6 Heading anchor (`#`)

Already covered in §6.9. Fades in on heading hover. Hidden on mobile.

### 7.7 Copy button on code blocks

```html
<button class="copy-btn">copy</button>
```

Injected into every `.codeblock` by `setupCodeCopy()` in
`terminal.js`. **Always visible** (per recent UX feedback — was
hover-only previously).

```css
.copy-btn {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  padding: 0.2rem 0.55rem;
  font-family: var(--mono);
  font-size: 0.7rem;
  color: var(--fg-4);
  background: transparent;
  border: 1px solid var(--rule);
}
.copy-btn:hover {
  color: var(--fg);
  border-color: var(--rule-2);
  background: var(--bg-1);
}
.copy-btn.copied {
  color: var(--fg);
  border-color: var(--fg);
}
```

States: `copy` → click → `ok` (1.4s, with `.copied` class) → `copy`.
Errors render `err`.

### 7.8 Image lightbox

Click any `<img>` inside `.post-content` → full-viewport overlay.

Implementation in `setupLightbox()`:

1. JS appends a single `.lightbox` overlay to `<body>`.
2. Each `<img>` gets `class="zoomable"` + click listener.
3. Clicking opens the overlay with a copy of the image.
4. **Close** triggers: click anywhere except the image, click the `×`
   button, or `Escape` key.
5. While open, `<html>` gets `lightbox-active` class which disables
   scrolling.
6. Cursor on post image: `zoom-in`. Cursor on lightbox image:
   `zoom-out`.

```css
.lightbox {
  position: fixed; inset: 0; z-index: 1000;
  background: rgba(0, 0, 0, 0.92);
  display: flex; align-items: center; justify-content: center;
  padding: 3rem;
  opacity: 0; pointer-events: none;
  transition: opacity .2s ease;
}
.lightbox.open { opacity: 1; pointer-events: auto; }
.lightbox-img {
  max-width: 100%;
  max-height: 100%;
  border: 1px solid var(--rule);
  background: var(--bg);
  cursor: zoom-out;
}
/* SVGs without intrinsic dimensions: force a sensible width */
.lightbox-img[src$=".svg"] {
  width: min(100%, 1100px);
  height: auto;
}
.lightbox-close {
  position: absolute;
  top: 1.25rem; right: 1.25rem;
  width: 2.25rem; height: 2.25rem;
  border: 1px solid var(--rule-2);
  background: transparent;
  color: var(--fg-2);
  font-family: var(--mono);
  font-size: 1.4rem;
}
.lightbox-close:hover {
  color: var(--bg);
  background: var(--fg);
  border-color: var(--fg);
}
```

### 7.9 Skip link (a11y)

```html
<a href="#main" class="skip-link">Saltar al contenido</a>
```

Off-screen by default (`translateY(-200%)`). Slides in on focus. Lets
keyboard users skip topbar straight to `<main id="main">`.

### 7.10 Focus rings (a11y)

`<html>` gets `using-keyboard` class via JS when `Tab` is pressed
(removed on mousedown). CSS shows outlines only when that class is
active:

```css
:focus { outline: none; }
.using-keyboard a:focus,
.using-keyboard .post-card:focus,
.using-keyboard .link-card:focus,
... {
  outline: 1px solid var(--fg);
  outline-offset: 2px;
}
```

Standard accessibility pattern. Mouse users see no outline noise.

---

## 8. Iconography

No SVG icon libraries. No emoji. No brand logos (GitHub, Twitter,
etc — identified by name).

Permitted Unicode glyphs:

| glyph   | usage                                        |
| ------- | -------------------------------------------- |
| `→`     | CTA buttons, post-card internal arrow         |
| `↗`     | link-card external arrow                      |
| `←` `→` | post-nav previous / next                      |
| `·`     | inline meta separators                        |
| `+` `−` | filter / details collapsible toggle           |
| `#`     | tag prefix (via `::before`)                   |
| `×`     | lightbox close button                         |

---

## 9. Theme system (dark / light)

`themes/tty/layouts/partials/head.html` includes an inline blocking
script before any stylesheet:

```html
<script>
  (function () {
    try {
      var t = localStorage.getItem('theme');
      if (t !== 'light' && t !== 'dark') {
        t = window.matchMedia('(prefers-color-scheme: dark)').matches
            ? 'dark' : 'light';
      }
      document.documentElement.setAttribute('data-theme', t);
    } catch (e) {}
  })();
</script>
```

This sets `data-theme` on `<html>` **before first paint**, so there
is no flash. The theme-toggle button updates this attribute and
persists it in `localStorage`.

CSS branches via `:root[data-theme="dark"]`. Without that selector
the light palette is the default (also covered by `:root` directly).

---

## 10. Templates and folder structure

```
themes/tty/
├── theme.toml
├── archetypes/default.md
├── assets/
│   ├── css/
│   │   ├── main.css        # all design tokens + components
│   │   └── syntax.css      # syntax highlighting palette
│   └── js/
│       └── terminal.js     # reading-progress, copy-btn, theme-toggle,
│                           # keyboard-focus, lightbox
├── static/
│   └── fonts/
│       ├── Geist-Variable.woff2
│       └── GeistMono-Variable.woff2
└── layouts/
    ├── 404.html
    ├── _default/
    │   ├── baseof.html       # html + body classes + reading-progress div
    │   ├── list.html         # /posts/, /tags/, /tags/<term>/
    │   ├── single.html       # /posts/<slug>/
    │   └── _markup/
    │       ├── render-heading.html    # adds anchor link `#`
    │       └── render-codeblock.html  # adds .codeblock wrapper + data-lang
    ├── index.html            # home
    ├── partials/
    │   ├── head.html         # meta, favicons, fonts preload, theme bootstrap, fingerprinted CSS
    │   ├── header.html       # topbar (brand-mark + nav + theme toggle)
    │   ├── footer.html       # bottom (copyright + RSS link)
    │   ├── analytics.html    # optional Umami beacon, prod-only, opt-in
    │   └── scripts.html
    └── shortcodes/
        └── callout.html
```

The site favicons live under `static/`:

- `favicon.png` — main 256×256 favicon (head crop, black on transparent).
- `favicon-dark.png` — white variant for `prefers-color-scheme: dark`,
  wired in `head.html` with a `media` swap so the browser tab follows
  the OS theme (independent of our `data-theme` attribute).
- `favicon.ico` — multi-size legacy fallback.
- `apple-touch-icon.png` — 180×180 for iOS home-screen.

If the head logo is ever updated, regenerate all four with the same
crop + padding (the head crop in `static/images/achetronic-mark.png`
is the source of truth).

---

## 11. UX rules

- **Static site, JavaScript is enhancement only.** Reading progress,
  copy buttons, theme toggle, lightbox and anchor links all degrade
  gracefully without JS (the content is fully accessible without it).
- **No sticky elements.** Topbar flows with content.
- **No breadcrumbs.** Linear navigation: topbar → list → post.
- **Two-tab navigation only.** `Inicio` (`/`) and `Publicaciones`
  (`/posts/`).
- **Spanish UI.** Capitalized labels (`Inicio`, `Publicaciones`,
  `Anterior`, `Siguiente`, `Filtrar por etiqueta`,
  `Publicación · YYYY`, `min lectura`, `palabras`, `vacío`,
  `Saltar al contenido`).
- **Spanish content.** Posts are written in Spanish.
- **Single responsive breakpoint** at `600px`:
  - body font-size drops to `15.5px`
  - paddings reduced
  - post-nav, link-grid wrap to 1 column
  - logos shrink
  - heading anchors hidden
- **Pagination.** `/posts/` and tag term pages use Hugo's built-in
  paginator with `pagerSize: 10`. The `<nav class="pager">` only
  renders when there is more than one page. Post numbers are global
  (don't reset per page).
- **RSS** is exposed via the small footer link `◉ RSS → /index.xml`
  and discovered automatically through `<link rel="alternate">` in
  the head. Don't bury the link or replace it with an SVG icon.
- **Analytics** are off by default. The optional Umami beacon
  (`partials/analytics.html`) is the only allowed third-party script
  and only loads in `hugo.Environment "production"`. It is cookieless
  and requires no consent banner. Other trackers, pixels, or ad
  scripts are forbidden.
- **`<title>` is hardcoded** to `Achetronic` site-wide (in
  `head.html`). Per-page titles still drive `og:title` and
  `<meta name="description">` for SEO.

---

## 12. Anti-patterns (do NOT)

If you catch yourself doing any of these, stop:

- ❌ `border-radius` > 0
- ❌ `box-shadow` (except polaroid)
- ❌ Linear or radial gradients on backgrounds
- ❌ `backdrop-filter: blur()` for "glass effect"
- ❌ `transform: translateY(-2px)` on hover
- ❌ Saturated colors outside `--hl`
- ❌ Three or more distinct colors in one view
- ❌ SVG brand logos
- ❌ Emoji
- ❌ Google Fonts or any external CDN
- ❌ Fade-in / slide-up on-load animations
- ❌ Blinking cursors, ASCII art, fake terminal prompts
- ❌ `border-style: dashed` (always solid)
- ❌ Multiple font weights in one paragraph
- ❌ `text-transform: uppercase` with aggressive letterspacing in body
  copy (only allowed on h4–h6, post-num, pill labels)
- ❌ Cards in the same view with different border thickness or sizes

---

## 13. Allowed micro-differentiators

Things that add character without breaking the system:

- **Descending numeric counters** in post-card list (`03 / 02 / 01`).
  Visual rhythm without screaming.
- **Format-shifting post identifiers** depending on context:
  `Publicación · 2025` (post header pill), `01 / 02 / 03`
  (list cards), `BASH` (code block pill). Same vocabulary, different
  granularity.
- **Direction-coherent arrows**: `↗` external, `→` internal,
  `← / →` post-nav.
- **Density gradient**: home cards are minimal (name + url + arrow),
  post-list cards are richer (number + title + desc + meta).
- **Inline separators differ by purpose**: `·` for inline meta
  (post-foot), hairlines `--rule` for visual separators between cells.
  **Never use `|`.**
- **Active states in topnav**: only color change `--fg-3` → `--fg`,
  no underline, no background.

---

## 14. Content imports (Medium, etc.)

Posts imported from external sources should:

1. Preserve the **original `date`** in front-matter (`YYYY-MM-DDTHH:MM:SS+ZZZZ`).
2. Add a **`canonical`** front-matter pointing to the original URL
   (SEO best-practice for republished content).
3. Download images locally to `static/images/posts/<slug>/`.
4. Convert HTML → Markdown preserving figures with captions, code
   blocks (with language detection), blockquotes, tables, etc.
5. Use slugs without accents:
   `mi-extraño-arranque-dual` → `mi-extrano-arranque-dual`.

Example front-matter:

```yaml
---
title: "Mi extraño arranque dual"
slug: "mi-extrano-arranque-dual"
date: 2021-03-05T05:39:15+0000
lastmod: 2021-03-05T05:39:15+0000
draft: false
description: "..."
tags:
  - "linux"
  - "grub"
canonical: "https://achetronic.medium.com/..."
---
```

---

## 15. Changes that don't require updating this document

- New posts, new tags.
- Spanish UI copy tweaks.
- Spacing tweaks of ±0.25rem that don't change hierarchy.

## 16. Changes that DO require updating this document

- Any new color in the palette.
- A new font family.
- Box model changes (radius, shadow, base padding).
- New components.
- New external dependencies (JS, fonts, icons).
- Changes to the theme toggle behavior.
- Changes to keyboard or focus handling.
- New animations or transitions.

---

*Last revision: design after Medium import + figure modes + theme
toggle + Geist fonts + SVG square ring animation.*
