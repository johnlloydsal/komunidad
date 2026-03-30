    #!/usr/bin/env python3
"""
Generate white PNG icons for Android app
"""
from PIL import Image, ImageDraw
import os

# Create directories
sizes = {
    'mipmap-hdpi': 72,
    'mipmap-mdpi': 48,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

for folder, size in sizes.items():
    path = f'android/app/src/main/res/{folder}'
    os.makedirs(path, exist_ok=True)
    
    # Create image with blue background
    img = Image.new('RGBA', (size, size), color=(0, 56, 168, 255))  # Blue: #0038A8
    draw = ImageDraw.Draw(img)
    
    # Draw white roof (triangle) at top
    roof_height = size // 3
    roof_base_y = int(size * 0.6)
    
    # Roof triangle in white
    roof_points = [
        (size // 2, int(size * 0.15)),  # Peak
        (int(size * 0.1), roof_base_y),  # Bottom left
        (int(size * 0.9), roof_base_y),  # Bottom right
    ]
    draw.polygon(roof_points, fill=(255, 255, 255, 255))  # White
    
    # Draw roof ridge (white line down the middle)
    ridge_x = size // 2
    draw.line([(ridge_x, int(size * 0.15)), (ridge_x, roof_base_y)], 
              fill=(255, 255, 255, 255), width=2)
    
    # Draw building (dark blue rectangle)
    building_top = roof_base_y
    draw.rectangle([int(size * 0.15), building_top, int(size * 0.85), int(size * 0.95)],
                   fill=(30, 58, 138, 255), outline=(30, 58, 138, 255))
    
    # Draw window (white pane)
    window_margin = int(size * 0.25)
    window_size = int(size * 0.15)
    draw.rectangle([window_margin, building_top + int(size * 0.1),
                    window_margin + window_size, building_top + window_size + int(size * 0.05)],
                   fill=(255, 255, 255, 255))
    
    # Draw door (white with handle)
    door_x1 = int(size * 0.55)
    door_y1 = building_top + int(size * 0.1)
    door_width = int(size * 0.15)
    door_height = int(size * 0.3)
    draw.rectangle([door_x1, door_y1, door_x1 + door_width, door_y1 + door_height],
                   fill=(255, 255, 255, 255))
    
    # Save image
    img.save(f'{path}/ic_launcher_foreground.png')
    print(f'Created {path}/ic_launcher_foreground.png (size: {size}x{size})')

print("Icon generation complete!")
