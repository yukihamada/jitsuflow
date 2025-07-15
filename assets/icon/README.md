# JitsuFlow App Icon

## Current Icon
The current icon is a placeholder that represents:
- Blue background (representing the traditional BJJ gi color)
- Orange belt shape (representing progression and the belt system)
- "JF" letters for JitsuFlow

## Icon Requirements
- 1024x1024 PNG format for best quality
- Should work well on both light and dark backgrounds
- Consider adding BJJ-related imagery such as:
  - Gi (uniform) elements
  - Belt representation
  - Grappling silhouettes
  - Japanese/Brazilian cultural elements

## Generating Icons
To generate icons for all platforms after updating app_icon.png:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## Converting SVG to PNG
If you have an SVG icon, you can convert it to PNG using:
- Online tools like CloudConvert or SVG to PNG converters
- Command line tools like ImageMagick: `convert -background none -size 1024x1024 app_icon.svg app_icon.png`
- Design software like Figma, Sketch, or Adobe Illustrator