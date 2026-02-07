# Image Optimization

Always use Astro's built-in components from `astro:assets`.

## `<Picture>` — Preferred for large/hero images

```astro
import { Picture } from "astro:assets";

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
```

## `<Image>` — Simple optimized images

```astro
import { Image } from "astro:assets";

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

## Rules

- Hero/above-fold: `loading="eager"` + `fetchpriority="high"`
- Below-fold: `loading="lazy"` (default)
- Always set `alt` text
- Use `formats={["avif", "webp"]}` for Picture
- Quality: 80-90 for photos, 90+ for logos
- Place images in `src/assets/` for optimization (not `public/`)
