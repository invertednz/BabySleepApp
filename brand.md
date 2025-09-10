# BabySteps Brand Guide

## Brand Overview

BabySteps is a comprehensive baby tracking and sleep management application designed to help parents monitor, analyze, and improve their baby's sleep patterns and daily routines. The app provides tools for tracking sleep, feeding, diaper changes, and offers features like sleep sounds, analytics, and scheduling.

## Brand Name

- **Name**: BabySteps
- **Tagline**: "Small steps for better sleep"

## Brand Voice

- **Tone**: Supportive, reassuring, and warm
- **Personality**: Knowledgeable but approachable, like a trusted friend or pediatric nurse
- **Communication Style**: Clear, concise, and empathetic

## Logo & Icon Guidelines

The BabySteps logo should incorporate:
- A simple, recognizable icon that represents sleep and baby care
- The brand name "BabySteps" in a clean, modern font
- Primary brand colors (Soft Pink Gradient)

## Color Palette

### Primary Colors
- **Soft Lavender Gradient**: 
  - Start: #E6D7F2 (Light Lavender)
  - End: #C8A2C8 (Soft Lilac)
  - Used for headers, buttons, and key UI elements
  - CSS: `linear-gradient(135deg, #E6D7F2 0%, #C8A2C8 100%)`
  - Darker accent: #A67EB7

### Secondary Colors
- **Warm Sand**: 
  - Main: #F5F0E6
  - Medium: #E6DBC8
  - Used for secondary actions and highlights
  
- **Sage Green**:
  - Main: #E0E8D9
  - Darker: #C8D8B9
  - Used for success states and positive actions

### Neutral Colors
- **White**: #FFFFFF
  - Used for card backgrounds and text on dark backgrounds
- **Light Gray**: #F8F9FA
  - Used for backgrounds and subtle UI elements
- **Medium Gray**: #E9ECEF
  - Used for borders and dividers
- **Text**: #4A4A4A
  - Primary text color
- **Text Light**: #8A8A8A
  - Secondary text color

### Accent Colors
- **Success**: #A8C8A2 (with light background #EBF5E6)
- **Warning**: #E6C8A2 (with light background #F5F0E6)
- **Alert**: #E6B3B3 (with light background #F5EBEB)
- **Info**: #A2B3C8 (with light background #E6EBF0)

### Color Usage
- Primary actions: Soft Lavender Gradient
- Secondary actions: Warm Sand
- Success states: Sage Green
- Alerts/Warnings: Soft Rose (#D9A6A6)
- Informational: Soft Lavender

## Typography

### Font Family
- **Primary Font**: 'Inter', sans-serif
- **Weights Used**: 300 (Light), 400 (Regular), 500 (Medium), 600 (Semi-bold), 700 (Bold)
- **Source**: Google Fonts (https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap)

### Text Styles
- **Headers**: 
  - H1: 24px (2xl), Bold, #FFFFFF (on gradient background) or #000000
  - H2: 18px (lg), Semi-bold, #000000
- **Body Text**: 
  - Regular: 16px, Regular, #000000
  - Small: 14px (sm), Regular, #718096 (gray-500)
- **Micro Text**: 12px (xs), Medium, #718096 (gray-500)

## UI Components

### Cards
- White background (#FFFFFF)
- Border radius: 16px
- Box shadow: 0 4px 12px rgba(0, 0, 0, 0.05)
- Transition: all 0.3s ease
- Active state: transform scale(0.98)

### Buttons

#### Primary Button
- Background: Soft Pink Gradient
- Text color: White (#FFFFFF)
- Font weight: 600 (Semi-bold)
- Padding: 14px 24px
- Border radius: 12px
- Box shadow: 0 4px 12px rgba(255, 155, 180, 0.3)
- Transition: all 0.3s ease
- Hover: transform translateY(-1px), subtle shadow
- Active state: transform scale(0.98), reduced shadow

#### Secondary Button
- Background: White (#FFFFFF)
- Text color: #4A4A4A
- Border: 1px solid #E9ECEF
- Font weight: 500 (Medium)
- Padding: 14px 24px
- Border radius: 12px
- Transition: all 0.2s ease
- Hover: border-color: #A5D8FF, background: #F8F9FA
- Active state: transform scale(0.98)

#### Text Button
- Background: Transparent
- Text color: #FF6B8B
- Font weight: 500 (Medium)
- Padding: 8px 12px
- Border radius: 8px
- Hover: background: rgba(255, 107, 139, 0.1)
- Active: background: rgba(255, 107, 139, 0.2)

### Icons
- Icon library: Feather Icons
- Default size: 24px x 24px
- Small size: 16px x 16px (h-4 w-4)
- Colors match the context (primary orange, gray for inactive, contextual colors)

### Navigation
- Bottom navigation with 5 items
- Active state: Soft Pink (#FF6B8B) icon and font-medium text
- Inactive state: #8A8A8A icon and regular text
- Icon with label beneath
- Smooth transition effects on press (0.2s ease)
- Background: White with subtle top border (#F0F0F0)

## Design Patterns

### Headers
- Gradient background
- White text
- Padding: 24px (p-6)
- Extra padding on top: 40px (pt-10)
- Title and subtitle structure

### Status Indicators
- Circular colored backgrounds with appropriate icons
- Color coding:
  - Green: Great/Success
  - Yellow: Good
  - Orange: Fair
  - Red: Poor/Alert

### Progress Bars
- Height: 8px
- Background: #E9ECEF
- Filled portion: Soft Pink Gradient
- Rounded corners: 4px
- Shadow: None
- Transition: width 0.3s ease

## Imagery & Iconography

### Icon Usage
- Sleep tracking: Clock icon
- Feeding: Coffee/bottle icon
- Diaper changes: Droplet icon
- Sleep sounds: Music icon
- Schedule: Calendar icon
- Analytics: Bar chart icon
- User profile: User icon
- Home: Home icon
- More menu: More horizontal icon

### Emotional Indicators
- Great: Smile icon in #87CBB9 (Mint)
- Good: Smile icon in #A5D8FF (Soft Blue)
- Fair: Meh icon in #FFD6E0 (Soft Pink)
- Poor: Frown icon in #FF9BB4 (Medium Pink)

## Mobile App Specifications

- Screen dimensions: 375px width, 812px height
- Border radius for device frame: 40px
- Device frame styling: Box shadow 0 0 0 10px #e0e0e0, 0 0 0 11px #f5f5f5

## Brand Application Examples

### Sleep Tracking Screen
- Timer circle with white inner circle
- Start/stop buttons with appropriate colors
- Quality indicators with emotional icons
- Recent sleep history cards

### Home Screen
- Welcoming header with gradient
- Quick action cards for common tasks
- Today's schedule with time indicators
- Sleep insights with progress visualization

### Sound Player
- Custom range input styling
- Player controls with intuitive icons
- Sound categories with visual differentiation

## Accessibility Guidelines

- Maintain sufficient contrast between text and backgrounds
- Use semantic HTML elements
- Ensure interactive elements have appropriate hover/focus states
- Provide clear visual feedback for all user interactions

## File Naming Conventions

- All lowercase
- Hyphen-separated words
- Descriptive of content (e.g., sleep-tracking.html, feeding-tracking.html)
