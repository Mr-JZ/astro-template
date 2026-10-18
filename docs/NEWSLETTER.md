# Newsletter signups through nginx

A static site can still have a working newsletter form, without a Node server and without exposing an API key. A small njs script inside nginx handles one route, `/api/newsletter/subscribe/`:

1. The browser POSTs `{ "email": "..." }` to the site's own domain.
2. nginx rate-limits the request and checks the email.
3. nginx adds the useSend API key from the container environment and creates the contact in useSend.

The key lives only on the Dokploy app. It is never in the HTML, the JavaScript, the Docker image or Depot CI. The njs module ships with the nginx image and adds no measurable RAM.

This setup runs in production on seallift.com.

## Why not call useSend from the browser

- **Every useSend API key has full access.** The "Sending" permission is stored but not enforced. A key in the browser lets anyone send email from your domains, read or delete every contact, and run campaigns.
- **useSend does not validate emails.** The contact API accepts any string, so nginx checks the address before forwarding it. Invalid addresses in a contact book cause bounces and hurt your sending reputation.

## Setup

These steps build on [`DEPLOYMENT.md`](DEPLOYMENT.md).

### 1. Add `deploy/newsletter.js`

Set the useSend URL and your contact book ID.

```js
const USESEND_CONTACTS_URL =
  'https://usesend.zisenis.digital/api/v1/contactBooks/<contact-book-id>/contacts'
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function json(r, status, data) {
  r.headersOut['Content-Type'] = 'application/json'
  r.return(status, JSON.stringify(data))
}

function name(value) {
  return typeof value === 'string' ? value.trim().slice(0, 100) : ''
}

async function subscribe(r) {
  // The key only exists in the container environment, so it never reaches the browser.
  const apiKey = process.env.USESEND_API_KEY
  if (!apiKey) {
    r.error('USESEND_API_KEY is not set')
    return json(r, 503, { error: 'Newsletter is unavailable' })
  }

  let body
  try {
    body = JSON.parse(r.requestText || '')
  } catch (e) {
    return json(r, 400, { error: 'Invalid request body' })
  }

  const email = body && body.email
  if (!email || typeof email !== 'string' || !EMAIL_REGEX.test(email)) {
    return json(r, 400, { error: 'A valid email is required' })
  }

  try {
    const res = await ngx.fetch(USESEND_CONTACTS_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        email: email.trim().toLowerCase(),
        firstName: name(body.firstName),
        lastName: name(body.lastName),
      }),
    })

    if (!res.ok) {
      r.error(`useSend error ${res.status}: ${await res.text()}`)
      return json(r, 500, { error: 'Failed to subscribe' })
    }

    return json(r, 200, { success: true })
  } catch (e) {
    r.error(`Subscribe error: ${e}`)
    return json(r, 500, { error: 'An unexpected error occurred' })
  }
}

export default { subscribe }
```

### 2. Turn `deploy/nginx.conf` into a template

Rename it to `deploy/nginx.conf.template`. At startup, the nginx entrypoint writes the container's DNS servers into `${NGINX_LOCAL_RESOLVERS}`, and njs needs them to look up useSend. Add the marked parts:

```nginx
server_tokens off;

# Newsletter: load the handler and rate-limit per visitor.
js_import newsletter from /etc/nginx/njs/newsletter.js;

# Behind Cloudflare the socket address is a proxy, so use the visitor IP Cloudflare forwards.
map $http_cf_connecting_ip $newsletter_client {
  "" $binary_remote_addr;
  default $http_cf_connecting_ip;
}
limit_req_zone $newsletter_client zone=newsletter:1m rate=5r/m;

server {
  listen 8080 default_server;
  # ... everything from deploy/nginx.conf stays ...

  # Newsletter: DNS and TLS for ngx.fetch.
  resolver ${NGINX_LOCAL_RESOLVERS} valid=300s ipv6=off;
  js_fetch_trusted_certificate /etc/ssl/certs/ca-certificates.crt;

  location = /api/newsletter/subscribe/ {
    limit_except POST { deny all; }
    limit_req zone=newsletter burst=4 nodelay;
    limit_req_status 429;
    client_max_body_size 4k;
    client_body_buffer_size 4k;
    js_content newsletter.subscribe;
  }
}
```

### 3. Update the `Dockerfile` runtime stage

```dockerfile
FROM nginxinc/nginx-unprivileged:1.30.6-alpine
USER root
# njs runs the newsletter handler; nginx hides environment variables from it unless they are declared.
RUN sed -i '1i load_module modules/ngx_http_js_module.so;\nenv USESEND_API_KEY;' /etc/nginx/nginx.conf
USER 101
# The entrypoint only substitutes the DNS servers it detects, never nginx's own $variables.
ENV NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1 NGINX_ENVSUBST_FILTER=^NGINX_LOCAL_RESOLVERS$
COPY deploy/newsletter.js /etc/nginx/njs/newsletter.js
COPY deploy/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
```

`NGINX_ENVSUBST_FILTER` matters. Without it, the entrypoint would also replace any `$name` in the config that matches an environment variable on the Dokploy app.

### 4. Allow the new files in `.dockerignore`

Replace `!deploy/nginx.conf` with:

```
!deploy/newsletter.js
!deploy/nginx.conf.template
```

### 5. Set the key on the Dokploy app

Add `USESEND_API_KEY` under the application's Environment tab. Don't add it to Depot CI or as a build-arg, because the build never needs it. Redeploy after changing it.

### 6. The form

Use the trailing slash. The form only needs `response.ok`:

```astro
<form id="newsletter">
  <input type="email" name="email" required />
  <button type="submit">Subscribe</button>
  <p data-message hidden></p>
</form>

<script>
  const form = document.querySelector<HTMLFormElement>('#newsletter')!
  const message = form.querySelector<HTMLElement>('[data-message]')!

  form.addEventListener('submit', async (event) => {
    event.preventDefault()
    const email = new FormData(form).get('email')
    const response = await fetch('/api/newsletter/subscribe/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    }).catch(() => null)

    message.textContent = response?.ok ? 'Thanks for subscribing!' : 'Something went wrong. Please try again.'
    message.hidden = false
    if (response?.ok) form.reset()
  })
</script>
```

Add a consent checkbox and link the privacy policy if the site needs it under GDPR.

## Testing

Test with a fake key. useSend rejects it, which proves that DNS, TLS and the request work without creating a real contact.

```bash
podman build -t my-site:test .
podman run -d --name nl-test -p 3101:8080 -e USESEND_API_KEY=fake-test-key my-site:test
url=http://localhost:3101/api/newsletter/subscribe/

curl -s -w ' %{http_code}\n' "$url"                                         # 403: GET is refused
curl -s -w ' %{http_code}\n' -X POST -d 'x' "$url"                          # 400: Invalid request body
curl -s -w ' %{http_code}\n' -X POST -d '{"email":"nope"}' "$url"           # 400: A valid email is required
curl -s -w ' %{http_code}\n' -X POST -d '{"email":"probe@example.com"}' "$url"  # 500: Failed to subscribe
podman logs nl-test 2>&1 | grep 'useSend error'                             # useSend answered: Authentication failed
podman rm -f nl-test
```

Without `USESEND_API_KEY`, only this route answers 503, and the rest of the site keeps working. After deploying, do one signup with your own address and check that it appears in the useSend contact book.

## Security notes

- Visitors can only add contacts. They can't read, change or delete them, or send email.
- nginx forwards only the email and names it builds itself. Visitor cookies and headers never reach useSend.
- The rate limit trusts `CF-Connecting-IP`. If someone reaches the server directly, bypassing Cloudflare, they can dodge the limit, but they can't do anything else.
- Turn on double opt-in for the contact book in useSend (`doubleOptInEnabled`), so nobody can sign up someone else's address.
