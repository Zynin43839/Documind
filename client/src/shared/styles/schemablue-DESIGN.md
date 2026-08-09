# SchemaBlue Design System

## Overview

SchemaBlue is a diagrammatic, relational design system purpose-built for database design and schema visualization tools. Its pale blue background provides a calm canvas for complex entity-relationship diagrams, while the blue-purple-green palette distinguishes tables, relationships, and data types. The system balances visual clarity with technical density, ensuring that intricate schema structures remain comprehensible. Material-influenced shadows create a layered interface where diagram elements float naturally above the workspace.

---

## Colors

- **Primary** (#3B82F6): Blue -- tables, primary keys, main actions
- **Secondary** (#8B5CF6): Purple -- foreign keys, relationships
- **Tertiary** (#10B981): Green -- indexes, successful validations
- **Background** (#F0F4FF): Canvas background (pale blue)
- **Surface** (#FFFFFF): Table cards, panels, modals
- **Success** (#10B981): Valid schema, successful migration
- **Warning** (#F59E0B): Missing indexes, nullable warnings
- **Error** (#EF4444): Constraint violations, broken refs
- **Info** (#3B82F6): Schema tips, documentation links

## Typography

- **Headline Font**: Roboto Mono
- **Body Font**: Roboto
- **Mono Font**: Roboto Mono

- **Display**: Roboto Mono 30px bold, 40px line height
- **Headline**: Roboto Mono 24px bold, 32px line height
- **Subhead**: Roboto Mono 18px semibold, 26px line height
- **Body Large**: Roboto 16px regular, 26px line height
- **Body**: Roboto 14px regular, 22px line height
- **Body Small**: Roboto 13px regular, 20px line height
- **Caption**: Roboto 12px medium, 18px line height
- **Overline**: Roboto Mono 11px medium, 16px line height
- **Code**: Roboto Mono 13px regular, 20px line height

---

## Spacing

- **Base unit:** 4px
- **Scale:** 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 / 96
- **Component padding:** 8px (compact) | 12px (default) | 16px (relaxed)
- **Section spacing:** 32px between panels, 16px between related groups
- **Diagram canvas:** 24px minimum margin around diagram bounds, 16px grid snapping

## Border Radius

- **None** (0px): Relationship lines, full-width bars
- **Small** (4px): Column type badges, status indicators
- **Medium** (8px): Table cards, inputs, buttons
- **Large** (12px): Modals, property panels
- **XL** (16px): Floating toolbars, canvas controls
- **Full** (9999px): Cardinality markers, avatar circles

## Elevation

Material-inspired layered shadows for diagrammatic depth.
- **Subtle**: 1px offset, 3px blur, #1E293B at 6%; 1px offset, 2px blur, #1E293B at 4%. Resting table cards.
- **Medium**: 4px offset, 6px blur, #1E293B at 7%; 2px offset, 4px blur, #1E293B at 5%. Hover, toolbars.
- **Large**: 10px offset, 20px blur, #1E293B at 10%; 4px offset, 8px blur, #1E293B at 6%. Dragged tables, modals.
- **Overlay**: 20px offset, 40px blur, #1E293B at 15%. Full-screen overlays.

## Components

### Buttons
- **Primary**: #3B82F6 fill, #FFFFFF text, no border, #2563EB fill.
- **Secondary**: #FFFFFF fill, #3B82F6 text, 1px #3B82F6 border, #EFF6FF fill.
- **Ghost**: transparent fill, #475569 text, no border, #E8EEFF fill.
- **Destructive**: #EF4444 fill, #FFFFFF text, no border, #DC2626 fill.
- **Sizes**: Small (30px height, 12px pad) | Medium (38px, 16px) | Large (46px, 20px)
- **Disabled**: 45% opacity, disabled cursor, no hover state changes

### Cards
** Background #FFFFFF, border 1px #DBEAFE, radius 8px, padding 16px, shadow Subtle **default, ** Background #FFFFFF, no border, radius 8px, padding 16px, shadow Medium **elevated.
- Table entity cards use a colored header bar (4px top border matching table color) and list columns below

### Inputs
- **Default**: #93C5FD border, #FFFFFF fill, no shadow.
- **Hover**: #60A5FA border, #FFFFFF fill, no shadow.
- **Focus**: #3B82F6 border, #FFFFFF fill, 3px ring #3B82F6 at 15% shadow.
- **Error**: #EF4444 border, #FEF2F2 fill, 3px ring #EF4444 at 10% shadow.
- **Disabled**: #DBEAFE border, #F0F4FF fill, no shadow.
** 13px, weight 500, color Text Primary, 4px below label **label, ** 12px, color Text Secondary; error helper uses Error color **helper text.

### Chips
** Background #EFF6FF, text #3B82F6, radius Full, padding 4px 12px, toggleable **filter chip, ** Semantic background at 10% opacity, semantic text, radius Full, padding 4px 12px **status chip, VARCHAR=blue, INT=purple, BOOL=green, FK=purple with link icon data type chips.

### Lists
36px, padding 8px 12px row height, 1px #DBEAFE between rows divider, background #DBEAFE, left border 2px #3B82F6 active/selected. Hover: background #EFF6FF.
- Column lists show name, type badge, constraints (PK/FK/NOT NULL) in a row layout

### Checkboxes
16px square, radius 4px. Unchecked: border 2px #93C5FD, background transparent. Checked: background #3B82F6, white checkmark icon. Focus: ring 3px ring #3B82F6 at 20%. Disabled: 40% opacity.

### Radio Buttons
16px circle. border 2px #93C5FD, background transparent unselected. Selected: border 2px #3B82F6, inner dot 8px #3B82F6. Focus: ring 3px ring #3B82F6 at 20%. Disabled: 40% opacity.

### Tooltips
#1E293B, text: #FFFFFF, radius 8px, padding 6px 12px fill. 12px Roboto regular. 6px, matching background arrow, 260px max width, 300ms show, 100ms hide delay.
---

## Do's and Don'ts

1. **Do** use relationship lines with clear cardinality markers (1:1, 1:N, M:N) on the canvas.
2. **Do** color-code data types consistently throughout tables and property panels.
3. **Don't** overcrowd the canvas -- use auto-layout to space tables at minimum 24px apart.
4. **Do** show primary keys with a key icon and foreign keys with a link icon for instant recognition.
5. **Don't** use more than 3 colors for relationship lines; keep the diagram palette restrained.
6. **Do** provide zoom controls and a minimap for navigating complex schemas.
7. **Don't** hide constraint information inside tooltips alone -- display it directly in the table card.
8. **Do** snap table positions to the 16px grid for clean diagram alignment.
9. **Don't** use decorative gradients or patterns on the canvas background -- keep it clean and flat.
10. **Do** validate schema changes in real time and surface errors with inline semantic indicators.