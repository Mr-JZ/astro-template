// @ts-check
import { defineConfig } from "astro/config";

import mdx from "@astrojs/mdx";
import sitemap from "@astrojs/sitemap";
import tailwind from "@astrojs/tailwind";
import react from "@astrojs/react";

// https://astro.build/config
export default defineConfig({
  integrations: [mdx(), sitemap(), tailwind(), react()],
  site: "https://example.com",
  trailingSlash: "always",
  devToolbar: {
    enabled: false,
  },
  image: {
    service: {
      entrypoint: "astro/assets/services/sharp",
    },
  },
  prefetch: {
    prefetchAll: true,
    defaultStrategy: "hover",
  },
});
