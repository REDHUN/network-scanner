# App Icon Instructions

## To create the app_icon.png file:

### Option 1: Manual Creation (Recommended)
1. Open any image editor (Photoshop, GIMP, Canva, etc.)
2. Create a new 1024x1024 pixel image
3. Set background color to: #2C2C2E (dark gray)
4. Add central hub: Golden circle (#D4A574) at center, ~80px radius
5. Add 8 network nodes: Smaller golden circles around center
6. Add connection lines: Semi-transparent golden lines (#D4A574 with 30% opacity)
7. Add 4 outer nodes: Very small golden circles at corners
8. Save as "app_icon.png" in this folder

### Option 2: Use Online Icon Generator
1. Go to https://appicon.co/ or similar service
2. Upload a square image with your network design
3. Download the generated icons
4. Place the 1024x1024 version here as "app_icon.png"

### Option 3: Screenshot Method
1. Run the Flutter app
2. Take a screenshot of the splash screen icon
3. Crop to square and resize to 1024x1024
4. Save as "app_icon.png"

## Design Specifications:
- Size: 1024x1024 pixels
- Background: #2C2C2E (dark gray)
- Primary color: #D4A574 (golden)
- Central hub: Large golden circle
- Network nodes: 8 smaller circles around center
- Connection lines: Semi-transparent golden
- Outer nodes: 4 tiny circles at extended positions
- No transparency in final image for best compatibility

Once you have the app_icon.png file, run:
```bash
flutter pub run flutter_launcher_icons:main
```

This will automatically generate all platform-specific icon files.