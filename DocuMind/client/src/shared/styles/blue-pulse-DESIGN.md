# Blue Pulse

## Overview
A minimal, real-time design system built for rapid information consumption and public conversation. Blue Pulse blends the classic bird-era blue with the modern monochromatic X era — creating a hybrid aesthetic that is fast, text-forward, and timeline-driven. The design prioritizes scan speed and microcontent, with a sparse interface that lets short-form text and media speak for itself.

## Colors
- **Primary** (#1DA1F2): Follow buttons, links, active indicators, notification badges — Twitter Blue
- **Primary Hover** (#1A91DA): Hover state for blue interactive elements
- **Secondary** (#0F1419): X-era dark brand, header text, bold accents — Ink Black
- **Neutral** (#536471): Secondary text, metadata, icons, muted actions — Gray 500
- **Background** (#FFFFFF): Light mode primary background
- **Surface** (#F7F9F9): Sidebar fill, "What's happening" panel, hover state backgrounds
- **Text Primary** (#0F1419): Post text, display names, headlines — Near Black
- **Text Secondary** (#536471): Handles (@username), timestamps, metadata
- **Border** (#EFF3F4): Timeline dividers, card outlines, section separators — Gray 100
- **Success** (#00BA7C): Verified badges, successful post, protected account indicator
- **Warning** (#FFD400): Community notes indicator, caution labels — Gold
- **Error** (#F4212E): Unfollow, delete, report, content warnings — Action Red

## Typography
- **Display Font**: Inter — loaded from Google Fonts
- **Body Font**: Inter — loaded from Google Fonts
- **Code Font**: JetBrains Mono — loaded from Google Fonts

Inter is used throughout, providing the neutral, high-performance typographic base needed for a text-heavy, real-time interface. Display names use weight 700 for instant recognition in timeline scanning. Post body text uses weight 400 at 15px — the precise size that balances density with readability for short-form content. Handles and metadata use weight 400 at smaller sizes in muted gray. The type system is intentionally constrained — almost everything lives between 13px and 15px to maintain timeline rhythm.

- **Display**: Inter 32px/40px, weight 800, tracking -0.02em
- **Page Title**: Inter 20px/24px, weight 800, tracking -0.01em
- **Section Title**: Inter 20px/24px, weight 700
- **Post Body**: Inter 15px/20px, weight 400
- **Display Name**: Inter 15px/20px, weight 700
- **Handle**: Inter 15px/20px, weight 400
- **Body Small**: Inter 13px/16px, weight 400
- **Label**: Inter 13px/16px, weight 700
- **Metadata**: Inter 13px/16px, weight 400
- **Tab**: Inter 15px/20px, weight 500 (inactive), weight 700 (active)
- **Code**: JetBrains Mono 14px/20px, weight 400

## Elevation
Shadows are used sparingly — the interface is predominantly flat with borders defining structure. Level 0: flat, no shadow — timeline posts, profile sections. Level 1: 0 0 15px rgba(101,119,134,0.2) — for popup menus, compose modal edges. Level 2: 0 0 25px rgba(101,119,134,0.25), 0 1px 4px rgba(101,119,134,0.15) — for compose modal, media viewer overlay. Hover states use #F7F9F9 background fill rather than shadows. The compose modal uses a full-screen dimmed backdrop (rgba(0,0,0,0.4)) with Level 2 shadow on the centered panel.

## Components
- **Buttons**: Follow uses #0F1419 fill (dark), white text, 36px height, 16px horizontal padding, 9999px border-radius, Inter 15px weight 700. Following state: transparent, 1px #CFD9DE border, #0F1419 text, hover turns red (#F4212E border, "Unfollow" text). Post/Tweet button: #1DA1F2 fill, white text, 36px height, 9999px radius, Inter 15px weight 700. Disabled at 50% opacity. Outlined: 1px #CFD9DE border, #0F1419 text.
- **Cards**: Bordered containers with 1px #EFF3F4 border, 16px border-radius, 16px internal padding. Used for "What's happening," "Who to follow," and trending topics in the sidebar. No shadow. Background #FFFFFF (or #F7F9F9 for sidebar panels). Post cards are not visually "cards" — they are borderless rows separated by 1px #EFF3F4 bottom borders.
- **Inputs**: Post compose: Borderless textarea, auto-expanding, Inter 20px weight 400, placeholder "What is happening?!" in #536471. Bottom toolbar with icon buttons (image, GIF, poll, emoji, schedule) in #1DA1F2. Character counter as circular progress ring. Search input: 44px height, #EFF3F4 background, 9999px border-radius, 20px horizontal padding, Inter 15px. Focused: 1px #1DA1F2 border, white background, blue search icon.
- **Chips**: Not prominent — categories use tab navigation instead. When used: pill-shaped (9999px radius), #EFF3F4 background, #0F1419 text, Inter 14px weight 400, 4px/12px padding. Topic tags use #EFF3F4 background, Inter 13px weight 700.
- **Lists**: Timeline is a vertical list of post items. Each post: avatar (40px circle) left, content right. Display name (bold) + handle (gray) + dot + timestamp on first line. Post body below. Embedded media (images 16px radius, video 16px radius, link cards 16px radius with 1px #EFF3F4 border). Action bar below: reply (gray), repost (green #00BA7C when active), like (pink #F91880 when active, heart animation), share. Hover on post shows #F7F9F9 background.
- **Checkboxes**: 20px circular (not square). Unchecked: 2px #536471 border. Checked: #1DA1F2 fill with white checkmark. Radio buttons for polls: same circular style. Used in settings and list management.
- **Tooltips**: #0F1419 background (dark), white text, 4px border-radius, 4px/8px padding, Inter 13px weight 400. Minimal delay (200ms). Used for icon button labels.
- **Navigation**: Left sidebar with icon + label navigation items. Active item: #0F1419 bold text, weight 700. Hover: #EFF3F4 pill background (9999px radius) around icon + label. Logo at top. Post button at bottom (full-width, #1DA1F2, 52px height, 9999px radius). On mobile: bottom tab bar 53px with 5 icon tabs, active uses filled icon variant. Right sidebar: search, trends, who to follow.
- **Search**: Prominent in right sidebar. 44px height, #EFF3F4 background, 9999px border-radius, magnifying glass icon left, Inter 15px placeholder "Search". Focused: white background, 1px #1DA1F2 border. Results dropdown: white background, Level 1 shadow, recent searches and trending suggestions. Explore page uses large search bar as primary element.

## Spacing
- Base unit: 4px
- Scale: 4px, 8px, 12px, 16px, 20px, 24px, 32px, 48px
- Component padding: 12px horizontal for posts, 16px for sidebar items
- Section spacing: 12px between posts (just the border), 16px between sidebar sections
- Container max width: 600px for main timeline column, 350px for right sidebar, 275px for left nav. Total layout max ~1265px centered.
- Card grid gap: 12px between sidebar cards

## Border Radius
- 4px: Tooltips, small menus, badges
- 8px: Dropdown menus, option panels
- 12px: Image previews, quote posts
- 16px: Cards, link previews, media containers, modals
- 9999px: Buttons, chips, search bar, avatars, navigation hover pills, compose button

## Do's and Don'ts
- Do keep the timeline sacred — posts are separated by borders only, never wrapped in visual cards
- Do use circular avatars everywhere — squares are never used for profile images
- Don't use the blue for large surfaces — reserve it for interactive elements (follow, links, compose)
- Do show engagement counts compactly next to action icons (reply, repost, like, views)
- Don't use heavy typography — the heaviest weight (800) is reserved for page titles only
- Do implement hover states with background color fill (#F7F9F9), not shadows or borders
- Don't break the 600px main column width — this constraint is what keeps posts scannable
- Do use the dark fill (#0F1419) for the primary Follow button to make it the highest contrast element
- Don't animate excessively — the only signature animation is the heart burst on Like
- Do truncate long display names and show full text on hover for timeline scan speed