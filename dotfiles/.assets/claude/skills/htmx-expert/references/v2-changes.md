# htmx 2.x Changes from 1.x

Reference for migrating from htmx 1.x to 2.x. If you're starting fresh with htmx 2.x, most of this won't matter — the main SKILL.md already reflects 2.x patterns.

## Breaking Changes

### Extensions Are Separate Packages

In 1.x, extensions like SSE, WebSockets, and others were bundled with htmx or available from the same repo. In 2.x, all extensions are separate npm packages:

```html
<!-- 1.x style (no longer works) -->
<script src="https://unpkg.com/htmx.org/dist/ext/sse.js"></script>

<!-- 2.x style -->
<script src="https://unpkg.com/htmx-ext-sse@2.2.0/sse.js"></script>
```

### `hx-on` Syntax Changed

The 1.x wildcard `hx-on` attribute (`hx-on="click: doSomething()"`) is removed. Use the `hx-on:` prefix form exclusively:

```html
<!-- 1.x (removed) -->
<button hx-on="click: doSomething()">Click</button>
<button hx-on="htmx:afterSwap: handleSwap()">Click</button>

<!-- 2.x -->
<button hx-on:click="doSomething()">Click</button>
<button hx-on::after-swap="handleSwap()">Click</button>
```

For htmx-namespaced events, use double colon (`hx-on::event-name`). For standard DOM events, single colon (`hx-on:click`).

### IE Support Dropped

htmx 2.x requires modern browsers. No IE11 polyfills needed.

### `hx-boost` Behavior

Boosted forms and links now follow more consistent rules around history and URL handling.

### Default `hx-swap` for Boosted Elements

Boosted elements use `innerHTML` on the `<body>` by default (same as 1.x), but the behavior around `hx-select` and `hx-target` on boosted elements is more predictable.

### `htmx.config.selfRequestsOnly` Default

In 2.x, `selfRequestsOnly` defaults to `true` (was `false` in 1.x). This means htmx will only allow requests to the same domain by default — a security improvement. To allow cross-origin requests, explicitly set it to `false`.

### Removed Deprecated Attributes

These 1.x attributes are no longer recognized:
- `hx-sse` — use the SSE extension with `sse-connect` and `sse-swap` instead
- `hx-ws` — use the WebSocket extension with `ws-connect` and `ws-send` instead

## Non-Breaking Improvements

### View Transitions API

htmx 2.x has improved integration with the View Transitions API:
- `transition:true` swap modifier
- `htmx.config.globalViewTransitions` configuration
- Works with the `head-support` extension for full SPA-like navigation

### Improved `hx-disabled-elt`

The `hx-disabled-elt` attribute now supports the same extended CSS selectors as `hx-target` (`closest`, `find`, `next`, `previous`).

### Better Error Handling

Response error handling is more consistent — `htmx:responseError` events provide better detail.

## Compatibility Shim

If you're migrating a large 1.x codebase and need time, there's an official compatibility extension:

```html
<script src="https://unpkg.com/htmx-ext-htmx-1-compat/htmx-1-compat.js"></script>
<body hx-ext="htmx-1-compat">
    <!-- 1.x behaviors restored -->
</body>
```

This rolls back most 2.x behavioral changes to 1.x defaults. Use it as a bridge during migration, not as a long-term solution.
