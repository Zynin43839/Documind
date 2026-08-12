# Using `index.css`

`client/src/index.css` is the application's single global stylesheet. It imports Tailwind CSS and defines the SchemaBlue design tokens used throughout the React app.

`client/src/main.tsx` imports it once:

```tsx
import "./index.css";
```

Do not import it again from individual components. Every component rendered under `App` can use its Tailwind utilities.

## Tailwind-First Styling

Use Tailwind utility classes directly in `.tsx` files. Keep component styling in JSX unless a style cannot be expressed clearly with utilities.

```tsx
export function PageHeading() {
  return (
    <div className="bg-canvas p-6 text-ink">
      <p className="font-mono text-overline font-medium tracking-widest text-muted">
        DOCUMENTATION INTELLIGENCE
      </p>
      <h1 className="mt-1 font-mono text-headline font-bold">Welcome back</h1>
    </div>
  );
}
```

Do not use arbitrary values for colors, typography, shadows, or standard layout dimensions when a SchemaBlue token is available.

```tsx
// Prefer
<button className="bg-primary text-white hover:bg-primary-hover" />

// Avoid
<button className="bg-[#3b82f6] text-white hover:bg-[#2563eb]" />
```

## SchemaBlue Tokens

### Colors

| Purpose | Utility examples |
| --- | --- |
| Application canvas | `bg-canvas` |
| White surface | `bg-surface` |
| Primary text | `text-ink` |
| Secondary text | `text-muted` |
| Default border | `border-border` |
| Input border | `border-border-strong` |
| Main action | `bg-primary`, `text-primary` |
| Main action hover | `hover:bg-primary-hover` |
| Selected background | `bg-primary-soft` |
| Citation/relationship | `text-secondary`, `bg-secondary` |
| Success | `text-success`, `bg-success` |
| Warning | `text-warning`, `bg-warning` |
| Error | `text-danger`, `border-danger`, `bg-danger-soft` |

### Typography

Use Roboto for body content and Roboto Mono for technical labels, headings, code, and the product brand.

| Purpose | Utility |
| --- | --- |
| Body font | `font-sans` |
| Technical/headline font | `font-mono` |
| Display, 30px | `text-display` |
| Headline, 24px | `text-headline` |
| Subhead, 18px | `text-subhead` |
| Body large, 16px | `text-body-lg` |
| Body, 14px | `text-body` |
| Body small, 13px | `text-body-sm` |
| Caption, 12px | `text-caption` |
| Overline, 11px | `text-overline` |
| Code, 13px | `text-code` |

### Shape And Elevation

| Purpose | Utility |
| --- | --- |
| Small radius, 4px | `rounded-sm` |
| Default radius, 8px | `rounded-md` |
| Modal/auth radius, 12px | `rounded-lg` |
| Floating control radius, 16px | `rounded-xl` |
| Resting card shadow | `shadow-card` |
| Raised control shadow | `shadow-raised` |
| Modal shadow | `shadow-modal` |
| Overlay shadow | `shadow-overlay` |

### Layout Dimensions

| Purpose | Utility |
| --- | --- |
| Auth card maximum width, 420px | `max-w-auth` |
| Desktop sidebar width, 280px | `w-sidebar` |
| Message reading width, 800px | `max-w-reading` |
| Auth control height, 42px | `h-control` |

Tailwind's default spacing scale already follows the design system's 4px base unit. Prefer classes such as `gap-2`, `p-3`, `px-4`, `mt-6`, and `py-8`.

## Common Patterns

### Primary Button

```tsx
<button
  className="inline-flex h-control items-center justify-center gap-2 rounded-md bg-primary px-4 font-medium text-white transition-colors hover:bg-primary-hover disabled:cursor-not-allowed disabled:opacity-45"
  type="submit"
>
  Sign in
</button>
```

### Text Field

```tsx
<div className="grid gap-1">
  <label className="text-body-sm font-medium text-ink" htmlFor="email">
    Work email
  </label>
  <input
    className="h-control rounded-md border border-border-strong bg-surface px-3 text-ink outline-none transition-colors hover:border-blue-400 focus:border-primary focus:ring-3 focus:ring-primary/15 aria-[invalid=true]:border-danger aria-[invalid=true]:bg-danger-soft aria-[invalid=true]:ring-3 aria-[invalid=true]:ring-danger/10"
    id="email"
    name="email"
    type="email"
  />
  <p className="text-caption text-muted">Use your workspace email address.</p>
</div>
```

### Auth Card

```tsx
<main className="grid min-h-screen place-items-center bg-canvas p-4 sm:p-6">
  <section className="w-full max-w-auth rounded-lg border border-border bg-surface p-6 shadow-modal sm:p-8">
    {/* Form content */}
  </section>
</main>
```

### Chat Conversation Row

```tsx
<a
  className="flex h-9 min-w-0 items-center gap-2 truncate rounded-r-md border-l-2 border-transparent px-2 text-muted hover:bg-primary-soft aria-[current=page]:border-primary aria-[current=page]:bg-primary-soft aria-[current=page]:font-semibold aria-[current=page]:text-blue-900"
  href="/chat"
  aria-current="page"
>
  <span className="truncate">Rate limiting for API clients</span>
</a>
```

### Code Block

```tsx
<pre className="overflow-x-auto rounded-md bg-slate-950 p-4 font-mono text-code text-slate-100">
  <code>const delay = retryAfter ?? 2 ** attempt + jitter();</code>
</pre>
```

## Responsive Sidebar

Use a persistent sidebar at `md` and above. Below `md` (768px), keep the sidebar out of the normal layout and expose it with a menu button that opens the Radix Dialog drawer.

```tsx
<aside className="hidden w-sidebar shrink-0 border-r border-border bg-surface p-3 md:flex">
  {/* Desktop history */}
</aside>

<button className="md:hidden" type="button">
  Open conversation history
</button>
```

The drawer must use `@radix-ui/react-dialog` so focus trapping, Escape handling, focus restoration, and modal semantics are handled correctly.

## Global Behavior Already Provided

`index.css` already provides:

- Border-box sizing.
- Canvas background and base body typography.
- A visible blue `:focus-visible` ring.
- Consistent inherited fonts for native form controls.
- Disabled control cursor and opacity.
- Reduced-motion support.

Do not duplicate these rules in components.
