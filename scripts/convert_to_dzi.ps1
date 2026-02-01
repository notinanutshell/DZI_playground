# =============================================================================
# DZI Converter Script for Windows
# Converts medical imaging files (SVS, NDPI, etc.) and standard images to DZI
# =============================================================================
# 
# PREREQUISITES:
#   1. Install VIPS: Download from https://github.com/libvips/libvips/releases
#   2. Add VIPS to PATH or install via: winget install libvips
#
# USAGE:
#   Right-click this file and select "Run with PowerShell"
#   Or run from PowerShell: .\convert_to_dzi.ps1
#
# =============================================================================

# Set console encoding for emoji support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Colors
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
    Magenta = "Magenta"
    White = "White"
}

# Print banner
function Show-Banner {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host "   DZI Converter - Deep Zoom Image Generator" -ForegroundColor Cyan
    Write-Host "   Convert SVS, NDPI, TIFF, JPG, PNG to DZI format" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host ""
}

# Print section header
function Show-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor Blue
    Write-Host "  $Title" -ForegroundColor Blue
    Write-Host "------------------------------------------------------------" -ForegroundColor Blue
}

# Check if VIPS is installed
function Test-VipsInstalled {
    Show-Section "Checking Dependencies"
    
    try {
        $vipsVersion = & vips --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] VIPS found: $vipsVersion" -ForegroundColor Green
            
            # Check for OpenSlide support
            $openslideCheck = & vips openslideload 2>&1
            if ($openslideCheck -match "usage") {
                Write-Host "[OK] OpenSlide support: Available" -ForegroundColor Green
                return @{ Installed = $true; OpenSlide = $true }
            } else {
                Write-Host "[!] OpenSlide support: Not available" -ForegroundColor Yellow
                Write-Host "    SVS, NDPI, MRXS files may not work" -ForegroundColor Yellow
                return @{ Installed = $true; OpenSlide = $false }
            }
        }
    } catch {
        # VIPS not found
    }
    
    Write-Host "[X] VIPS is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To install VIPS on Windows:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Option 1: Using winget (recommended)" -ForegroundColor Cyan
    Write-Host "    winget install libvips" -ForegroundColor White
    Write-Host ""
    Write-Host "  Option 2: Manual download" -ForegroundColor Cyan
    Write-Host "    1. Go to: https://github.com/libvips/libvips/releases" -ForegroundColor White
    Write-Host "    2. Download: vips-dev-w64-all-x.x.x.zip" -ForegroundColor White
    Write-Host "    3. Extract to C:\vips" -ForegroundColor White
    Write-Host "    4. Add C:\vips\bin to your PATH" -ForegroundColor White
    Write-Host ""
    Write-Host "  Option 3: Using Chocolatey" -ForegroundColor Cyan
    Write-Host "    choco install libvips" -ForegroundColor White
    Write-Host ""
    
    Read-Host "Press Enter to exit"
    exit 1
}

# Get input directory
function Get-InputDirectory {
    Show-Section "Select Input Directory"
    
    Write-Host "Enter the path to the folder containing your images:"
    Write-Host "(You can paste a path or drag and drop a folder here)" -ForegroundColor Cyan
    Write-Host ""
    
    $inputDir = Read-Host "Input directory"
    
    # Remove quotes if present
    $inputDir = $inputDir.Trim('"', "'", ' ')
    
    if (-not (Test-Path $inputDir -PathType Container)) {
        Write-Host "[X] Directory not found: $inputDir" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host "[OK] Input directory: $inputDir" -ForegroundColor Green
    return $inputDir
}

# Get output directory
function Get-OutputDirectory {
    param([string]$InputDir)
    
    Show-Section "Select Output Directory"
    
    $defaultOutput = Join-Path $InputDir "dzi_output"
    
    Write-Host "Enter the path for the output DZI files:"
    Write-Host "(Press Enter to use: $defaultOutput)" -ForegroundColor Cyan
    Write-Host ""
    
    $outputDir = Read-Host "Output directory"
    
    if ([string]::IsNullOrWhiteSpace($outputDir)) {
        $outputDir = $defaultOutput
    }
    
    # Remove quotes if present
    $outputDir = $outputDir.Trim('"', "'", ' ')
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    Write-Host "[OK] Output directory: $outputDir" -ForegroundColor Green
    return $outputDir
}

# Select file types
function Select-FileTypes {
    param([bool]$HasOpenSlide)
    
    Show-Section "Select File Types to Convert"
    
    Write-Host "Which file types do you want to convert?"
    Write-Host ""
    Write-Host "  1) SVS files only (Aperio whole slide images)" -ForegroundColor Cyan
    Write-Host "  2) All pathology formats (SVS, NDPI, MRXS, SCN, VMS, BIF)" -ForegroundColor Cyan
    Write-Host "  3) Standard images only (JPG, JPEG, PNG)" -ForegroundColor Cyan
    Write-Host "  4) TIFF files only (TIF, TIFF)" -ForegroundColor Cyan
    Write-Host "  5) All supported formats" -ForegroundColor Cyan
    Write-Host "  6) Custom (enter your own extensions)" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "Enter your choice [1-6]"
    
    switch ($choice) {
        "1" {
            $extensions = @("*.svs")
            $description = "SVS files"
        }
        "2" {
            $extensions = @("*.svs", "*.ndpi", "*.mrxs", "*.scn", "*.vms", "*.bif")
            $description = "pathology formats"
            if (-not $HasOpenSlide) {
                Write-Host "[!] Warning: OpenSlide not available. Some formats may not work." -ForegroundColor Yellow
            }
        }
        "3" {
            $extensions = @("*.jpg", "*.jpeg", "*.png")
            $description = "standard images"
        }
        "4" {
            $extensions = @("*.tif", "*.tiff")
            $description = "TIFF files"
        }
        "5" {
            $extensions = @("*.svs", "*.ndpi", "*.mrxs", "*.scn", "*.vms", "*.bif", "*.jpg", "*.jpeg", "*.png", "*.tif", "*.tiff")
            $description = "all supported formats"
        }
        "6" {
            Write-Host ""
            $customInput = Read-Host "Enter file extensions separated by spaces (e.g., svs jpg png)"
            $extensions = $customInput.Split(' ') | ForEach-Object { "*.$_" }
            $description = "custom formats ($customInput)"
        }
        default {
            $extensions = @("*.svs")
            $description = "SVS files"
        }
    }
    
    Write-Host "[OK] Selected: $description" -ForegroundColor Green
    return @{ Extensions = $extensions; Description = $description }
}

# Get quality settings
function Get-QualitySettings {
    Show-Section "Quality Settings"
    
    Write-Host "Select JPEG quality for output tiles:"
    Write-Host ""
    Write-Host "  1) High quality (Q=95) - Best for diagnostic viewing, larger files" -ForegroundColor Cyan
    Write-Host "  2) Good quality (Q=90) - Recommended balance [DEFAULT]" -ForegroundColor Cyan
    Write-Host "  3) Medium quality (Q=80) - Smaller files, good for previews" -ForegroundColor Cyan
    Write-Host "  4) Custom quality" -ForegroundColor Cyan
    Write-Host ""
    
    $qualityChoice = Read-Host "Enter your choice [1-4] (default: 2)"
    
    switch ($qualityChoice) {
        "1" { $quality = 95 }
        "3" { $quality = 80 }
        "4" {
            $customQuality = Read-Host "Enter quality (1-100)"
            $quality = [int]$customQuality
            if ($quality -lt 1 -or $quality -gt 100) {
                Write-Host "[!] Invalid quality. Using default (90)." -ForegroundColor Yellow
                $quality = 90
            }
        }
        default { $quality = 90 }
    }
    
    Write-Host "[OK] Quality setting: $quality" -ForegroundColor Green
    
    # Tile size
    Write-Host ""
    Write-Host "Select tile size:"
    Write-Host "  1) 254 pixels [DEFAULT] - Standard for web viewing" -ForegroundColor Cyan
    Write-Host "  2) 256 pixels - Alternative standard" -ForegroundColor Cyan
    Write-Host "  3) 512 pixels - Fewer tiles, may be faster to load" -ForegroundColor Cyan
    Write-Host ""
    
    $tileChoice = Read-Host "Enter your choice [1-3] (default: 1)"
    
    switch ($tileChoice) {
        "2" { $tileSize = 256 }
        "3" { $tileSize = 512 }
        default { $tileSize = 254 }
    }
    
    Write-Host "[OK] Tile size: ${tileSize}px" -ForegroundColor Green
    
    return @{ Quality = $quality; TileSize = $tileSize }
}

# Find files to convert
function Find-FilesToConvert {
    param(
        [string]$InputDir,
        [string[]]$Extensions
    )
    
    Show-Section "Scanning for Files"
    
    $files = @()
    foreach ($ext in $Extensions) {
        $found = Get-ChildItem -Path $InputDir -Filter $ext -File -ErrorAction SilentlyContinue
        $files += $found
    }
    
    if ($files.Count -eq 0) {
        Write-Host "[X] No matching files found in: $InputDir" -ForegroundColor Red
        Write-Host "    Looking for: $($Extensions -join ', ')" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host "[OK] Found $($files.Count) file(s) to convert:" -ForegroundColor Green
    Write-Host ""
    
    foreach ($file in $files) {
        $size = "{0:N2} MB" -f ($file.Length / 1MB)
        Write-Host "   - $($file.Name) ($size)" -ForegroundColor Cyan
    }
    
    return $files
}

# Confirm conversion
function Confirm-Conversion {
    param(
        [string]$InputDir,
        [string]$OutputDir,
        [int]$FileCount,
        [int]$Quality,
        [int]$TileSize
    )
    
    Show-Section "Ready to Convert"
    
    Write-Host ""
    Write-Host "  Input:      $InputDir" -ForegroundColor Cyan
    Write-Host "  Output:     $OutputDir" -ForegroundColor Cyan
    Write-Host "  Files:      $FileCount file(s)" -ForegroundColor Cyan
    Write-Host "  Quality:    $Quality" -ForegroundColor Cyan
    Write-Host "  Tile size:  ${TileSize}px" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Proceed with conversion? [Y/n]"
    
    if ($confirm -match "^[Nn]") {
        Write-Host "[!] Conversion cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Convert files
function Convert-Files {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$OutputDir,
        [int]$Quality,
        [int]$TileSize
    )
    
    Show-Section "Converting Files"
    
    $successCount = 0
    $failCount = 0
    
    foreach ($file in $Files) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $outputPath = Join-Path $OutputDir $name
        
        Write-Host ""
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host "Converting: $($file.Name)" -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
        
        $startTime = Get-Date
        
        try {
            $result = & vips dzsave $file.FullName $outputPath --tile-size=$TileSize --overlap=1 --Q=$Quality 2>&1
            
            $dziFile = "$outputPath.dzi"
            $tilesDir = "${outputPath}_files"
            
            if (Test-Path $dziFile) {
                $endTime = Get-Date
                $duration = [math]::Round(($endTime - $startTime).TotalSeconds, 1)
                
                $dziSize = (Get-Item $dziFile).Length
                $dziSizeStr = "{0:N2} KB" -f ($dziSize / 1KB)
                
                $tilesCount = (Get-ChildItem -Path $tilesDir -Recurse -File).Count
                $levelsCount = (Get-ChildItem -Path $tilesDir -Directory).Count
                
                Write-Host "[OK] Success!" -ForegroundColor Green
                Write-Host "     DZI file: $dziSizeStr"
                Write-Host "     Tiles: $tilesCount"
                Write-Host "     Zoom levels: $levelsCount"
                Write-Host "     Time: ${duration}s"
                
                $successCount++
            } else {
                throw "DZI file not created"
            }
        } catch {
            Write-Host "[X] Failed to convert: $($file.Name)" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Red
            Write-Host "    Try running: vips dzsave `"$($file.FullName)`" test_output" -ForegroundColor Yellow
            $failCount++
        }
    }
    
    # Print summary
    Show-Section "Conversion Summary"
    
    Write-Host ""
    Write-Host "  Successful: $successCount" -ForegroundColor Green
    Write-Host "  Failed:     $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "White" })
    Write-Host "  Output:     $OutputDir" -ForegroundColor Cyan
    Write-Host ""
    
    if ($successCount -gt 0) {
        Write-Host "Your DZI files are ready!" -ForegroundColor Green
        Write-Host "Open the DZI Viewer and select your .dzi files to view them." -ForegroundColor Cyan
    }
    Write-Host ""
}

# Main function
function Main {
    Show-Banner
    
    $vipsCheck = Test-VipsInstalled
    
    $inputDir = Get-InputDirectory
    $outputDir = Get-OutputDirectory -InputDir $inputDir
    
    $fileTypes = Select-FileTypes -HasOpenSlide $vipsCheck.OpenSlide
    $settings = Get-QualitySettings
    
    $files = Find-FilesToConvert -InputDir $inputDir -Extensions $fileTypes.Extensions
    
    Confirm-Conversion -InputDir $inputDir -OutputDir $outputDir -FileCount $files.Count -Quality $settings.Quality -TileSize $settings.TileSize
    
    Convert-Files -Files $files -OutputDir $outputDir -Quality $settings.Quality -TileSize $settings.TileSize
    
    Read-Host "Press Enter to exit"
}

# Run main function
Main
