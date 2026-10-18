# Deployment with nginx, Depot and Dokploy

Every push to `main` builds the site into a small nginx image and rolls it out:

1. **Depot CI** runs `.depot/workflows/build-production.yml`. It builds the `Dockerfile` and saves the image to the Depot Registry, tagged with the commit SHA and `production`.
2. The workflow points the **Dokploy** application at the new tag and starts a deployment (`scripts/ci/`).
3. Dokploy pulls the image and runs it. nginx serves the static files on port 8080, behind Dokploy's Traefik and, usually, Cloudflare.

The server only pulls and runs a finished image, so building never costs it CPU or RAM.

The older SFTP workflow in `.github/workflows/deploy.yml` still works for plain hosting. Delete whichever workflow a site does not use.

## Why nginx

An Astro site built with `output: 'static'` is plain files. nginx (`nginxinc/nginx-unprivileged`, Alpine) serves them from about 8 MB of RAM. It handles gzip, redirects and cache headers, and runs as a non-root user. In our benchmark it served files faster than BusyBox httpd, `serve`, and Bun or Node servers.

## Files

| File | Purpose |
| --- | --- |
| `Dockerfile` | Bun builds the site, then the files are copied into nginx. A cache mount keeps Astro's optimized images between builds. |
| `.dockerignore` | An allowlist, so only what `astro build` reads ends up in the build context. Add new config files here. |
| `deploy/nginx.conf` | Port 8080, gzip, one-year cache for `/_astro/`, revalidation for pages, `index.html` redirects. |
| `.depot/workflows/build-production.yml` | Build, save to the registry, roll out on Dokploy. |
| `scripts/ci/update-dokploy-service.sh` | Sets the image and the registry login on the Dokploy app. |
| `scripts/ci/deploy-dokploy-service.sh` | Starts the deployment and waits until it finishes or fails. |
| `scripts/check-site-image.sh` | Smoke-tests a built image locally. |

## Setting up a new site

1. **Depot project.** Create a project in the Depot dashboard and put its ID in `DEPOT_PROJECT_ID` in the workflow.
2. **Pull token.** In that project, open Settings → Tokens and create a token. Copy the value right away, because Depot shows it only once. Then store it as a Depot CI secret for this repo:

   ```bash
   pbpaste | depot ci secrets add DEPOT_PULL_TOKEN <variant-name> --repo <owner>/<repo>
   ```

   Project tokens only work for their own project. A token from another site fails with `unauthorized` when Dokploy pulls the image.
3. **Dokploy token.** Make `DOKPLOY_TOKEN`, a Dokploy API key, available to the repo the same way.
4. **Dokploy application.** Create an application with the Docker provider. Set the domain's container port to **8080**. Put the application ID from its dashboard URL in `DOKPLOY_APP_ID`. Turn off Dokploy's own autodeploy, because the workflow triggers deploys.
5. **Connect the repo** to Depot CI in the Depot dashboard, then push to `main`.

Run the workflow without pushing:

```bash
depot ci dispatch --repo <owner>/<repo> --workflow build-production.yml --ref main
depot ci status <run-id> --wait
```

## Environment variables

- **`PUBLIC_*` values** are baked into the HTML at build time. Pass them to the build with `build-args:` in the workflow and declare them with `ARG` in the `Dockerfile` before `bun run build`. Values set only on the Dokploy app never reach a static page.
- **Secrets** never go into the build. Anything secret has to live at runtime on the Dokploy app, and only nginx may read it. See [`NEWSLETTER.md`](NEWSLETTER.md) for the pattern.
- If a site switches to Astro's server output, read secrets with `process.env.X`, not `import.meta.env.X`. Astro replaces `import.meta.env.X` at build time, and Depot builds without your secrets.

## Testing locally

```bash
podman build -t my-site:test .     # or docker
bash scripts/check-site-image.sh my-site:test
```

## Common changes

- **www redirect.** Add a server block in front of the default one:

  ```nginx
  server {
    listen 8080;
    server_name www.example.com;
    return 301 https://example.com$request_uri;
  }
  ```

- **More cached assets.** Add a `location` with its own `Cache-Control`. Use `immutable` only for files whose names change when their content changes.
- **Image cache after an Astro upgrade.** Images are re-encoded once, then cached again.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| Dokploy: `unauthorized: authentication required`, "Login failed" | `DEPOT_PULL_TOKEN` is not a token for this Depot project. |
| Redirects send visitors to `http://` | `absolute_redirect off;` is missing from the nginx config. |
| 502 from Traefik | The domain's container port in Dokploy is not 8080. |
| A `PUBLIC_*` value is empty on the live site | It was not passed as a build-arg. |
