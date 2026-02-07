# Astro Starter Template

Production-ready Astro 5 starter with Tailwind CSS, React, MDX, sitemap, Sharp image optimization, and SEO.

## Commands

| Command          | Action                              |
| ---------------- | ----------------------------------- |
| `bun install`    | Install dependencies                |
| `bun run dev`    | Start dev server at `localhost:4321` |
| `bun run build`  | Build production site to `./dist/`  |
| `bun run preview`| Preview production build locally    |

## Deployment

The site deploys automatically via GitHub Actions (`.github/workflows/deploy.yml`) on push to `main`. It can also be triggered manually via `workflow_dispatch`.

### Pipeline

1. **Build** — Uses `withastro/action@v2` with Bun and Node 22 to build the site; uploads `dist/` as an artifact
2. **Deploy** — Downloads the artifact and uploads `dist/*` to the SFTP server via `wlixcc/SFTP-Deploy-Action@v1.2.4`

### Required GitHub Secrets

Set these in **Settings → Secrets and variables → Actions** in the GitHub repository.

| Secret | Description |
| --- | --- |
| `SFTP_SERVER` | SFTP server hostname or IP |
| `SFTP_USERNAME` | SFTP login username |
| `SFTP_PASSWORD` | SFTP login password |
