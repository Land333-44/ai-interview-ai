---
name: Azure Coaching System
colors:
  surface: '#f9f9ff'
  surface-dim: '#cfdaf1'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee8ff'
  surface-container-highest: '#d8e3fa'
  on-surface: '#111c2c'
  on-surface-variant: '#3f484c'
  inverse-surface: '#263142'
  inverse-on-surface: '#ebf1ff'
  outline: '#6f787d'
  outline-variant: '#bfc8cd'
  surface-tint: '#0c6780'
  primary: '#0c6780'
  on-primary: '#ffffff'
  primary-container: '#87ceeb'
  on-primary-container: '#005870'
  inverse-primary: '#89d0ed'
  secondary: '#506167'
  on-secondary: '#ffffff'
  secondary-container: '#d1e3ea'
  on-secondary-container: '#55656b'
  tertiary: '#5c5f60'
  on-tertiary: '#ffffff'
  tertiary-container: '#c2c5c6'
  on-tertiary-container: '#4e5253'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#baeaff'
  primary-fixed-dim: '#89d0ed'
  on-primary-fixed: '#001f29'
  on-primary-fixed-variant: '#004d62'
  secondary-fixed: '#d4e5ec'
  secondary-fixed-dim: '#b8c9d0'
  on-secondary-fixed: '#0d1e23'
  on-secondary-fixed-variant: '#39494f'
  tertiary-fixed: '#e1e3e4'
  tertiary-fixed-dim: '#c4c7c8'
  on-tertiary-fixed: '#191c1d'
  on-tertiary-fixed-variant: '#444748'
  background: '#f9f9ff'
  on-background: '#111c2c'
  surface-variant: '#d8e3fa'
typography:
  h1:
    fontFamily: Manrope
    fontSize: 40px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  h2:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.3'
    letterSpacing: -0.01em
  h3:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-sm:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.2'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 48px
  xl: 80px
  gutter: 24px
  margin: 32px
---

## Brand & Style

The design system is anchored in a philosophy of "Digital Serenity." It targets professional users seeking personal growth through AI interaction, requiring an environment that feels both intellectually stimulating and emotionally calming. 

The style is a blend of **Modern Corporate** and **Minimalism**, prioritizing expansive whitespace and a "beach" atmosphere to reduce cognitive load. By utilizing translucent layers and soft transitions, the system evokes a sense of clarity and openness, mirroring the expansive nature of a clear sky.

## Colors

The palette is centered on "Sky Blue" (#87CEEB), used strategically for primary actions and brand identifiers. To maintain the spacious, "beach" feel, the background architecture relies heavily on Pure White (#FFFFFF) and Slate-50 for subtle sectioning. 

Text contrast is strictly maintained using Slate-900 for headlines to ensure peak readability against the light blue and gray backgrounds. The "Idea" logo should utilize the `sky-dark` for the node connections and `sky-base` for the lightbulb filament to ensure it feels integrated into the interface.

## Typography

The design system utilizes **Manrope** for its geometric yet approachable character. The hierarchy is designed to be highly legible for long-form coaching transcripts and AI insights. 

Headlines use tighter letter spacing and heavier weights to provide a grounded contrast to the airy layout. Body text is set with generous line heights (1.6) to enhance the feeling of "breathable" content. Labels and small utility text use a semi-bold weight to maintain accessibility despite their smaller scale.

## Layout & Spacing

This design system employs a **Fixed Grid** model for desktop (12-column, 1200px max-width) and a **Fluid Grid** for mobile. The rhythm is based on an 8px square baseline, ensuring all components align to a predictable vertical scale.

Layouts should prioritize large "safe areas" around AI-generated content to prevent visual clutter. Margins are intentionally wide (32px+) to reinforce the minimalist, expansive aesthetic.

## Elevation & Depth

Depth is achieved through **Ambient Shadows** rather than harsh lines. Surfaces use a "stacked" approach:
1.  **Level 0 (Base):** Pure White or Slate-50 background.
2.  **Level 1 (Cards):** White surfaces with a 10% opacity Sky Blue tint in the shadow to create a cohesive atmospheric effect.
3.  **Level 2 (Modals/Popovers):** Deeper blurs with a 15% shadow opacity.

Shadows should feel diffused and soft, with a large blur radius (20px-40px) and a low vertical offset (4px-8px) to mimic natural overhead light on a bright day.

## Shapes

The shape language is defined by **Rounded** geometry. A standard radius of 16px (rounded-lg) is applied to all primary containers, cards, and buttons. This curvature softens the professional tone, making the AI coaching experience feel more empathetic and modern. Progress bars and small tags use fully pill-shaped (rounded-full) containers to contrast against the structural card elements.

## Components

-   **Buttons:** Primary buttons use a solid Sky Blue fill with white text. Secondary buttons use a Sky Blue ghost style (transparent fill, blue border).
-   **Cards:** 16px corner radius, white background, and a soft "Sky-tinted" shadow. No borders; use elevation for separation.
-   **Input Fields:** Subtle Slate-50 fill with a 1px border that turns Sky Blue on focus.
-   **Progress Bars:** Use a dual-tone blue approach. The track is `sky-light` at 30% opacity, and the indicator is a solid `sky-base` gradient to `sky-dark`.
-   **Chips/Tags:** Small, pill-shaped markers with `sky-light` backgrounds and `sky-dark` text for categorization.
-   **AI Chat Bubbles:** User bubbles are Slate-50; AI bubbles are a very pale Sky Blue gradient to distinguish the "intelligence" of the response visually.