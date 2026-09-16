---
name: Academic Precision
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#464555'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#777587'
  outline-variant: '#c7c4d8'
  surface-tint: '#4d44e3'
  primary: '#3525cd'
  on-primary: '#ffffff'
  primary-container: '#4f46e5'
  on-primary-container: '#dad7ff'
  inverse-primary: '#c3c0ff'
  secondary: '#006c4a'
  on-secondary: '#ffffff'
  secondary-container: '#82f5c1'
  on-secondary-container: '#00714e'
  tertiary: '#703a00'
  on-tertiary: '#ffffff'
  tertiary-container: '#934e00'
  on-tertiary-container: '#ffd2b1'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2dfff'
  primary-fixed-dim: '#c3c0ff'
  on-primary-fixed: '#0f0069'
  on-primary-fixed-variant: '#3323cc'
  secondary-fixed: '#85f8c4'
  secondary-fixed-dim: '#68dba9'
  on-secondary-fixed: '#002114'
  on-secondary-fixed-variant: '#005137'
  tertiary-fixed: '#ffdcc3'
  tertiary-fixed-dim: '#ffb77d'
  on-tertiary-fixed: '#2f1500'
  on-tertiary-fixed-variant: '#6e3900'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: 0em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 15px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.04em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system delivers a high-density, structured, and modern academic portal compliant with Material Design 3 guidelines. Designed for students, parents, and educators navigating data-intensive gradebooks, schedule changes, and attendance records on mobile devices, the interface balances strict institutional clarity with contemporary tactile refinement.

The aesthetic philosophy centers on **Precision Modernism**:
- **Clarity over ornament:** Information hierarchy is paramount. Heavy decorative flourishes are stripped away in favor of crisp typography, consistent color semantics, and defined spatial grids.
- **Scannable density:** Compact layouts optimize vertical mobile real estate, allowing students to absorb daily schedules, grading updates, and pending assignments without excessive scrolling.
- **Purposeful chromatic signals:** Colors act as functional wayfinding tools rather than mere aesthetic choices, immediate visual anchors categorize evaluations, attendance statuses, and schedule alterations.

## Colors

The palette establishes an authoritative, reliable base grounded by an indigo primary tone, supported by functional categorical color codes tailored for rapid status digestion.

### Core Canvas & Neutrals
- **Canvas Base:** `#F8FAFC` (Slate 50) serves as the subdued, low-strain backdrop for all primary views.
- **Surface Elevation:** `#FFFFFF` (Pure White) creates crisp foreground isolation for interactive cards, sheets, and dialogs.
- **Structural Lines:** `#E2E8F0` (Slate 200) demarcates boundaries, list partitions, and container strokes without visual noise.
- **Typography Primary:** `#0F172A` (Slate 900) ensures maximum contrast for primary labels, grades, and titles.
- **Typography Secondary:** `#64748B` (Slate 500) provides balanced hierarchy for metadata, timestamps, and captions.

### Category & Semantic Indicators
- **Homework & Daily Activities:** `#4F46E5` (Indigo 600) — Primary UI interactions, assignments, general tasks.
- **Exams & Summative Assessments:** `#059669` (Deep Emerald 600) / `#BE123C` (Crimson 700) for major test milestones.
- **Quizzes & Short Checks:** `#D97706` (Amber 600) — Formative evaluations and pending submissions.
- **Positive Status / On-Schedule / Present:** `#10B981` (Emerald 500) — Timely arrival, completed benchmarks, standard operations.
- **Substitutions & Room Changes:** `#EA580C` (Orange 600) — Modified scheduling or faculty replacements.
- **Cancellations & Severe Alerts:** `#DC2626` (Rose/Red 600) — Class cancellations, unexcused absences, critical academic warnings.

## Typography

The type scale relies entirely on **Plus Jakarta Sans**, chosen for its crisp geometry, open counters, and high legibility at micro scales. It allows compact tables, status pills, and dense calendar views to maintain effortless readability on smaller handheld displays.

- **Numbers & Metrics:** Quantitative data (e.g., GPAs, percentages, scores) must use tabular numbers (`tnum`) to maintain vertical alignment within dense assessment tables.
- **Micro-Copy:** `label-sm` is reserved for uppercase badges (e.g., `QUIZ`, `EXAM`, `ROOM 402`), set with enhanced letter-spacing (+0.04em) to prevent glyph collisions.
- **Hierarchy Enforcers:** Bold and Semi-Bold weights are favored for course codes and point tallies, keeping them distinct from descriptive text and instructor names.

## Layout & Spacing

This design system utilizes an 8-point base rhythm optimized to a dense 4-point sub-grid for mobile compact environments.

### Mobile Grid Philosophy
- **Screen Canvas:** Mobile displays use a fluid single-column layout bounded by a strict `1rem` (16px) outer margin to maximize usable horizontal width.
- **Vertical Density:** Component gaps rely predominantly on `space-xs` (4px) and `space-sm` (8px) for tightly related metadata (e.g., assignment title to due date), and `space-md` (12px) between modular card units.
- **Section Breaks:** Major groupings (e.g., "Term 1 Grades" versus "Upcoming Deadlines") are separated by `space-xl` (24px).
- **Responsive Handling:** When expanding to tablet or split-screen views (>= 600px), margins scale to `1.5rem` (24px), transitioning into a 2-column or 3-column asymmetric layout with a persistent navigation rail.

## Elevation & Depth

In alignment with Material Design 3, elevation is rendered primarily through **tonal differentiation combined with fine 1px containment borders**, minimizing muddy ambient shadow spread in dense interfaces.

- **Level 0 (Flat Canvas):** `#F8FAFC` — Base viewport background.
- **Level 1 (Card & Module Layer):** `#FFFFFF` background with a solid `1px solid #E2E8F0` border. Shadow: `0 1px 2px 0 rgba(15, 23, 42, 0.04)`.
- **Level 2 (Active/Tapped Elements & Floating Pills):** `#FFFFFF` surface with `1px solid #CBD5E1`. Shadow: `0 4px 6px -1px rgba(15, 23, 42, 0.07), 0 2px 4px -2px rgba(15, 23, 42, 0.05)`.
- **Level 3 (Modal Bottom Sheets & Navigation Bars):** `#FFFFFF` surface with an elevated shadow: `0 10px 15px -3px rgba(15, 23, 42, 0.08), 0 4px 6px -4px rgba(15, 23, 42, 0.03)`.

## Shapes

The design system adopts a **Soft (Level 1)** corner philosophy. Subtle curvature ensures the UI feels engineered, structured, and space-efficient without encroaching on edge-to-edge content borders.

- **Cards and Modals:** `0.5rem` (8px, `rounded-lg`) corner radius, preserving clean linear perimeters inside list views.
- **Badges, Tags, and Category Markers:** `0.25rem` (4px, `rounded`) to `0.375rem` (6px) for compact tabular tags.
- **Action Buttons & Inputs:** `0.375rem` (6px) to maintain a cohesive, utilitarian form factor across interactive touchpoints.
- **Full Pills (`rounded-full`):** Reserved solely for quantitative metric counters (e.g., unread alert counts, grade percentage badges).

## Components

### Cards & Assessment Modules
- **Structure:** Crisp `#FFFFFF` surface enclosed by a `1px solid #E2E8F0` stroke. Inner padding is set to a compact `0.75rem` (12px).
- **Category Indicator Stripe:** A 4px vertical color bar on the left edge denoting the category:
  - Deep Emerald (`#059669`): Exams
  - Amber (`#D97706`): Quizzes
  - Indigo (`#4F46E5`): Homework / Projects
  - Rose (`#DC2626`): Canceled / Past Due
  - Orange (`#EA580C`): Substitution / Schedule Change
- **Metrics Positioning:** Quantitative scores (`98/100` or `A+`) align to the right in high-contrast `headline-sm` with `tnum` font features.

### Category Chips & Status Badges
- **Visuals:** Low-opacity tinted backgrounds (10% tint of the parent color) paired with high-contrast, fully opaque text. For example, a Quiz badge uses `bg-[#D97706]/10` with `text-[#D97706]`.
- **Dimensions:** Height fixed to 22px; padding `2px 8px`; typography `label-sm` in all caps.

### Dense Lists & Timetable Rows
- **List Items:** Separated by a hairline border (`1px solid #F1F5F9`). Minimum touch target is 44px, but visual content height is compressed to 36px via negative internal margins for efficient scrolling.
- **Attendance Dots:** 8px circular status indicators (`#10B981` Present, `#DC2626` Absent, `#EA580C` Tardy).

### Buttons & Interactive Controls
- **Primary Button:** Solid Indigo (`#4F46E5`) fill, pure white text, 38px height, medium weight (`label-lg`), 6px border radius.
- **Secondary / Ghost Button:** Transparent background, `1px solid #E2E8F0` border, `#0F172A` text, matching 38px height.
- **Inputs & Filters:** Height standardized to 36px for dense forms. Background `#FFFFFF` with `#E2E8F0` stroke, transitioning to `#4F46E5` on focus with a 1px outline ring.

### Floating Bottom Navigation Bar
- **Form:** Elevated white dock with an upper border (`1px solid #E2E8F0`) and subtle top shadow.
- **Icons & Labels:** 20px vector icons paired with `label-sm` labels directly underneath; active items use `#4F46E5`, inactive items use `#94A3B8`.