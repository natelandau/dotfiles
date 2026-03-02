---
name: htmx-expert
description: Use when writing, debugging, or reviewing htmx attributes (hx-get, hx-post, hx-swap, hx-target, hx-trigger), AJAX interactions, server-side HTML fragment responses, out-of-band swaps, htmx events, loading indicators, or hypermedia-driven patterns
---

# htmx Expert

Comprehensive reference for htmx development — the library that extends HTML to access modern browser features directly without JavaScript.

## Core Philosophy

Servers respond with HTML fragments, not JSON. htmx extends HTML to handle AJAX requests, CSS transitions, WebSockets, and Server-Sent Events directly.

## Core Attributes Reference

### HTTP Verb Attributes

| Attribute   | Purpose              | Default Trigger      |
| ----------- | -------------------- | -------------------- |
| `hx-get`    | Issue GET request    | click                |
| `hx-post`   | Issue POST request   | click (form: submit) |
| `hx-put`    | Issue PUT request    | click                |
| `hx-patch`  | Issue PATCH request  | click                |
| `hx-delete` | Issue DELETE request | click                |

### Request Control

- **hx-trigger**: Customize when requests fire
    - Modifiers: `changed`, `delay:Xms`, `throttle:Xms`, `once`
    - Special triggers: `load`, `revealed`, `every Xs`
    - Extended: `from:<selector>`, `target:<selector>`
- **hx-include**: Include additional element values in request
- **hx-params**: Filter which parameters to send (`*`, `none`, `not <param>`, `<param>`)
- **hx-headers**: Add custom headers (JSON format)
- **hx-vals**: Add values to request (JSON format)
- **hx-encoding**: Set encoding (`multipart/form-data` for file uploads)

### Response Handling

- **hx-target**: Where to place response content
    - Extended selectors: `this`, `closest <sel>`, `next <sel>`, `previous <sel>`, `find <sel>`
- **hx-swap**: How to insert content
    - `innerHTML` (default), `outerHTML`, `beforebegin`, `afterbegin`, `beforeend`, `afterend`, `delete`, `none`
    - Modifiers: `swap:Xms`, `settle:Xms`, `scroll:top`, `show:top`
- **hx-select**: Select subset of response to swap
- **hx-select-oob**: Select elements for out-of-band swaps

### State Management

- **hx-push-url**: Push URL to browser history
- **hx-replace-url**: Replace current URL in history
- **hx-history**: Control history snapshot behavior
- **hx-history-elt**: Specify element to snapshot

### UI Indicators

- **hx-indicator**: Element to show during request (add `htmx-indicator` class)
- **hx-disabled-elt**: Elements to disable during request

### Security & Control

- **hx-confirm**: Show confirmation dialog before request
- **hx-validate**: Enable HTML5 validation on non-form elements
- **hx-disable**: Disable htmx processing on element and descendants
- **hx-sync**: Coordinate requests between elements

## Implementation Patterns

### Basic AJAX

```html
<button hx-get="/api/data" hx-target="#result" hx-swap="innerHTML">Load Data</button>
<div id="result"></div>
```

### Active Search

```html
<input
    type="search"
    name="q"
    hx-get="/search"
    hx-trigger="input changed delay:300ms, search"
    hx-target="#search-results" />
<div id="search-results"></div>
```

Use `input changed` instead of `keyup changed` (catches paste, autofill). The `search` trigger handles the clear button (X).

### Infinite Scroll

```html
<div hx-get="/items?page=2" hx-trigger="revealed" hx-swap="afterend">Loading more...</div>
```

### Polling

```html
<div hx-get="/status" hx-trigger="every 5s" hx-swap="innerHTML">Status: Unknown</div>
```

### Form Submission

```html
<form hx-post="/submit" hx-target="#response" hx-swap="outerHTML">
    <input name="email" type="email" required />
    <button type="submit">Submit</button>
</form>
```

### Out-of-Band Updates

Server response can update multiple elements:

```html
<!-- Main response -->
<div id="main-content">Updated content</div>

<!-- OOB updates -->
<div id="notification" hx-swap-oob="true">New notification!</div>
<span id="counter" hx-swap-oob="true">42</span>
```

### Loading Indicators

```html
<button hx-get="/slow-endpoint" hx-indicator="#spinner">Load</button>
<img id="spinner" class="htmx-indicator" src="/spinner.gif" />
```

CSS for indicators:

```css
.htmx-indicator {
    opacity: 0;
    transition: opacity 200ms ease-in;
}
.htmx-request .htmx-indicator {
    opacity: 1;
}
```

CSS-only spinner (preferred over image files):

```css
.htmx-indicator {
    display: none;
}
.htmx-request .htmx-indicator {
    display: inline-block;
}
.spinner {
    width: 20px;
    height: 20px;
    border: 2px solid #f3f3f3;
    border-top: 2px solid #3d72d7;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}
@keyframes spin {
    0% {
        transform: rotate(0deg);
    }
    100% {
        transform: rotate(360deg);
    }
}
```

### Form POST with Loading State

Combine `hx-indicator` and `hx-disabled-elt` for complete UX:

```html
<form hx-post="/api/submit" hx-target="#result" hx-indicator="#spinner" hx-disabled-elt="find button">
    <input name="email" required />
    <button type="submit">
        Submit
        <span id="spinner" class="spinner htmx-indicator"></span>
    </button>
</form>
```

### Row Updates with closest

```html
<li id="item-1">
    <span>Item 1</span>
    <button hx-get="/api/update-item/1" hx-target="closest li" hx-swap="outerHTML">Update</button>
</li>
```

Server returns complete `<li>` element with new htmx attributes intact.

### Combining Multiple Triggers

```html
<div hx-get="/api/data" hx-trigger="load, every 5s, click from:#refresh-btn"></div>
```

## Server Response Patterns

### Return HTML Fragments

Server endpoints return HTML, not JSON:

```python
@app.route('/search')
def search():
    q = request.args.get('q', '')
    results = search_database(q)
    return render_template('_search_results.html', results=results)
```

### Response Headers

| Header                    | Purpose                             |
| ------------------------- | ----------------------------------- |
| `HX-Location`             | Client-side redirect (with context) |
| `HX-Push-Url`             | Push URL to history                 |
| `HX-Redirect`             | Full page redirect                  |
| `HX-Refresh`              | Refresh the page                    |
| `HX-Reswap`               | Override hx-swap value              |
| `HX-Retarget`             | Override hx-target value            |
| `HX-Trigger`              | Trigger client-side events          |
| `HX-Trigger-After-Settle` | Trigger after settle                |
| `HX-Trigger-After-Swap`   | Trigger after swap                  |

### Detect htmx Requests

```python
if request.headers.get('HX-Request'):
    return render_template('_partial.html')
else:
    return render_template('full_page.html')
```

## Events

### Key Events

| Event                      | When Fired                                  |
| -------------------------- | ------------------------------------------- |
| `htmx:load`                | Element loaded into DOM                     |
| `htmx:configRequest`       | Before request sent (modify params/headers) |
| `htmx:beforeRequest`       | Before AJAX request                         |
| `htmx:afterRequest`        | After AJAX request completes                |
| `htmx:beforeSwap`          | Before content swap                         |
| `htmx:afterSwap`           | After content swap                          |
| `htmx:afterSettle`         | After DOM settles                           |
| `htmx:confirm`             | Before confirmation dialog                  |
| `htmx:validation:validate` | Custom validation hook                      |

### Event Handling

Using `hx-on*` (double colons for htmx events):

```html
<button hx-get="/data" hx-on::before-request="console.log('Starting...')" hx-on::after-swap="console.log('Done!')">
    Load
</button>
```

Using JavaScript:

```javascript
document.body.addEventListener("htmx:configRequest", function (evt) {
    evt.detail.headers["X-Custom-Header"] = "value";
});
```

## Security Best Practices

1. **Escape All User Content**: Prevent XSS through server-side template escaping
2. **Use hx-disable**: Prevent htmx processing on untrusted content
3. **Restrict Request Origins**: `htmx.config.selfRequestsOnly = true;`
4. **Disable Script Processing**: `htmx.config.allowScriptTags = false;`
5. **Include CSRF Tokens**:
    ```html
    <body hx-headers='{"X-CSRF-Token": "{{ csrf_token }}"}'></body>
    ```
6. **Content Security Policy**: Layer browser-level protections

## Configuration

```javascript
htmx.config.defaultSwapStyle = "innerHTML";
htmx.config.timeout = 0;
htmx.config.historyCacheSize = 10;
htmx.config.globalViewTransitions = false;
htmx.config.scrollBehavior = "instant"; // or 'smooth', 'auto'
htmx.config.selfRequestsOnly = false;
htmx.config.allowScriptTags = true;
htmx.config.allowEval = true;
```

Or via meta tag: `<meta name="htmx-config" content='{"selfRequestsOnly":true}' />`

## Extensions

```html
<script src="https://unpkg.com/htmx-ext-<name>@<version>/<name>.js"></script>
<body hx-ext="extension-name"></body>
```

Common: **head-support**, **idiomorph** (morphing swaps), **sse**, **ws**, **preload**, **response-targets** (HTTP status-based targeting)

## Debugging

```javascript
htmx.logAll();
```

Check Network tab headers: `HX-Request`, `HX-Target`, `HX-Trigger`, `HX-Current-URL`

## Third-Party Integration

```javascript
htmx.onLoad(function (content) {
    content.querySelectorAll(".datepicker").forEach((el) => new Datepicker(el));
});
htmx.process(document.getElementById("new-content")); // for programmatically added content
```

## Common Gotchas

1. **ID Stability**: Keep element IDs stable for CSS transitions
2. **Swap Timing**: Default 0ms swap delay; use `swap:100ms` for transitions
3. **Event Bubbling**: htmx events bubble; use `event.detail` for data
4. **Form Data**: Only named inputs are included in requests
5. **History**: History snapshots store innerHTML, not full DOM state
6. **file:// won't work**: htmx requires HTTP — always serve via HTTP server

## Progressive Enhancement

```html
<form action="/search" method="POST">
    <input name="q" hx-get="/search" hx-trigger="keyup changed delay:300ms" hx-target="#results" />
    <button type="submit">Search</button>
</form>
<div id="results"></div>
```

Non-JavaScript users get form submission; JavaScript users get AJAX.
