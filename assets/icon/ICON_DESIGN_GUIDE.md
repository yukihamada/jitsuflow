# JitsuFlow Icon Design Guide

## Icon Design Requirements

### Technical Specifications
- **Size**: 1024x1024 pixels (minimum)
- **Format**: PNG with transparency
- **Color depth**: 24-bit or 32-bit (with alpha channel)
- **File name**: `app_icon.png`

### Design Guidelines

#### Visual Elements to Consider
1. **Brazilian Jiu-Jitsu Theme**
   - Belt colors (white, blue, purple, brown, black)
   - Gi (uniform) elements
   - Grappling positions or silhouettes
   - Traditional Japanese/Brazilian patterns

2. **App Identity**
   - Include "JF" or "JitsuFlow" text
   - Modern, clean design
   - Professional appearance suitable for a sports/fitness app

3. **Color Scheme**
   - Primary: Blue (#1E40AF) - representing trust and professionalism
   - Accent: Orange/Yellow (#F59E0B) - representing energy and progression
   - White/Light colors for contrast

### Platform Considerations
- **iOS**: Icon will be automatically rounded and given a slight shadow
- **Android**: Consider that icon may be displayed in various shapes (circle, squircle, etc.)
- **Web**: Will be used as favicon and PWA icon

### How to Update the Icon

1. Create your icon design following the guidelines above
2. Save it as `app_icon.png` in the `assets/icon/` directory
3. Run the following commands:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```
4. The icons will be automatically generated for all platforms

### Current Placeholder
The current icon is a basic placeholder with:
- Blue background
- Orange belt shape
- "JF" text in white

Please replace this with a professional design that better represents the JitsuFlow brand and Brazilian Jiu-Jitsu culture.