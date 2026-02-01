# DZI_playground
View DZI Images

## Overview
A simple, client-side HTML + JavaScript viewer for Deep Zoom Images (DZI) using OpenSeadragon. This viewer allows you to view DZI files directly from your local machine without needing a web server.

## Features
- 🌐 **No Server Required**: Works entirely in the browser using the HTML5 File API
- 🔒 **Privacy**: All files stay on your local machine, no data is sent to any server
- 🎨 **Interactive Viewer**: Zoom and pan through high-resolution images smoothly
- ✅ **CORS-Free**: Uses Blob URLs to avoid Cross-Origin Resource Sharing issues
- 📱 **Modern UI**: Clean, responsive interface with clear instructions

## How to Use

### Prerequisites
- A modern web browser (Chrome, Firefox, Edge, or Safari)
- A DZI file and its corresponding tiles folder

### Steps
1. **Open the Viewer**: 
   - Simply open `index.html` in your web browser
   - You can double-click the file or drag it into your browser

2. **Select Your DZI File**:
   - Click "Select DZI File" and choose your `.dzi` file

3. **Select the Tiles Folder**:
   - Click "Select Image Tiles Folder" 
   - Choose the `_files` folder that contains all the tile images
   - The folder should have the same base name as your DZI file (e.g., if your file is `image.dzi`, the folder should be `image_files`)

4. **Load and View**:
   - Click "Load DZI Image"
   - Your image will appear in the viewer
   - Use mouse wheel to zoom, click and drag to pan

## DZI File Structure
Your DZI files should follow this structure:
```
yourimage.dzi
yourimage_files/
  ├── 0/
  │   └── 0_0.jpg
  ├── 1/
  │   ├── 0_0.jpg
  │   └── 1_0.jpg
  ├── 2/
  │   └── ...
  └── ...
```

## Technical Details
- **Library**: OpenSeadragon v4.1.0 (loaded from CDN)
- **File Handling**: HTML5 File API with FileReader
- **CORS Solution**: Uses `URL.createObjectURL()` to create blob URLs for local files
- **Browser Compatibility**: Modern browsers with File API support

## Troubleshooting

### Image Not Loading?
- Ensure your DZI file is valid XML
- Check that the tiles folder matches the naming convention (basename_files)
- Verify the folder contains the proper structure with numbered subdirectories

### Browser Compatibility Issues?
- Try using Chrome or Edge for best compatibility
- Make sure you're using a recent browser version
- Check browser console (F12) for any error messages

## License
This project is open source and available for anyone to use.
