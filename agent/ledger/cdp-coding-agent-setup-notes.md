# How The Node CDP REPL Was Made Working

Point-in-time artifact focused on the mechanics of getting the Node/CDP REPL working.

Date: 2026-06-16
Author: Brent Millare <brent.millare@gmail.com>
Repo: `chrome-developer-tools-ws`

## Starting Point

The repo already had a working Chromium launch path:

```bash
nix develop --command bash -lc './scripts/launch-chromium-cdt.sh about:blank >.cdt-logs/chromium-node.log 2>&1'
```

That launcher handled the SSH/Wayland pieces:

```bash
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
```

And it launched Chromium with local CDP enabled:

```bash
--remote-debugging-address=127.0.0.1
--remote-debugging-port="$port"
--remote-allow-origins="http://127.0.0.1:$port"
```

The question was whether a coding agent could get Clojure-REPL-like behavior against that browser: keep a session open, preserve variables, and send incremental CDP commands through a PTY.

## Step 1: Add Node To The Flake

The first change was adding Node to `flake.nix`:

```nix
pkgs.nodejs
```

Then I verified the available runtime:

```bash
nix develop --command node -e 'console.log(process.version); console.log(typeof WebSocket)'
```

Observed:

```text
v24.15.0
function
```

That mattered because Node 24 already exposes a built-in `WebSocket`, so the first implementation did not need npm, `chrome-remote-interface`, Playwright, Puppeteer, or a `package.json`.

## Step 2: Build A Tiny CDP Client

I added `scripts/cdt_node_lib.mjs`.

The client works directly against Chrome DevTools Protocol:

```text
Node process -> built-in WebSocket -> Chromium page target websocket
```

The core mechanics are:

1. Poll `http://127.0.0.1:9222/json/version` until Chromium is ready.
2. Open or select a page target through `http://127.0.0.1:9222/json/new?...` or `/json/list`.
3. Connect to `target.webSocketDebuggerUrl`.
4. Send JSON messages with incrementing `id` values:

```js
{ id, method, params }
```

5. Keep a `pending` map from CDP message id to promise resolver.
6. Resolve the matching promise when a websocket message returns the same `id`.
7. Store non-response CDP events in a bounded event buffer.

This was enough to implement:

```js
client.call('Page.enable')
client.call('Runtime.enable')
client.call('Page.navigate', { url })
client.call('Runtime.evaluate', { expression, returnByValue: true })
client.call('Input.dispatchMouseEvent', ...)
client.call('Page.captureScreenshot', ...)
```

## Step 3: Add Browser Helpers

The low-level `client.call()` worked, but it was too verbose for REPL work. I added helper functions:

```js
nav(url)
evalPage(expression)
pageSummary()
textDigest({ maxChars })
findByText(text)
clickText(text)
screenshot(path)
summarize(value)
```

The key helper was `pageSummary()`. It evaluates a small browser-side function that returns:

- page title
- capped URL
- ready state
- viewport size
- counts for links, buttons, inputs, and headings
- first 10 headings
- first 10 links

The first version accidentally returned the function object instead of invoking it:

```js
(() => ({ ... }))
```

That made the summary serialize as `{}`. The fix was to invoke it:

```js
(() => ({ ... }))()
```

## Step 4: Guard Against Large Outputs

The experiment immediately showed why output caps are necessary.

MDN page body text was large:

```text
chars: 27634
truncated: 26634
```

A generated `data:` URL also flooded output because the entire HTML document was encoded into `location.href`. The fix was to cap URLs in `pageSummary()`:

```js
url: location.href.length > 500
  ? location.href.slice(0, 500) + '... [truncated ' + (location.href.length - 500) + ' chars]'
  : location.href
```

I also added:

- string truncation in `summarize()`
- array caps in `summarize()`
- object-depth caps in `summarize()`
- normalized and capped body text in `textDigest()`
- a bounded CDP event buffer

## Step 5: Build The REPL Entrypoint

I added `scripts/cdt_node_repl.mjs`.

It connects to a page target and injects helpers into the Node REPL context:

```js
Object.assign(server.context, {
  client,
  target,
  session,
  port,
  clickText: (text, options) => clickText(client, text, options),
  evalPage: (expression, options) => evalPage(client, expression, options),
  findByText: (text, selector) => findByText(client, text, selector),
  listTargets: () => listTargets({ port }),
  nav: (nextUrl) => nav(client, nextUrl),
  pageSummary: () => pageSummary(client),
  screenshot: (path) => screenshot(client, path),
  summarize,
  textDigest: (options) => textDigest(client, options),
})
```

Then I started it in a PTY:

```bash
nix develop --command ./scripts/cdt_node_repl.mjs https://example.com/
```

Observed startup:

```text
Connected to EDCBF9295E30FAF65C4717A283A64A61 on port 9222
Helpers: client, nav(url), evalPage(expr), pageSummary(), textDigest(), findByText(text), clickText(text), screenshot(path), listTargets(), summarize(value)
cdt>
```

## Step 6: Prove Stable Session State

Inside the REPL, I created a variable:

```js
state = { notes: [], started: new Date().toISOString() }
```

Then I inspected the current page:

```js
await pageSummary()
```

Then I saved page state into the variable:

```js
state.notes.push((await pageSummary()).title); state
```

Then I navigated:

```js
await nav('https://developer.mozilla.org/en-US/docs/Web/API/Document')
```

Then I reused the same variable:

```js
state.notes.push((await pageSummary()).title); state
```

Observed:

```js
{
  notes: ['Example Domain', 'Document - Web APIs | MDN'],
  started: '2026-06-17T02:44:54.140Z'
}
```

That confirmed the important behavior: the PTY-backed Node REPL can keep agent-side variables alive while the browser target changes pages.

## Step 7: Build A Repeatable Experiment

I added `scripts/cdt_node_experiment.mjs` to run the same workflow without manual REPL input.

It performs:

1. Navigate to `https://example.com/`.
2. Summarize the page.
3. Click the `Learn more` link with CDP mouse events.
4. Navigate to an MDN page.
5. Digest large page body text without dumping it all.
6. Navigate to a generated large `data:` page.
7. Capture a screenshot.

The clean JSON capture command needed one detail: redirect inside the dev shell so the Nix shell banner does not pollute the JSON file.

Working command:

```bash
nix develop --command bash -lc './scripts/cdt_node_experiment.mjs > .cdt-logs/node-experiment-output.json'
jq '.[].step' .cdt-logs/node-experiment-output.json
```

Observed:

```text
"navigate example.com"
"click example.com Learn more"
"navigate MDN Array page"
"navigate local data page with large output"
"screenshot large output page"
```

## Verification Commands

Syntax checks:

```bash
nix develop --command node --check scripts/cdt_node_lib.mjs
nix develop --command node --check scripts/cdt_node_repl.mjs
nix develop --command node --check scripts/cdt_node_experiment.mjs
```

Flake check:

```bash
nix flake check
```

Experiment:

```bash
nix develop --command bash -lc './scripts/cdt_node_experiment.mjs > .cdt-logs/node-experiment-output.json'
jq '.[].step' .cdt-logs/node-experiment-output.json
```

## Result

The Node REPL approach is working.

The important implementation detail is that the browser session is not magic inside Codex tooling. The durable session exists because a Node process remains alive in a PTY, holds the CDP websocket open, and keeps JavaScript variables in the REPL context.

The resulting path is:

```text
Codex -> PTY shell -> Node REPL -> WebSocket CDP -> Chromium
```

This gives coding agents a practical interactive browser-control loop for UI/UX research.
