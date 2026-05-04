# achetronic / website

Personal website of **achetronic** at [achetronic.com](https://achetronic.com),
a small site with a few sections and a blog. Built with [Hugo](https://gohugo.io/)
and a custom theme (`tty`).

The design system used by the site is documented in detail in
[`.agents/design-system.md`](./.agents/design-system.md). If you contribute
or repurpose this codebase, read that file first.

---

## Stack

| piece           | what                                                       |
|-----------------|------------------------------------------------------------|
| **Hugo**        | static site generator (extended ≥ 0.128, tested on 0.155.3) |
| **theme**       | `themes/tty` — handcrafted, no npm, no JS framework         |
| **fonts**       | Geist + Geist Mono (Vercel) served locally, no Google Fonts |
| **CI/CD**       | GitHub Actions → GitHub Pages (HTML) + GHCR (OCI image)     |
| **runtime**     | nginx 1.27 alpine for OCI deployments                       |
| **build**       | minified output + asset fingerprinting                      |

No tracker that profiles you. No third-party ads. No cookies. No
consent banner. Just text. The site ships a single cookieless
analytics beacon (Umami), configured in `hugo.yaml`; remove the params
to disable it entirely.

---

## Quickstart

```bash
# 1. make sure you have Hugo extended installed
make check

# 2. start the dev server (with drafts, live reload)
make serve

# 3. open it
make open      # or http://localhost:1313 directly
```

If Hugo is missing:

```bash
make install-hugo   # prints install instructions for your OS
```

---

## Make targets

Everything you need is wired into the `Makefile`. Run `make help` for the
full list. The most useful ones:

```text
setup
  check              verify Hugo is installed
  install-hugo       show install instructions for Hugo extended

development
  serve              dev server on :1313 with drafts and live reload
  preview            same but production-like (no drafts, minified)

build
  build              build into public/
  build-prod         CI-equivalent build (minified, no drafts)

content
  new SLUG=foo       scaffold a new post at content/posts/foo.md

maintenance
  clean              remove public/
  clean-all          remove public/ + Hugo caches
  stats              show post count, word count, etc.

ci / qa
  lint               validate Hugo config
  check-links        check for broken links (uses lychee if installed)
  deploy-check       run the same build CI runs

docker / oci
  docker-build       build the OCI image (achetronic/website:local)
  docker-run         build and run the image on :8080
  docker-push        tag and push to ghcr.io (requires docker login)

extras
  open               open the site in the browser
```

### Useful overrides

| variable    | default                     | use                                     |
|-------------|-----------------------------|-----------------------------------------|
| `PORT`      | `1313`                      | dev server port                         |
| `BIND`      | `0.0.0.0`                   | bind address                            |
| `BASEURL`   | `http://localhost:1313/`    | base URL during development             |
| `HUGO`      | `hugo`                      | Hugo binary (override for custom build) |
| `IMAGE`     | `achetronic/website`        | OCI image name (without registry)       |
| `TAG`       | `local`                     | OCI image tag                           |

```bash
make serve PORT=8080
make docker-build IMAGE=mything TAG=v1.2.3
```

---

## Repository layout

```
.
├── Makefile                    # all the recipes
├── Dockerfile                  # multi-stage: Hugo build → nginx runtime
├── hugo.yaml                   # site config
├── archetypes/                 # `hugo new` templates
├── content/
│   └── posts/                  # /posts/<slug>/
├── themes/tty/                 # custom theme
│   ├── theme.toml
│   ├── assets/
│   │   ├── css/main.css        # all design tokens + components
│   │   └── css/syntax.css      # syntax highlighting
│   ├── assets/js/terminal.js   # progressive enhancements
│   ├── static/fonts/           # Geist + Geist Mono variable fonts
│   └── layouts/                # base, list, single, partials, hooks
├── static/                     # files served at /
│   ├── favicon.png             # site favicon (light / default)
│   ├── favicon-dark.png        # dark scheme variant (white head)
│   ├── favicon.ico             # legacy fallback (multi-size)
│   ├── apple-touch-icon.png    # iOS home-screen icon
│   └── images/                 # post and site images
├── .agents/
│   └── design-system.md        # full design system reference
└── .github/workflows/
    ├── deploy.yml              # GitHub Pages deployment
    └── oci.yml                 # multi-arch OCI image to GHCR
```

---

## Writing a post

```bash
make new SLUG=my-article
```

That generates `content/posts/my-article.md` with this front matter:

```yaml
---
title: "My Article"
date: 2026-XX-XX
draft: true
description: ""
tags: []
categories: []
---
```

While `draft: true`, the post **only shows up** under `make serve`. Once
ready, set `draft: false`, commit and push.

Useful front-matter keys: `tags`, `categories`, `series`, `description`,
`slug`, `lastmod`, `canonical` (for posts originally published elsewhere).

### Available shortcodes

```markdown
{{</* callout type="warning" title="Heads up" */>}}
This block stands out.
{{</* /callout */>}}
```

`type` accepts `info` (default), `tip`, `warning`, `danger`.

---

## Deployment

The site is published at [achetronic.com](https://achetronic.com).

### GitHub Pages (HTML)

Every push to `main` triggers `.github/workflows/deploy.yml`, which:

1. Installs Hugo extended `0.155.3`.
2. Builds with `hugo --gc --minify` and the right Pages base URL.
3. Uploads `public/` as a Pages artifact and deploys it.

> **First-time setup:** in your GitHub repo go to **Settings → Pages →
> Source** and pick **GitHub Actions**. To serve the site under
> `achetronic.com`, configure the **custom domain** in the same panel
> and add a `CNAME` file (or let GitHub create it for you) plus the
> right DNS records (`ALIAS`/`ANAME` to `achetronic.github.io` or four
> A records to GitHub Pages IPs).

To validate locally what CI will produce:

```bash
make deploy-check
```

### OCI image (GHCR)

Every push to `main` (and every tag matching `v*`) also triggers
`.github/workflows/oci.yml`, which:

1. Builds a **multi-arch image** (`linux/amd64`, `linux/arm64`) using
   QEMU + Buildx.
2. Tags it with branch name, semver, short SHA and `latest` (on `main`).
3. Pushes to `ghcr.io/<owner>/<repo>` with proper OCI annotations.
4. Generates an **SBOM** and **build provenance**.
5. **Signs the image with cosign** (keyless, OIDC) and pushes the
   signature alongside the image.
6. Attests the build with `attest-build-provenance` so consumers can
   verify the image came from this exact workflow.

The image runs `nginx:1.27-alpine` as **non-root** (uid 101), exposes
port `8080`, and ships with sensible cache headers and security headers.

### Run the image locally

```bash
make docker-run
# → http://localhost:8080
```

### Pull and run from GHCR

```bash
docker pull ghcr.io/achetronic/website:latest
docker run --rm -p 8080:8080 ghcr.io/achetronic/website:latest
```

### Verify the cosign signature

```bash
cosign verify \
  --certificate-identity-regexp "https://github.com/achetronic/website/.github/workflows/oci.yml@.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/achetronic/website:latest
```

> **First-time setup:** the very first time the workflow pushes the
> image, GHCR creates the package as **private**. Go to your GitHub
> profile → **Packages → website → Settings** and switch its visibility
> to **Public** if you want it pullable without auth.

---

## Analytics

The site loads a single cookieless analytics beacon. It only renders
when the corresponding params are set in `hugo.yaml` **and** the build
runs in `production` environment (so `make serve` never loads any
beacon).

Currently wired:

- **Umami** (`params.umamiWebsiteId` + `params.umamiSrc`).

```yaml
params:
  umamiWebsiteId: "<your-website-id>"
  umamiSrc: "https://your-umami-host/script.js"
```

Both values are public by design (the snippet runs in the visitor's
browser), so it's safe to commit them. They do not authenticate against
your analytics account; they only let the beacon report to it.

To disable analytics altogether, remove both params from `hugo.yaml`.
To swap providers, edit
`themes/tty/layouts/partials/analytics.html` — easy to extend.

---

## Listing pagination

The `/posts/` listing is paginated using Hugo's built-in paginator.

Configured in `hugo.yaml`:

```yaml
pagination:
  pagerSize: 10
```

The pager renders below the list once there is more than one page,
matching the rest of the design language (hairlines, mono pager labels,
no buttons or chrome). Post numbers are preserved across pages so a
post numbered `01` keeps reading as `01` on page 2 of the listing.

---

## RSS

Hugo emits an RSS feed at `/index.xml` for the site, and a per-section
feed wherever Hugo would normally generate one. There is a small RSS
button in the footer linking to it. Feed readers will discover it
automatically via the `<link rel="alternate">` tag in the head.

## License

Code under [MIT](LICENSE). Content under CC BY-NC-SA 4.0 unless stated
otherwise on the post itself.
