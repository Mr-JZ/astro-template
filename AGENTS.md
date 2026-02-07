# Astro Starter Template

## Project Overview

Minimal Astro 5 starter template. Pure Astro components, no UI frameworks (React/Vue/Svelte) or CSS frameworks (Tailwind) — ready to be extended.

## Tech Stack

- **Framework**: Astro 5 (v5.17.1)
- **Language**: TypeScript (strict mode)
- **Package Manager**: Bun (bun.lock), but npm/yarn compatible

## Project Structure

```
src/
├── assets/        # Static assets (SVGs, images)
├── components/    # Reusable .astro components
├── layouts/       # Page layout wrappers
└── pages/         # File-based routing (each .astro file = a route)
public/            # Static files served as-is (favicon, robots.txt)
```

## Commands

| Command          | Action                                      |
| ---------------- | ------------------------------------------- |
| `bun install`    | Install dependencies                        |
| `bun run dev`    | Start dev server at `localhost:4321`         |
| `bun run build`  | Build production site to `./dist/`           |
| `bun run preview`| Preview production build locally             |

## Development Guidelines

### Astro Basics

- Pages go in `src/pages/` — each `.astro` file becomes a route automatically.
- Reusable components go in `src/components/`.
- Layouts in `src/layouts/` wrap page content with shared HTML structure.
- Static assets in `src/assets/` are optimized by Astro at build time.
- Files in `public/` are copied as-is to the output.

### Code Style

- Use `.astro` single-file components (frontmatter script + template + scoped styles).
- Use TypeScript in component frontmatter (`---` blocks).
- Keep styles scoped to components (Astro scopes `<style>` by default).
- Prefer Astro's built-in `<Image>` component for optimized images.

### Configuration

- `astro.config.mjs` — Astro configuration (integrations, adapters, etc.)
- `tsconfig.json` — Extends `astro/tsconfigs/strict`

### Adding Integrations

To add frameworks or tools, use `bunx astro add <integration>`:

```sh
bunx astro add react      # Add React support
bunx astro add tailwind   # Add Tailwind CSS
bunx astro add mdx        # Add MDX support
```

### Important Notes

- Do NOT edit files in `dist/` or `.astro/` — these are generated.
- The `.astro/` directory contains auto-generated types; it's gitignored.
- Environment variables go in `.env` (gitignored). Use `import.meta.env` to access them.
