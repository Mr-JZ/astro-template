# Astro Starter Template

Production-ready Astro 5 starter with Tailwind CSS v4, React 19, MDX, i18n, sitemap, and Sharp image optimization.

## Use This Template

### Option 1: GitHub UI

Click **"Use this template"** > **"Create a new repository"** at the top of this page.

### Option 2: GitHub CLI

```bash
gh repo create my-site --template Mr-JZ/astro-template --clone
cd my-site
bun install
```

### Option 3: degit (no git history)

```bash
npx degit Mr-JZ/astro-template my-site
cd my-site
bun install
```

## Getting Started

```bash
bun install          # Install dependencies
bun run dev          # Start dev server at localhost:4321
bun run build        # Build for production
bun run preview      # Preview production build
```

After cloning, update the `site` URL in `astro.config.mjs` to your domain.

## What's Included

- **Astro 5** — Static-first, islands architecture
- **Tailwind CSS v4** — Utility-first styling via `@tailwindcss/vite`
- **React 19** — For interactive components (`client:load`, `client:visible`, `client:idle`)
- **MDX** — Markdown with components
- **Sharp** — Automatic image optimization (AVIF, WebP)
- **Sitemap** — Auto-generated at `/sitemap-index.xml`
- **SEO** — Open Graph, Twitter Cards, canonical URLs, JSON-LD support
- **i18n** — Built-in multi-language support (see `docs/I18N.md`)
- **TypeScript** — Strict mode
- **Prefetch** — All links prefetched on hover

## Project Structure

```
src/
├── assets/        # Images (optimized at build time)
├── components/    # .astro and .tsx components
├── i18n/          # Translations and i18n helpers
├── layouts/       # Page layout wrappers
├── pages/         # File-based routing
└── styles/        # Global CSS
docs/              # Detailed guidelines (images, SEO, i18n)
public/            # Static files (favicon, robots.txt)
```

## Documentation

- [`docs/IMAGES.md`](docs/IMAGES.md) — Image optimization with `<Picture>` and `<Image>`
- [`docs/SEO.md`](docs/SEO.md) — SEO meta tags and Layout component
- [`docs/I18N.md`](docs/I18N.md) — Multi-language setup and translation patterns

## Deployment

The site deploys automatically via GitHub Actions (`.github/workflows/deploy.yml`) on push to `main`. It can also be triggered manually via `workflow_dispatch`.

### Pipeline

1. **Build** — Uses `withastro/action@v2` with Bun and Node 22 to build the site; uploads `dist/` as an artifact
2. **Deploy** — Downloads the artifact and uploads `dist/*` to the SFTP server via `wlixcc/SFTP-Deploy-Action@v1.2.4`

### Required GitHub Secrets

Set these in **Settings > Secrets and variables > Actions** in the GitHub repository.

| Secret | Description |
| --- | --- |
| `SFTP_SERVER` | SFTP server hostname or IP |
| `SFTP_USERNAME` | SFTP login username |
| `SFTP_PASSWORD` | SFTP login password |

## License

MIT
