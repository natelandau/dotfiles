# daisyUI Components Reference

Complete reference of all daisyUI components with usage examples.

## Actions

### Button

```html
<!-- Basic buttons -->
<button class="btn">Button</button>
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-accent">Accent</button>
<button class="btn btn-ghost">Ghost</button>
<button class="btn btn-link">Link</button>

<!-- Button sizes -->
<button class="btn btn-xs">Tiny</button>
<button class="btn btn-sm">Small</button>
<button class="btn btn-md">Normal</button>
<button class="btn btn-lg">Large</button>

<!-- Button states -->
<button class="btn btn-active">Active</button>
<button class="btn btn-disabled">Disabled</button>
<button class="btn loading">Loading</button>

<!-- Outlined buttons -->
<button class="btn btn-outline">Outline</button>
<button class="btn btn-outline btn-primary">Primary Outline</button>

<!-- Icon buttons -->
<button class="btn btn-square">
  <svg>...</svg>
</button>
<button class="btn btn-circle">
  <svg>...</svg>
</button>
```

### Dropdown

```html
<div class="dropdown">
  <label tabindex="0" class="btn">Click</label>
  <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
    <li><a>Item 1</a></li>
    <li><a>Item 2</a></li>
  </ul>
</div>

<!-- Dropdown positions -->
<div class="dropdown dropdown-end">...</div>
<div class="dropdown dropdown-top">...</div>
<div class="dropdown dropdown-bottom">...</div>
<div class="dropdown dropdown-left">...</div>
<div class="dropdown dropdown-right">...</div>
```

### Modal

```html
<!-- Button to trigger -->
<button class="btn" onclick="my_modal.showModal()">Open Modal</button>

<!-- Modal -->
<dialog id="my_modal" class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">Hello!</h3>
    <p class="py-4">Press ESC key or click outside to close</p>
    <div class="modal-action">
      <form method="dialog">
        <button class="btn">Close</button>
      </form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button>close</button>
  </form>
</dialog>

<!-- Modal with actions -->
<dialog id="confirm_modal" class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">Confirm Action</h3>
    <p class="py-4">Are you sure?</p>
    <div class="modal-action">
      <button class="btn btn-error">Delete</button>
      <button class="btn">Cancel</button>
    </div>
  </div>
</dialog>
```

### Swap

```html
<!-- Theme toggle example -->
<label class="swap swap-rotate">
  <input type="checkbox" />
  <svg class="swap-on">...</svg>
  <svg class="swap-off">...</svg>
</label>
```

## Data Display

### Card

```html
<!-- Basic card -->
<div class="card w-96 bg-base-100 shadow-xl">
  <figure><img src="photo.jpg" alt="Photo" /></figure>
  <div class="card-body">
    <h2 class="card-title">Card Title</h2>
    <p>Description text</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Buy Now</button>
    </div>
  </div>
</div>

<!-- Card variants -->
<div class="card bg-primary text-primary-content">...</div>
<div class="card bg-neutral text-neutral-content">...</div>
<div class="card card-bordered">...</div>
<div class="card card-compact">...</div>
<div class="card card-normal">...</div>
<div class="card card-side">...</div>
```

### Badge

```html
<div class="badge">neutral</div>
<div class="badge badge-primary">primary</div>
<div class="badge badge-secondary">secondary</div>
<div class="badge badge-accent">accent</div>
<div class="badge badge-ghost">ghost</div>

<!-- Badge sizes -->
<div class="badge badge-lg">Large</div>
<div class="badge badge-md">Medium</div>
<div class="badge badge-sm">Small</div>
<div class="badge badge-xs">Tiny</div>

<!-- Badge in button -->
<button class="btn">
  Inbox
  <div class="badge">+99</div>
</button>
```

### Table

```html
<div class="overflow-x-auto">
  <table class="table">
    <thead>
      <tr>
        <th>Name</th>
        <th>Job</th>
        <th>Favorite Color</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Cy Ganderton</td>
        <td>Quality Control Specialist</td>
        <td>Blue</td>
      </tr>
    </tbody>
  </table>
</div>

<!-- Table variants -->
<table class="table table-zebra">...</table>
<table class="table table-pin-rows">...</table>
<table class="table table-pin-cols">...</table>
<table class="table table-xs">...</table>
<table class="table table-sm">...</table>
<table class="table table-md">...</table>
<table class="table table-lg">...</table>
```

### Stats

```html
<div class="stats shadow">
  <div class="stat">
    <div class="stat-figure text-primary">
      <svg>...</svg>
    </div>
    <div class="stat-title">Total Page Views</div>
    <div class="stat-value">89,400</div>
    <div class="stat-desc">21% more than last month</div>
  </div>

  <div class="stat">
    <div class="stat-figure text-secondary">
      <svg>...</svg>
    </div>
    <div class="stat-title">New Users</div>
    <div class="stat-value">4,200</div>
    <div class="stat-desc">↗︎ 400 (22%)</div>
  </div>
</div>
```

### Carousel

```html
<div class="carousel w-full">
  <div id="slide1" class="carousel-item relative w-full">
    <img src="image1.jpg" class="w-full" />
    <div class="absolute flex justify-between transform -translate-y-1/2 left-5 right-5 top-1/2">
      <a href="#slide4" class="btn btn-circle">❮</a>
      <a href="#slide2" class="btn btn-circle">❯</a>
    </div>
  </div>
  <!-- More slides... -->
</div>
```

## Data Input

### Input

```html
<input type="text" placeholder="Type here" class="input input-bordered w-full max-w-xs" />

<!-- Input variants -->
<input type="text" class="input input-primary" />
<input type="text" class="input input-secondary" />
<input type="text" class="input input-accent" />
<input type="text" class="input input-ghost" />

<!-- Input sizes -->
<input type="text" class="input input-xs" />
<input type="text" class="input input-sm" />
<input type="text" class="input input-md" />
<input type="text" class="input input-lg" />

<!-- Input states -->
<input type="text" class="input input-bordered input-success" />
<input type="text" class="input input-bordered input-warning" />
<input type="text" class="input input-bordered input-error" />
```

### Textarea

```html
<textarea class="textarea textarea-bordered" placeholder="Bio"></textarea>
<textarea class="textarea textarea-primary"></textarea>
<textarea class="textarea textarea-ghost w-full"></textarea>
```

### Checkbox

```html
<input type="checkbox" checked="checked" class="checkbox" />
<input type="checkbox" class="checkbox checkbox-primary" />
<input type="checkbox" class="checkbox checkbox-secondary" />
<input type="checkbox" class="checkbox checkbox-accent" />

<!-- Checkbox sizes -->
<input type="checkbox" class="checkbox checkbox-xs" />
<input type="checkbox" class="checkbox checkbox-sm" />
<input type="checkbox" class="checkbox checkbox-md" />
<input type="checkbox" class="checkbox checkbox-lg" />
```

### Radio

```html
<input type="radio" name="radio-1" class="radio" checked />
<input type="radio" name="radio-1" class="radio" />

<input type="radio" class="radio radio-primary" />
<input type="radio" class="radio radio-secondary" />
<input type="radio" class="radio radio-accent" />
```

### Select

```html
<select class="select select-bordered w-full max-w-xs">
  <option disabled selected>Pick one</option>
  <option>Option 1</option>
  <option>Option 2</option>
</select>

<!-- Select variants -->
<select class="select select-primary">...</select>
<select class="select select-ghost">...</select>
```

### Toggle

```html
<input type="checkbox" class="toggle" checked />
<input type="checkbox" class="toggle toggle-primary" />
<input type="checkbox" class="toggle toggle-secondary" />
<input type="checkbox" class="toggle toggle-accent" />

<!-- Toggle sizes -->
<input type="checkbox" class="toggle toggle-xs" />
<input type="checkbox" class="toggle toggle-sm" />
<input type="checkbox" class="toggle toggle-md" />
<input type="checkbox" class="toggle toggle-lg" />
```

## Navigation

### Navbar

```html
<div class="navbar bg-base-100">
  <div class="flex-1">
    <a class="btn btn-ghost text-xl">daisyUI</a>
  </div>
  <div class="flex-none">
    <ul class="menu menu-horizontal px-1">
      <li><a>Link</a></li>
      <li>
        <details>
          <summary>Parent</summary>
          <ul class="p-2 bg-base-100">
            <li><a>Link 1</a></li>
            <li><a>Link 2</a></li>
          </ul>
        </details>
      </li>
    </ul>
  </div>
</div>
```

### Menu

```html
<ul class="menu bg-base-200 w-56 rounded-box">
  <li><a>Item 1</a></li>
  <li><a>Item 2</a></li>
  <li><a>Item 3</a></li>
</ul>

<!-- Menu with submenu -->
<ul class="menu bg-base-200 w-56 rounded-box">
  <li><a>Item 1</a></li>
  <li>
    <details open>
      <summary>Parent</summary>
      <ul>
        <li><a>Submenu 1</a></li>
        <li><a>Submenu 2</a></li>
      </ul>
    </details>
  </li>
</ul>
```

### Tabs

```html
<div class="tabs">
  <a class="tab">Tab 1</a>
  <a class="tab tab-active">Tab 2</a>
  <a class="tab">Tab 3</a>
</div>

<!-- Tab variants -->
<div class="tabs tabs-boxed">...</div>
<div class="tabs tabs-bordered">...</div>
<div class="tabs tabs-lifted">...</div>
```

### Breadcrumbs

```html
<div class="text-sm breadcrumbs">
  <ul>
    <li><a>Home</a></li>
    <li><a>Documents</a></li>
    <li>Add Document</li>
  </ul>
</div>
```

## Feedback

### Alert

```html
<div class="alert">
  <svg>...</svg>
  <span>12 unread messages.</span>
</div>

<!-- Alert variants -->
<div class="alert alert-info">...</div>
<div class="alert alert-success">...</div>
<div class="alert alert-warning">...</div>
<div class="alert alert-error">...</div>
```

### Progress

```html
<progress class="progress w-56"></progress>
<progress class="progress progress-primary w-56" value="70" max="100"></progress>
<progress class="progress progress-secondary w-56" value="40" max="100"></progress>
```

### Loading

```html
<span class="loading loading-spinner loading-xs"></span>
<span class="loading loading-spinner loading-sm"></span>
<span class="loading loading-spinner loading-md"></span>
<span class="loading loading-spinner loading-lg"></span>

<!-- Loading variants -->
<span class="loading loading-dots"></span>
<span class="loading loading-ring"></span>
<span class="loading loading-ball"></span>
<span class="loading loading-bars"></span>
```

### Toast

```html
<div class="toast">
  <div class="alert alert-info">
    <span>New message arrived.</span>
  </div>
</div>

<!-- Toast positions -->
<div class="toast toast-top toast-end">...</div>
<div class="toast toast-bottom toast-start">...</div>
```

### Tooltip

```html
<div class="tooltip" data-tip="hello">
  <button class="btn">Hover me</button>
</div>

<!-- Tooltip positions -->
<div class="tooltip tooltip-right" data-tip="right">...</div>
<div class="tooltip tooltip-bottom" data-tip="bottom">...</div>
<div class="tooltip tooltip-left" data-tip="left">...</div>
```

## Layout

### Drawer

```html
<div class="drawer">
  <input id="my-drawer" type="checkbox" class="drawer-toggle" />
  <div class="drawer-content">
    <label for="my-drawer" class="btn btn-primary drawer-button">Open drawer</label>
  </div>
  <div class="drawer-side">
    <label for="my-drawer" class="drawer-overlay"></label>
    <ul class="menu p-4 w-80 min-h-full bg-base-200 text-base-content">
      <li><a>Sidebar Item 1</a></li>
      <li><a>Sidebar Item 2</a></li>
    </ul>
  </div>
</div>
```

### Hero

```html
<div class="hero min-h-screen" style="background-image: url(bg.jpg);">
  <div class="hero-overlay bg-opacity-60"></div>
  <div class="hero-content text-center text-neutral-content">
    <div class="max-w-md">
      <h1 class="mb-5 text-5xl font-bold">Hello there</h1>
      <p class="mb-5">Provident cupiditate voluptatem...</p>
      <button class="btn btn-primary">Get Started</button>
    </div>
  </div>
</div>
```

### Footer

```html
<footer class="footer p-10 bg-neutral text-neutral-content">
  <nav>
    <h6 class="footer-title">Services</h6>
    <a class="link link-hover">Branding</a>
    <a class="link link-hover">Design</a>
  </nav>
  <nav>
    <h6 class="footer-title">Company</h6>
    <a class="link link-hover">About us</a>
    <a class="link link-hover">Contact</a>
  </nav>
</footer>
```

This reference covers all major daisyUI components. Consult the official daisyUI documentation for additional variants and customization options.
