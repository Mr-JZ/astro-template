# SEO & Layout

The Layout component (`src/layouts/Layout.astro`) handles all SEO meta tags.

## Included Tags

- `<title>` and `<meta name="description">`
- Open Graph (`og:title`, `og:description`, `og:image`, `og:type`)
- Twitter Card tags
- Canonical URL
- Sitemap link (`/sitemap-index.xml`)
- `<slot name="head" />` for per-page additions

## Usage

```astro
<Layout title="Page Title" description="Page description">
  <!-- Page content -->
</Layout>
```

### Adding JSON-LD structured data

```astro
<Layout title="Page Title" description="Page description">
  <script type="application/ld+json" slot="head" set:html={JSON.stringify({
    "@context": "https://schema.org",
    "@type": "WebSite",
    "name": "Site Name",
    "url": "https://example.com",
  })} />
</Layout>
```

### Adding Open Graph image

```astro
<Layout title="Page" ogImage="/images/og-image.jpg">
```

## Important

Set your `site` URL in `astro.config.mjs` — required for sitemap and canonical URLs.
