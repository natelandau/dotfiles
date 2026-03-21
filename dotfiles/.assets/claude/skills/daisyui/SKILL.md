---
name: daisyui
# prettier-ignore
description: Complete guide for building UIs with daisyUI v5 and Tailwind CSS — components, forms, theming, and responsive design. Use when building any user interface with daisyUI or Tailwind CSS, implementing UI components (buttons, cards, modals, tables, navbars), creating forms (inputs, selects, textareas, validation), configuring themes, or migrating from daisyUI v4 to v5. Also use when the user mentions daisyUI class names like btn, card, fieldset, input, select, or any daisyUI component patterns.
---

# daisyUI v5

## Installation

```bash
npm install -D daisyui@latest
```

Configure `tailwind.config.js`:

```javascript
module.exports = {
    plugins: [require("daisyui")],
};
```

For detailed installation options and CDN usage, see `references/installation.md`.

## Component Categories

daisyUI provides semantic CSS classes across these categories:

- **Actions**: Buttons, dropdowns, modals, swap
- **Data Display**: Cards, badges, tables, carousels, stats
- **Data Input**: Input, textarea, select, checkbox, radio, toggle
- **Navigation**: Navbar, menu, tabs, breadcrumbs, pagination, dock
- **Feedback**: Alert, progress, loading, toast, tooltip
- **Layout**: Drawer, footer, hero, stack, divider

For complete component examples, see `references/components.md`.

## Forms (v5 Patterns)

v5 changed form structure significantly from v4. The old `form-control`/`label-text` pattern is replaced with `fieldset`/`fieldset-legend`.

### Standard Input

```html
<fieldset class="fieldset">
    <legend class="fieldset-legend">Email</legend>
    <label class="validator input w-full">
        <input type="email" name="email" placeholder="Email" class="grow" required />
    </label>
</fieldset>
```

### Key Form Rules

- **Input wrapper**: `<label class="input w-full">` contains `<input class="grow">`
- **Validation**: Add `validator` class to the label for automatic validation UI
- **Selects**: Apply `select` class directly to `<select>` — no wrapper label
- **Textareas**: Apply `textarea` class directly — no `-bordered` suffix in v5
- **Helper text**: Use `<p class="label">` below inputs
- **Spacing**: Use `space-y-4` on forms for consistent field spacing
- **Always add `w-full`** to `<label class="input">` for full-width inputs

### Select (No Wrapper)

```html
<fieldset class="fieldset">
    <legend class="fieldset-legend">Choose option</legend>
    <select name="type" class="select w-full" required>
        <option value="" disabled>Select type</option>
        <option value="meeting">Meeting</option>
    </select>
</fieldset>
```

### Common v4 → v5 Mistakes

| v4 (wrong)                                | v5 (correct)                                       |
| ----------------------------------------- | -------------------------------------------------- |
| `<div class="form-control">`              | `<fieldset class="fieldset">`                      |
| `<label><span class="label-text">`        | `<legend class="fieldset-legend">`                 |
| `<input class="input-bordered input">`    | `<label class="input w-full"><input class="grow">` |
| `<select class="select-bordered select">` | `<select class="select w-full">`                   |
| `<textarea class="textarea-bordered">`    | `<textarea class="textarea w-full">`               |
| `<nav class="btm-nav">`                   | `<div class="dock">`                               |

For complete form examples, validation patterns, error handling, and textarea patterns, see `references/forms.md`.

## Theming

Set theme via HTML attribute:

```html
<html data-theme="cupcake"></html>
```

Available themes: light, dark, cupcake, bumblebee, emerald, corporate, synthwave, retro, cyberpunk, valentine, halloween, garden, forest, aqua, lofi, pastel, fantasy, wireframe, black, luxury, dracula, cmyk, autumn, business, acid, lemonade, night, coffee, winter, dim, nord, sunset

For advanced theming and custom theme creation, see `references/theming.md`.

## Responsive Design

daisyUI components work with Tailwind's responsive prefixes:

```html
<button class="btn btn-sm md:btn-md lg:btn-lg">Responsive Button</button>

<div class="card w-full md:w-96">
    <!-- Responsive card -->
</div>
```

## Tailwind Forms Plugin Conflict

If using `@tailwindcss/forms`, it causes a double focus ring on daisyUI inputs. Add this CSS fix:

```css
.input:has(input:focus) {
    outline: 2px solid var(--input-color, var(--color-base-content));
    outline-offset: 2px;
}

.input input:focus {
    outline: none;
    box-shadow: none;
}
```

## Quick Examples

### Button

```html
<button class="btn btn-primary">Primary</button>
<button class="btn btn-outline btn-secondary">Outlined</button>
<button class="btn btn-sm">Small</button>
```

### Card

```html
<div class="card w-96 bg-base-100 shadow-xl">
    <figure><img src="image.jpg" alt="Image" /></figure>
    <div class="card-body">
        <h2 class="card-title">Title</h2>
        <p>Description</p>
        <div class="card-actions justify-end">
            <button class="btn btn-primary">Action</button>
        </div>
    </div>
</div>
```

### Modal

```html
<button class="btn" onclick="my_modal.showModal()">Open</button>
<dialog id="my_modal" class="modal">
    <div class="modal-box">
        <h3 class="font-bold text-lg">Title</h3>
        <p class="py-4">Content</p>
        <div class="modal-action">
            <form method="dialog">
                <button class="btn">Close</button>
            </form>
        </div>
    </div>
</dialog>
```

## When to Consult References

- **Complete component list with all variants**: `references/components.md`
- **Detailed form patterns, validation, error handling**: `references/forms.md`

## Key Principles

- **Semantic over utility**: Use daisyUI component classes for common patterns
- **Utility for customization**: Apply Tailwind utilities for unique styling
- **Theme-aware**: Components adapt to theme colors automatically
- **Composable**: Combine components to build complex UIs
