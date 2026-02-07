# Astro Starter Template

Production-ready Astro 5 starter with Tailwind CSS v4, React 19, MDX, i18n, and Sharp image optimization.

## Package Manager

Uses **Bun** — `bun install`, `bun run dev`, `bun run build`, `bun run preview`.

## Key Conventions

- Prefer `.astro` components — only use `.tsx` when client-side interactivity is needed (`client:load`, `client:visible`, `client:idle`)
- Use **Tailwind CSS v4** via `@tailwindcss/vite` (not the legacy `@astrojs/tailwind` integration)
- Use `<Picture>` and `<Image>` from `astro:assets` for all images
- TypeScript strict mode; define `interface Props` in component frontmatter
- All URLs have trailing slashes

## I18n

Custom i18n using Astro's built-in `i18n` config with `prefixDefaultLocale: false`. Translations live in `src/i18n/ui.ts`, helpers in `src/i18n/utils.ts` (`getLangFromUrl`, `useTranslations`, `useTranslatedPath`). See `docs/I18N.md` for full setup.

## Detailed Guidelines

- Image optimization: `docs/IMAGES.md`
- SEO & Layout component: `docs/SEO.md`
- i18n setup & patterns: `docs/I18N.md`
