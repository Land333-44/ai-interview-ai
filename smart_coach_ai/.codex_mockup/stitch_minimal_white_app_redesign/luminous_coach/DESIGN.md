---
name: Luminous Coach
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f4'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#484555'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f0f1f1'
  outline: '#797587'
  outline-variant: '#c9c4d8'
  surface-tint: '#5d3fe0'
  primary: '#5b3cdd'
  on-primary: '#ffffff'
  primary-container: '#7459f7'
  on-primary-container: '#fffbff'
  inverse-primary: '#c9bfff'
  secondary: '#5f5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e2dfde'
  on-secondary-container: '#636262'
  tertiary: '#5b5b66'
  on-tertiary: '#ffffff'
  tertiary-container: '#74737f'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5deff'
  primary-fixed-dim: '#c9bfff'
  on-primary-fixed: '#1a0063'
  on-primary-fixed-variant: '#441cc8'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#e3e1ee'
  tertiary-fixed-dim: '#c6c5d2'
  on-tertiary-fixed: '#1a1b24'
  on-tertiary-fixed-variant: '#464650'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  h1:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.02em
  h2:
    fontFamily: Manrope
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  h3:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: 0em
  body-lg:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  label-sm:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-padding: 20px
  gutter: 12px
---

## Brand & Style

The design system is a "Modern Corporate" evolution of the original dark-themed application. It prioritizes clarity, focus, and a sense of calm reliability. By transitioning to a high-contrast light theme, the interface moves from a "tech-first" aesthetic to a "user-centric" coaching environment that feels professional and accessible.

The personality is encouraging yet precise. It utilizes a refined minimalist approach, using generous white space to reduce cognitive load during the coaching process. The core aesthetic relies on depth through soft shadows and subtle layering rather than heavy borders, creating a sophisticated mobile experience that feels integrated with modern OS standards.

## Colors

This design system utilizes a "High-Contrast Light" palette. The foundation is a pure white (#FFFFFF) for the main canvas, ensuring maximum brightness and cleanliness. To maintain brand continuity, the vibrant primary purple (#7B61FF) is reserved for high-impact interactive elements and primary actions.

Typography and iconography use a deep charcoal (#1A1A1A) to ensure WCAG AAA compliance and sharp legibility. A secondary "Surface" tint (#F8F9FA) and a tertiary "Brand Wash" (#F4F2FF) are used for background elements and subtle card differentiation. Functional colors for success and error states are saturated to stand out against the white background while maintaining professional tones.

## Typography

The design system employs **Manrope** for all text elements. This geometric sans-serif offers a balance between modern tech and approachable humanism. 

Headlines use a bold weight with tighter letter spacing to create a strong visual anchor. Body text is set with generous line heights to ensure readability during long feedback sessions. Labels utilize a semi-bold weight and slight tracking to distinguish them from standard body copy. All text elements must maintain a high contrast ratio against the #FFFFFF background, primarily using #1A1A1A for primary text and a 60% opacity for secondary information.

## Layout & Spacing

The layout follows a fluid 4-column mobile grid system. A base unit of 4px governs all dimensions to ensure mathematical harmony. 

Vertical rhythm is established using the `lg` (24px) unit for section spacing and the `md` (16px) unit for internal card padding. Content is contained within a 20px horizontal margin to provide breathing room on mobile displays. This design system favors "optical grouping," where related elements are closer together (8px) and distinct sections are clearly separated (32px).

## Elevation & Depth

To replace the deep gradients of the original design, this system uses **Ambient Shadows** and **Tonal Layers**. 

Hierarchy is conveyed through three distinct levels:
1.  **Level 0 (Base):** Pure White (#FFFFFF) background.
2.  **Level 1 (Cards):** Soft White surfaces with a subtle shadow (Blur: 15px, Y: 4, Opacity: 6% Black). This is used for primary content containers.
3.  **Level 2 (Interactive/Floating):** Higher elevation shadows (Blur: 25px, Y: 8, Opacity: 10% Black) used for floating action buttons or active state cards.

Subtle 1px borders in a very light gray (#E9ECEF) may be used on Level 1 elements to define boundaries without adding visual weight.

## Shapes

The shape language is "Rounded," echoing the friendly nature of an AI coach. Standard components (Inputs, Small Cards) use a 0.5rem (8px) radius. Larger layout containers and primary buttons use 1rem (16px) to appear softer and more inviting. 

Icons should be contained within circular or highly rounded enclosures (min 12px radius) to maintain a consistent visual metaphors of "bubbles" and "containers" seen in the original feedback components.

## Components

-   **Buttons:** Primary buttons are solid Purple (#7B61FF) with white text. Secondary buttons use a light purple tint (#F4F2FF) with purple text. All buttons have a height of 56px for touch accessibility.
-   **Cards:** Use a white background with the Level 1 shadow. Headers within cards should be distinct, often accompanied by a small icon in a tinted circular background.
-   **Input Fields:** Ghost-style inputs with a light gray border (#E9ECEF) that transitions to Purple (#7B61FF) on focus. Labels sit above the field in `label-sm` style.
-   **Progress Bars:** Backgrounds are a light neutral (#F1F3F5) with the fill in Primary Purple or functional status colors (Green/Yellow/Red).
-   **Status Bar & Icons:** Updated to dark icons (#1A1A1A). Icons use a 2px stroke weight to ensure they feel substantial against the white background.
-   **AI Feedback Chips:** Use the `tertiary_color` background to highlight AI-generated suggestions, creating a distinct "advice" zone that feels different from user input.