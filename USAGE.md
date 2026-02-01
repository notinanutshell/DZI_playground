# DZI Viewer Usage Guide

This guide will help you get started with the DZI (Deep Zoom Image) viewer.

## Quick Start

1. **Open the viewer**: Double-click `index.html` or drag it into your web browser
2. **Select your files**: 
   - Click "Select DZI File" and choose your `.dzi` file
   - Click "Select Image Tiles Folder" and choose the `_files` folder
3. **View your image**: Click "Load DZI Image"

## What You'll Need

### DZI File Structure
A valid DZI image consists of two parts:
- A `.dzi` XML file (e.g., `image.dzi`)
- A `_files` folder containing the image tiles (e.g., `image_files/`)

Example structure:
```
my-image.dzi
my-image_files/
  ├── 0/
  │   └── 0_0.jpg
  ├── 1/
  │   ├── 0_0.jpg
  │   └── 0_1.jpg
  ├── 2/
  │   └── ... (more tiles)
  └── ... (more zoom levels)
```

### Creating DZI Files

If you don't have DZI files yet, you can create them using various tools:

#### Using Python (with PIL/Pillow)
```python
from PIL import Image
import os

def create_dzi(image_path, output_path):
    # Use a DZI generator library like pyvips or deepzoom
    pass
```

#### Using VIPS
```bash
vips dzsave input.jpg output
# This creates output.dzi and output_files/
```

#### Using ImageMagick
```bash
convert input.jpg -define dzi:tile-size=256 output.dzi
```

## Viewer Controls

Once your image is loaded, you can:
- **Zoom**: Use mouse wheel or pinch gestures
- **Pan**: Click and drag the image
- **Navigate**: Use the mini-map in the bottom-right corner (if shown)
- **Reset**: Refresh the page to start over

## Troubleshooting

### "OpenSeadragon library failed to load"
- **Cause**: No internet connection or CDN is blocked
- **Solution**: Ensure you have internet access and can reach cdn.jsdelivr.net

### "Please select a DZI file first"
- **Cause**: You tried to load without selecting a DZI file
- **Solution**: Click "Choose File" and select your `.dzi` file

### "Please select the tiles folder"
- **Cause**: You haven't selected the folder containing the tile images
- **Solution**: Click "Choose Files" for the folder input and select the `_files` folder

### Image not displaying
- **Check**: Is your folder named correctly? (e.g., `image_files` for `image.dzi`)
- **Check**: Does the folder contain numbered subdirectories (0, 1, 2, etc.)?
- **Check**: Open the browser console (F12) to see any error messages

### Tiles not loading
- **Cause**: File path mismatch or incorrect folder structure
- **Check**: Console logs show which tiles are being requested
- **Verify**: The tiles are in the format `level/x_y.jpg` (or .png)

## Browser Compatibility

### Recommended Browsers
- ✅ Google Chrome (latest)
- ✅ Microsoft Edge (latest)
- ✅ Mozilla Firefox (latest)
- ✅ Safari (latest)

### Required Features
- HTML5 File API support
- ES6 JavaScript support
- Blob URL support

## Advanced Usage

### Loading Multiple Images
To load a different image:
1. Select new files using the file inputs
2. Click "Load DZI Image" again
3. The old image will be automatically cleaned up

### Memory Considerations
- Large DZI images with many tiles will create many Blob URLs
- The viewer automatically cleans up these URLs when:
  - You load a new image
  - You close the browser tab/window
- For very large images (10,000+ tiles), consider using a smaller tile size when generating DZI files

## Privacy & Security

✅ **Your images stay on your machine**
- No data is sent to any server
- Files are read locally using browser APIs
- Blob URLs are created in-memory only

✅ **No tracking or analytics**
- This viewer doesn't collect any data
- No cookies are used
- Completely offline after the OpenSeadragon library loads

## Tips for Best Results

1. **File Organization**: Keep your `.dzi` file and `_files` folder in the same directory
2. **File Names**: Use simple names without special characters
3. **Tile Size**: 254-256 pixels is optimal for web viewing
4. **Format**: JPEG for photographs, PNG for images with transparency
5. **Internet**: You need internet only once to load the OpenSeadragon library

## Example DZI XML

Here's what a typical `.dzi` file looks like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Image xmlns="http://schemas.microsoft.com/deepzoom/2008"
  Format="jpg"
  Overlap="1"
  TileSize="254">
  <Size Height="4096" Width="4096"/>
</Image>
```

Key attributes:
- **Format**: Image format (jpg, png, etc.)
- **Overlap**: Pixel overlap between tiles (usually 0-2)
- **TileSize**: Size of each tile in pixels (usually 254 or 256)
- **Height/Width**: Full resolution of the original image

## Getting Help

If you encounter issues:
1. Check the browser console (F12) for error messages
2. Verify your DZI file structure matches the expected format
3. Try with a different browser
4. Create an issue on the GitHub repository with:
   - Browser version
   - Error messages from console
   - DZI file structure details

## License

This viewer is free to use for any purpose. The OpenSeadragon library has its own license (BSD).
