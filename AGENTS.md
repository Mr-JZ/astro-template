# Astro Starter Template

## Project Overview

Production-ready Astro 5 starter with Tailwind CSS, React, MDX, sitemap, Sharp image optimization, and SEO.

## Tech Stack

- **Framework**: Astro 5
- **Styling**: Tailwind CSS 3
- **UI**: React 19 (for interactive components)
- **Content**: MDX support
- **Images**: Sharp (AVIF/WebP optimization)
- **Language**: TypeScript (strict mode)
- **Package Manager**: Bun (bun.lock), npm/yarn compatible

## Commands

| Command          | Action                              |
| ---------------- | ----------------------------------- |
| `bun install`    | Install dependencies                |
| `bun run dev`    | Start dev server at `localhost:4321` |
| `bun run build`  | Build production site to `./dist/`  |
| `bun run preview`| Preview production build locally    |

## Project Structure

```
src/
├── assets/        # Images/SVGs (optimized by Astro at build time)
├── components/    # Reusable .astro and .tsx components
├── layouts/       # Page layout wrappers (Layout.astro)
├── pages/         # File-based routing (each file = a route)
└── styles/        # globals.css (Tailwind directives + base styles)
public/            # Static files served as-is (favicon, robots.txt)
```

## Integrations (astro.config.mjs)

- **@astrojs/tailwind** — Tailwind CSS integration
- **@astrojs/react** — React component support (.tsx/.jsx)
- **@astrojs/mdx** — MDX content support
- **@astrojs/sitemap** — Auto-generated sitemap at `/sitemap-index.xml`
- **sharp** — Image optimization service (AVIF, WebP)
- **Prefetch** — All links prefetched on hover
- **Trailing slash** — All URLs end with `/`

## Development Guidelines

### Images — Use `<Picture>` and `<Image>`

Always use Astro's built-in components from `astro:assets`:

```astro
import { Picture } from "astro:assets";
import { Image } from "astro:assets";

<!-- Responsive multi-format (preferred for large images) -->
<Picture
  src={heroImage}
  alt="Description"
  widths={[640, 768, 1024, 1280]}
  sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 600px"
  formats={["avif", "webp"]}
  quality={85}
  loading="eager"
  fetchpriority="high"
/>

<!-- Simple optimized image -->
<Image
  src={logo}
  alt="Logo"
  width={120}
  height={200}
  format="webp"
  quality={90}
  loading="lazy"
/>
```

**Rules:**
- Hero/above-fold images: `loading="eager"` + `fetchpriority="high"`
- Below-fold images: `loading="lazy"` (default)
- Always set `alt` text
- Use `formats={["avif", "webp"]}` for Picture
- Quality: 80-90 for photos, 90+ for logos

### SEO

The Layout component (`src/layouts/Layout.astro`) includes:
- `<title>` and `<meta name="description">`
- Open Graph tags (`og:title`, `og:description`, `og:image`, `og:type`)
- Twitter Card tags
- Canonical URL
- Sitemap link
- `<slot name="head" />` for per-page additions (JSON-LD, extra meta)

**Adding JSON-LD structured data to a page:**
```astro
<Layout title="Page Title" description="Page description">
  <script type="application/ld+json" slot="head" set:html={JSON.stringify({
    "@context": "https://schema.org",
    "@type": "WebSite",
    "name": "Site Name",
    "url": "https://example.com",
  })} />

  <!-- Page content -->
</Layout>
```

**Adding Open Graph image:**
```astro
<Layout title="Page" ogImage="/images/og-image.jpg">
```

### Styling

- Use Tailwind CSS utility classes
- Global styles in `src/styles/globals.css`
- Scoped styles in `.astro` components via `<style>` tags
- Utility classes available: `.container-default`, `.section-padding`
- Skip-to-content link included for accessibility

### Components

- `.astro` components: Static, server-rendered (default)
- `.tsx/.jsx` components: Use for interactive/client-side features
  - Add `client:load`, `client:visible`, or `client:idle` directive
- Always define TypeScript `interface Props` in frontmatter

### Pages & Routing

- Each `.astro` file in `src/pages/` = a route
- Dynamic routes: `[slug].astro` with `getStaticPaths()`
- All URLs have trailing slashes (configured in astro.config)

### Content Collections (MDX)

To add a blog or content section:
1. Create `src/content/` directory
2. Define schema in `src/content/config.ts`
3. Create `.mdx` files in subdirectories
4. Query with `getCollection()` / `getEntry()`

### Configuration

- `astro.config.mjs` — Integrations, site URL, image service, prefetch
- `tailwind.config.mjs` — Tailwind theme customization
- `tsconfig.json` — Extends `astro/tsconfigs/strict`

### Important Notes

- Set your site URL in `astro.config.mjs` (`site` property) — needed for sitemap and canonical URLs
- Do NOT edit `dist/` or `.astro/` — these are generated
- Environment variables go in `.env` (gitignored), access via `import.meta.env`
- Static files in `public/` are copied as-is (no processing)
- Assets in `src/assets/` are optimized by Astro at build time
