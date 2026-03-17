# htmx Extensions Reference

In htmx 2.x, extensions are separate packages loaded via `<script>` tags and activated with `hx-ext`. Extensions are installed from `https://unpkg.com/htmx-ext-<name>@<version>/<name>.js`.

## Table of Contents

- [Idiomorph (Morph Swaps)](#idiomorph-morph-swaps)
- [SSE (Server-Sent Events)](#sse-server-sent-events)
- [WebSockets](#websockets)
- [Head Support](#head-support)
- [Response Targets](#response-targets)
- [Preload](#preload)
- [Loading States](#loading-states)
- [Multi-Swap](#multi-swap)

---

## Idiomorph (Morph Swaps)

Morphs the existing DOM into the new HTML instead of replacing it. This preserves focus, scroll position, form input values, CSS transitions, and other DOM state that a naive innerHTML swap would destroy.

```html
<script src="https://unpkg.com/idiomorph@0.3.0/dist/idiomorph-ext.min.js"></script>
<body hx-ext="morph">
    <div hx-get="/updated-content" hx-swap="morph" hx-target="#content">
        Refresh
    </div>
    <div id="content">
        <!-- DOM is morphed, not replaced — form state and focus survive -->
        <input name="search" />
        <ul id="results">...</ul>
    </div>
</body>
```

Swap values: `morph` (morph innerHTML), `morph:outerHTML` (morph the entire element), `morph:innerHTML` (explicit innerHTML morph).

Use morph swaps when:
- The swapped region contains form inputs (preserves values and focus)
- You need smooth CSS transitions between states
- The old and new HTML share structure but differ in content

## SSE (Server-Sent Events)

Moved from core htmx to an extension in 2.x. Establishes a one-way server-to-client event stream over HTTP.

```html
<script src="https://unpkg.com/htmx-ext-sse@2.2.0/sse.js"></script>

<!-- Connect to SSE endpoint -->
<div hx-ext="sse" sse-connect="/events">
    <!-- Swap content when "message" event arrives -->
    <div sse-swap="message"></div>

    <!-- Swap content on a named event -->
    <div sse-swap="newNotification" hx-target="#notifications"></div>

    <!-- Use SSE events as htmx triggers -->
    <div hx-get="/latest" hx-trigger="sse:update"></div>
</div>
```

Server-side (Python example):

```python
def event_stream():
    while True:
        data = get_latest_data()
        yield f"event: message\ndata: <div>{data}</div>\n\n"

@app.route('/events')
def sse():
    return Response(event_stream(), mimetype='text/event-stream')
```

The `sse-swap` attribute listens for a named SSE event and swaps its data (which should be HTML) into the element.

## WebSockets

Moved from core htmx to an extension in 2.x. Provides bidirectional communication.

```html
<script src="https://unpkg.com/htmx-ext-ws@2.0.0/ws.js"></script>

<div hx-ext="ws" ws-connect="/ws">
    <!-- Send form data over WebSocket -->
    <form ws-send>
        <input name="message" />
        <button type="submit">Send</button>
    </form>

    <!-- Incoming messages are swapped by matching element IDs -->
    <div id="chat-messages"></div>
</div>
```

When the server sends HTML with an element that has an `id`, htmx finds the matching element on the page and swaps it. This follows the same pattern as OOB swaps.

## Head Support

Merges `<head>` element changes from htmx responses. Without this extension, htmx ignores the `<head>` tag in responses entirely — so title changes, new stylesheets, and meta tags won't be applied.

```html
<script src="https://unpkg.com/htmx-ext-head-support@2.0.0/head-support.js"></script>
<body hx-ext="head-support">...</body>
```

With head-support enabled, htmx responses that include a `<head>` tag will:
- Update `<title>`
- Add new `<link>` and `<style>` tags
- Add new `<meta>` tags
- Remove tags marked with `head-support-remove`

Particularly useful with `hx-boost`, where navigating between pages should update the document title and load page-specific CSS.

## Response Targets

Target different elements based on HTTP response status codes. Without this, error responses (4xx, 5xx) swap into the same target as success responses, which usually isn't what you want.

```html
<script src="https://unpkg.com/htmx-ext-response-targets@2.0.0/response-targets.js"></script>

<body hx-ext="response-targets">
    <form hx-post="/submit"
          hx-target="#result"
          hx-target-400="#form-errors"
          hx-target-500="#server-error"
          hx-target-error="#generic-error">
        <input name="email" required />
        <button type="submit">Submit</button>
    </form>

    <div id="result"></div>
    <div id="form-errors"></div>
    <div id="server-error"></div>
    <div id="generic-error"></div>
</body>
```

Attributes:
- `hx-target-<status>` — target for a specific status code (e.g., `hx-target-404`)
- `hx-target-<range>` — target for a range (e.g., `hx-target-4*` for all 4xx, `hx-target-5*` for all 5xx)
- `hx-target-error` — target for any non-2xx response

## Preload

Prefetch content on `mousedown` or hover, so it's ready by the time the user clicks. Reduces perceived latency.

```html
<script src="https://unpkg.com/htmx-ext-preload@2.0.0/preload.js"></script>

<body hx-ext="preload">
    <!-- Preloads on mousedown (default) -->
    <a hx-get="/page" preload>Next Page</a>

    <!-- Preloads on hover with a delay -->
    <a hx-get="/page" preload="mouseover" preload-delay="100ms">Next Page</a>
</body>
```

Preload strategies: `mousedown` (default, ~100ms head start), `mouseover` (triggers on hover).

## Loading States

Adds CSS classes to elements during request lifecycle, giving finer control than `hx-indicator`.

```html
<script src="https://unpkg.com/htmx-ext-loading-states@2.0.0/loading-states.js"></script>

<div hx-ext="loading-states">
    <button hx-get="/data"
            data-loading-class="opacity-50 cursor-wait"
            data-loading-disable>
        Load Data
    </button>

    <div data-loading-class="animate-pulse"
         data-loading-path="/data">
        Content area
    </div>
</div>
```

Attributes:
- `data-loading-class` — CSS classes to add during loading
- `data-loading-class-remove` — CSS classes to remove during loading
- `data-loading-disable` — disable the element during loading
- `data-loading-path` — only activate when a specific path is being requested

## Multi-Swap

Swap multiple targets from a single response without using OOB swaps. Useful when the server wants to explicitly declare which parts of the page to update.

```html
<script src="https://unpkg.com/htmx-ext-multi-swap@2.0.0/multi-swap.js"></script>

<button hx-get="/dashboard-update"
        hx-ext="multi-swap"
        hx-swap="multi:#stats:innerHTML,#notifications:innerHTML,#chart:outerHTML">
    Refresh Dashboard
</button>
```

The `hx-swap` value is a comma-separated list of `#selector:swapStyle` pairs.
