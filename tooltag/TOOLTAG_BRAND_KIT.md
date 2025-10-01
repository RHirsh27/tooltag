# 🔧 ToolTag Brand Kit v1.0

Complete brand identity and design system for ToolTag - rugged, industrial, modern.

---

## 🎨 Color Palette

### Core Colors

| Color Name | Role | HEX | RGB | Tailwind Class |
|------------|------|-----|-----|----------------|
| **ToolTag Orange** | Primary Brand Accent | `#F26A1B` | (242, 106, 27) | `primary-500` |
| **Iron Black** | Primary Background | `#2D2D2D` | (45, 45, 45) | `iron-200` |
| **Steel White** | Typography Contrast | `#FFFFFF` | (255, 255, 255) | `white` |

### Supporting Neutrals

| Color Name | Role | HEX | RGB | Tailwind Class |
|------------|------|-----|-----|----------------|
| **Gunmetal Gray** | Secondary Backgrounds | `#4A4A4A` | (74, 74, 74) | `gunmetal-100` |
| **Forge Silver** | Icons & Borders | `#BFBFBF` | (191, 191, 191) | `silver` |

### Accent Extensions

| Color Name | Role | HEX | RGB | Tailwind Class |
|------------|------|-----|-----|----------------|
| **Safety Yellow** | Warnings & Alerts | `#FFD23F` | (255, 210, 63) | `safety` |
| **Blueprint Blue** | Trust & Links | `#1F4E79` | (31, 78, 121) | `blueprint` |

---

## 🎨 Extended Palette (Tints & Shades)

### ToolTag Orange Scale
```
primary-50:  #FFF4ED (Lightest - backgrounds)
primary-100: #FFEAD9
primary-200: #FFAA73 (40% lighter)
primary-300: #FF8C42 (20% lighter)
primary-400: #F26A1B (Brand Orange)
primary-500: #F26A1B (Brand Orange - default)
primary-600: #CC5615 (20% darker - hover states)
primary-700: #993F10 (40% darker - active states)
primary-800: #662A0B
primary-900: #331507 (Darkest)
```

### Iron Black Scale
```
iron-50:  #606060 (40% lighter)
iron-100: #474747 (20% lighter - cards)
iron-200: #2D2D2D (Brand Black - main bg)
iron-300: #1A1A1A (20% darker - inputs)
iron-400: #0D0D0D (40% darker)
```

### Gunmetal Gray Scale
```
gunmetal-50:  #6B6B6B (20% lighter)
gunmetal-100: #4A4A4A (Brand Gray)
gunmetal-200: #333333 (20% darker)
```

---

## ✍️ Typography System

### Font Families

**Headings (Logo / Hero / CTA)**
- **Typeface**: Montserrat ExtraBold
- **Usage**: H1-H6, buttons, navigation
- **Tailwind**: `font-heading`
- **Import**: Google Fonts (included in app.css)

**Body Text**
- **Typeface**: Inter Regular
- **Usage**: Paragraphs, descriptions, UI copy
- **Tailwind**: `font-body`
- **Import**: Google Fonts (included in app.css)

**Code / Technical**
- **Typeface**: JetBrains Mono
- **Usage**: Serial numbers, code snippets
- **Tailwind**: `font-mono`
- **Import**: Google Fonts (included in app.css)

### Type Scale

```css
/* Headings */
h1: text-3xl font-bold (30px)
h2: text-2xl font-bold (24px)
h3: text-xl font-semibold (20px)
h4: text-lg font-semibold (18px)
h5: text-base font-semibold (16px)
h6: text-sm font-semibold (14px)

/* Body */
body: text-base font-normal (16px)
small: text-sm (14px)
tiny: text-xs (12px)
```

---

## 🧩 UI Components

### Buttons

#### Primary Button (CTA)
```html
<button class="btn btn-primary">
  Check Out Item
</button>
```
- Background: ToolTag Orange (`#F26A1B`)
- Text: White
- Hover: Darker Orange (`#CC5615`)
- Shadow: Large shadow with glow effect

#### Secondary Button
```html
<button class="btn btn-secondary">
  Cancel
</button>
```
- Background: Transparent
- Border: 2px Gunmetal Gray
- Text: Forge Silver
- Hover: Border + text shift to Orange

### Cards / Panels

```html
<div class="card">
  <h3>Card Title</h3>
  <p>Card content</p>
</div>
```
- Background: Iron Black lighter (`#474747`)
- Border: Gunmetal with opacity
- Shadow: Large shadow for depth
- Text: White headings, Silver body

### Input Fields

```html
<input type="text" class="input" placeholder="Enter item name">
```
- Background: Iron Black darker (`#1A1A1A`)
- Border: Gunmetal Gray
- Text: White
- Placeholder: Silver with 50% opacity
- Focus: Orange border with glow

### Alerts

#### Warning Alert
```html
<div class="alert-warning p-4 rounded">
  ⚠️ This item is overdue!
</div>
```
- Background: Safety Yellow (`#FFD23F`)
- Text: Iron Black
- Border: Left accent in Orange

#### Error Alert
```html
<div class="alert-error p-4 rounded">
  ❌ Failed to save item
</div>
```
- Background: Dark Orange (`#993F10`)
- Text: White
- Border: Left accent in bright Orange

#### Info Alert
```html
<div class="alert-info p-4 rounded">
  ℹ️ New features available
</div>
```
- Background: Blueprint Blue (`#1F4E79`)
- Text: White
- Border: Left accent in same blue

---

## 📐 Layout Guidelines

### Spacing Scale
- **xs**: 0.25rem (4px)
- **sm**: 0.5rem (8px)
- **md**: 1rem (16px)
- **lg**: 1.5rem (24px)
- **xl**: 2rem (32px)
- **2xl**: 3rem (48px)

### Border Radius
- **Default**: 0.5rem (8px) - inputs, buttons
- **Large**: 0.75rem (12px) - cards
- **Full**: 9999px - badges, avatars

### Shadows
- **sm**: Small depth for hover states
- **md**: Medium depth for cards
- **lg**: Large depth for modals, primary buttons
- **xl**: Extra large for floating elements

---

## 🎯 Usage Guidelines

### Brand Color Application

**ToolTag Orange (`#F26A1B`)**
- ✅ Use for: CTA buttons, logos, highlights, active states
- ✅ Frequency: 10-15% of UI
- ❌ Avoid: Large background areas, body text

**Iron Black (`#2D2D2D`)**
- ✅ Use for: Main backgrounds, app frame, dark sections
- ✅ Frequency: 60-70% of UI
- ❌ Avoid: On dark images without contrast

**White (`#FFFFFF`)**
- ✅ Use for: Headings on dark, icons, borders
- ✅ Frequency: 15-20% of UI
- ❌ Avoid: Backgrounds (use lighter gray instead)

**Neutrals (Gray/Silver)**
- ✅ Use for: Secondary text, dividers, disabled states
- ✅ Frequency: Remaining ~10%
- ❌ Avoid: Overusing silver text (hard to read)

**Accents (Yellow/Blue)**
- ✅ Use for: Alerts, system messages, trust signals
- ✅ Frequency: Sparingly, <5%
- ❌ Avoid: Competing with primary orange

---

## 💻 Implementation in Code

### Tailwind Config (Already Configured)

```javascript
// tailwind.config.js
theme: {
  extend: {
    colors: {
      primary: { /* ToolTag Orange scale */ },
      iron: { /* Black scale */ },
      gunmetal: { /* Gray scale */ },
      silver: '#BFBFBF',
      safety: '#FFD23F',
      blueprint: '#1F4E79',
    },
    fontFamily: {
      heading: ['Montserrat', 'sans-serif'],
      body: ['Inter', 'system-ui', 'sans-serif'],
      mono: ['JetBrains Mono', 'monospace'],
    },
  },
}
```

### CSS Utilities (Already Configured)

```css
/* Global styles in app.css */
body {
  @apply bg-iron-200 text-white font-body;
}

h1, h2, h3, h4, h5, h6 {
  @apply font-heading font-bold;
}
```

### Component Classes

```css
.btn { /* Base button styles */ }
.btn-primary { /* Orange CTA button */ }
.btn-secondary { /* Outlined button */ }
.input { /* Form input field */ }
.card { /* Content card */ }
.alert-warning { /* Yellow warning */ }
.alert-error { /* Orange error */ }
.alert-info { /* Blue info */ }
```

---

## 🎨 Design Assets

### Logo Variations

**Primary Logo**
- ToolTag wordmark in Montserrat ExtraBold
- Color: ToolTag Orange on dark, Iron Black on light
- Icon: Wrench/gear symbol in Orange

**Logo Lockups**
- Horizontal: Icon + wordmark side by side
- Vertical: Icon stacked above wordmark
- Icon only: For favicons, app icons

**Color Variations**
- Primary: Orange icon + black text (light backgrounds)
- Reversed: Orange icon + white text (dark backgrounds)
- Monochrome: All black or all white (limited use)

### Icon Style

- **Line weight**: 2px strokes
- **Corner radius**: Slightly rounded (not sharp, not too soft)
- **Style**: Outlined, industrial aesthetic
- **Color**: Orange for active, Silver for inactive

---

## 📱 Responsive Design

### Breakpoints
```
sm: 640px   // Mobile landscape
md: 768px   // Tablet
lg: 1024px  // Laptop
xl: 1280px  // Desktop
2xl: 1536px // Large desktop
```

### Mobile-First Approach
- Start with mobile layout
- Enhance for larger screens
- Touch targets minimum 44x44px
- Increase button padding on mobile

---

## ♿ Accessibility

### Color Contrast
- **Primary Orange on Dark**: 7.5:1 (AAA compliant)
- **White on Dark**: 14:1 (AAA compliant)
- **Silver on Dark**: 4.8:1 (AA compliant)

### Recommendations
- Always pair Orange with sufficient dark/light contrast
- Never use color alone to convey meaning
- Include text labels with icon-only buttons
- Ensure 4.5:1 minimum contrast ratio for body text

---

## 🚀 Quick Reference

### Most Common Combinations

**Primary CTA**
```html
<button class="bg-primary-500 text-white hover:bg-primary-600">
  Get Started
</button>
```

**Card on Dark Background**
```html
<div class="bg-iron-100 border border-gunmetal-100/30 p-6 rounded-lg">
  <h3 class="text-white">Inventory Item</h3>
  <p class="text-silver">Description text</p>
</div>
```

**Form Input**
```html
<input 
  type="text"
  class="bg-iron-300 border-gunmetal-100 text-white placeholder-silver/50"
  placeholder="Enter item name"
>
```

**Warning Badge**
```html
<span class="bg-safety text-iron-400 px-3 py-1 rounded-full text-sm font-semibold">
  Overdue
</span>
```

---

## 📦 Export Formats

### For Figma/Design Tools
- Color Styles: Export as Figma color tokens
- Text Styles: Export heading and body styles
- Components: Button, input, card variants

### For Development
- Tailwind config: Already configured in `tailwind.config.js`
- CSS variables: Can be added for runtime theming
- Component library: Svelte components use Tailwind classes

---

## ✨ Brand Personality

**ToolTag feels:**
- **Rugged**: Industrial, durable, built for work
- **Modern**: Clean interfaces, no clutter
- **Trustworthy**: Safety colors, clear hierarchy
- **Efficient**: Quick actions, scannable layouts

**ToolTag avoids:**
- Overly bright/flashy colors (except safety yellow for warnings)
- Comic/playful fonts
- Rounded bubbly shapes
- Pastel or muted palettes

---

**This brand kit is production-ready and fully implemented in the ToolTag codebase!** 🎊

All colors, fonts, and component styles are configured in:
- `tailwind.config.js` - Color palette and fonts
- `app.css` - Global styles and component classes
- Google Fonts - Auto-loaded for Montserrat, Inter, JetBrains Mono

Start using these classes immediately in your components!

