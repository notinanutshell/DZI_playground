#!/bin/bash
# =============================================================================
# DZI Converter Script for macOS/Linux
# Converts medical imaging files (SVS, NDPI, etc.) and standard images to DZI
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emoji icons
ICON_MICROSCOPE="🔬"
ICON_FOLDER="📁"
ICON_SUCCESS="✅"
ICON_ERROR="❌"
ICON_WARNING="⚠️"
ICON_INFO="ℹ️"
ICON_ROCKET="🚀"
ICON_PARROT="🦜"

# Print banner
print_banner() {
    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${ICON_PARROT} ${CYAN}DZI Converter - Deep Zoom Image Generator${NC}           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     Convert SVS, NDPI, TIFF, JPG, PNG to DZI format       ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print section header
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if vips is installed
check_vips() {
    print_section "${ICON_INFO} Checking Dependencies"
    
    if ! command -v vips &> /dev/null; then
        echo -e "${RED}${ICON_ERROR} VIPS is not installed!${NC}"
        echo ""
        echo -e "${YELLOW}To install VIPS on macOS:${NC}"
        echo "  brew install vips"
        echo ""
        echo -e "${YELLOW}To install VIPS on Linux (Ubuntu/Debian):${NC}"
        echo "  sudo apt-get install libvips-tools"
        echo ""
        echo -e "${YELLOW}To install VIPS on Linux (Fedora):${NC}"
        echo "  sudo dnf install vips-tools"
        echo ""
        exit 1
    fi
    
    VIPS_VERSION=$(vips --version | head -1)
    echo -e "${GREEN}${ICON_SUCCESS} VIPS found: ${VIPS_VERSION}${NC}"
    
    # Check for OpenSlide support (needed for SVS files)
    if vips openslideload 2>&1 | grep -q "usage"; then
        echo -e "${GREEN}${ICON_SUCCESS} OpenSlide support: Available${NC}"
        HAS_OPENSLIDE=true
    else
        echo -e "${YELLOW}${ICON_WARNING} OpenSlide support: Not available${NC}"
        echo -e "${YELLOW}   SVS, NDPI, MRXS files may not work${NC}"
        HAS_OPENSLIDE=false
    fi
}

# Get input directory from user
get_input_directory() {
    print_section "${ICON_FOLDER} Select Input Directory"
    
    echo -e "Enter the path to the folder containing your images:"
    echo -e "${CYAN}(You can drag and drop a folder here, or type the path)${NC}"
    echo ""
    read -r -p "📂 Input directory: " INPUT_DIR
    
    # Remove quotes if present (from drag and drop)
    INPUT_DIR="${INPUT_DIR%\"}"
    INPUT_DIR="${INPUT_DIR#\"}"
    INPUT_DIR="${INPUT_DIR%\'}"
    INPUT_DIR="${INPUT_DIR#\'}"
    
    # Expand ~ to home directory
    INPUT_DIR="${INPUT_DIR/#\~/$HOME}"
    
    # Remove trailing slash
    INPUT_DIR="${INPUT_DIR%/}"
    
    if [ ! -d "$INPUT_DIR" ]; then
        echo -e "${RED}${ICON_ERROR} Directory not found: $INPUT_DIR${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}${ICON_SUCCESS} Input directory: $INPUT_DIR${NC}"
}

# Get output directory from user
get_output_directory() {
    print_section "${ICON_FOLDER} Select Output Directory"
    
    echo -e "Enter the path for the output DZI files:"
    echo -e "${CYAN}(Press Enter to use: ${INPUT_DIR}/dzi_output)${NC}"
    echo ""
    read -r -p "📂 Output directory: " OUTPUT_DIR
    
    if [ -z "$OUTPUT_DIR" ]; then
        OUTPUT_DIR="${INPUT_DIR}/dzi_output"
    fi
    
    # Remove quotes and expand ~
    OUTPUT_DIR="${OUTPUT_DIR%\"}"
    OUTPUT_DIR="${OUTPUT_DIR#\"}"
    OUTPUT_DIR="${OUTPUT_DIR%\'}"
    OUTPUT_DIR="${OUTPUT_DIR#\'}"
    OUTPUT_DIR="${OUTPUT_DIR/#\~/$HOME}"
    OUTPUT_DIR="${OUTPUT_DIR%/}"
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    echo -e "${GREEN}${ICON_SUCCESS} Output directory: $OUTPUT_DIR${NC}"
}

# Let user select file types
select_file_types() {
    print_section "${ICON_MICROSCOPE} Select File Types to Convert"
    
    echo -e "Which file types do you want to convert?"
    echo ""
    echo -e "  ${CYAN}1)${NC} SVS files only (Aperio whole slide images)"
    echo -e "  ${CYAN}2)${NC} All pathology formats (SVS, NDPI, MRXS, SCN, VMS, BIF)"
    echo -e "  ${CYAN}3)${NC} Standard images only (JPG, JPEG, PNG)"
    echo -e "  ${CYAN}4)${NC} TIFF files only (TIF, TIFF)"
    echo -e "  ${CYAN}5)${NC} All supported formats"
    echo -e "  ${CYAN}6)${NC} Custom (enter your own extensions)"
    echo ""
    read -r -p "Enter your choice [1-6]: " FILE_TYPE_CHOICE
    
    case $FILE_TYPE_CHOICE in
        1)
            FILE_EXTENSIONS=("svs" "SVS")
            FILE_TYPE_DESC="SVS files"
            ;;
        2)
            FILE_EXTENSIONS=("svs" "SVS" "ndpi" "NDPI" "mrxs" "MRXS" "scn" "SCN" "vms" "VMS" "bif" "BIF")
            FILE_TYPE_DESC="pathology formats"
            if [ "$HAS_OPENSLIDE" = false ]; then
                echo -e "${YELLOW}${ICON_WARNING} Warning: OpenSlide not available. Some formats may not work.${NC}"
            fi
            ;;
        3)
            FILE_EXTENSIONS=("jpg" "JPG" "jpeg" "JPEG" "png" "PNG")
            FILE_TYPE_DESC="standard images"
            ;;
        4)
            FILE_EXTENSIONS=("tif" "TIF" "tiff" "TIFF")
            FILE_TYPE_DESC="TIFF files"
            ;;
        5)
            FILE_EXTENSIONS=("svs" "SVS" "ndpi" "NDPI" "mrxs" "MRXS" "scn" "SCN" "vms" "VMS" "bif" "BIF" "jpg" "JPG" "jpeg" "JPEG" "png" "PNG" "tif" "TIF" "tiff" "TIFF")
            FILE_TYPE_DESC="all supported formats"
            ;;
        6)
            echo ""
            echo -e "Enter file extensions separated by spaces (e.g., svs jpg png):"
            read -r -p "Extensions: " CUSTOM_EXTENSIONS
            FILE_EXTENSIONS=()
            for ext in $CUSTOM_EXTENSIONS; do
                FILE_EXTENSIONS+=("$ext" "${ext^^}")
            done
            FILE_TYPE_DESC="custom formats ($CUSTOM_EXTENSIONS)"
            ;;
        *)
            echo -e "${RED}${ICON_ERROR} Invalid choice. Using SVS files only.${NC}"
            FILE_EXTENSIONS=("svs" "SVS")
            FILE_TYPE_DESC="SVS files"
            ;;
    esac
    
    echo -e "${GREEN}${ICON_SUCCESS} Selected: $FILE_TYPE_DESC${NC}"
}

# Get quality settings
get_quality_settings() {
    print_section "⚙️  Quality Settings"
    
    echo -e "Select JPEG quality for output tiles:"
    echo ""
    echo -e "  ${CYAN}1)${NC} High quality (Q=95) - Best for diagnostic viewing, larger files"
    echo -e "  ${CYAN}2)${NC} Good quality (Q=90) - Recommended balance [DEFAULT]"
    echo -e "  ${CYAN}3)${NC} Medium quality (Q=80) - Smaller files, good for previews"
    echo -e "  ${CYAN}4)${NC} Custom quality"
    echo ""
    read -r -p "Enter your choice [1-4] (default: 2): " QUALITY_CHOICE
    
    case $QUALITY_CHOICE in
        1)
            QUALITY=95
            ;;
        3)
            QUALITY=80
            ;;
        4)
            read -r -p "Enter quality (1-100): " QUALITY
            if ! [[ "$QUALITY" =~ ^[0-9]+$ ]] || [ "$QUALITY" -lt 1 ] || [ "$QUALITY" -gt 100 ]; then
                echo -e "${YELLOW}${ICON_WARNING} Invalid quality. Using default (90).${NC}"
                QUALITY=90
            fi
            ;;
        *)
            QUALITY=90
            ;;
    esac
    
    echo -e "${GREEN}${ICON_SUCCESS} Quality setting: $QUALITY${NC}"
    
    # Tile size
    echo ""
    echo -e "Select tile size:"
    echo -e "  ${CYAN}1)${NC} 254 pixels [DEFAULT] - Standard for web viewing"
    echo -e "  ${CYAN}2)${NC} 256 pixels - Alternative standard"
    echo -e "  ${CYAN}3)${NC} 512 pixels - Fewer tiles, may be faster to load"
    echo ""
    read -r -p "Enter your choice [1-3] (default: 1): " TILE_CHOICE
    
    case $TILE_CHOICE in
        2)
            TILE_SIZE=256
            ;;
        3)
            TILE_SIZE=512
            ;;
        *)
            TILE_SIZE=254
            ;;
    esac
    
    echo -e "${GREEN}${ICON_SUCCESS} Tile size: ${TILE_SIZE}px${NC}"
}

# Find files to convert
find_files() {
    print_section "🔍 Scanning for Files"
    
    FILES_TO_CONVERT=()
    
    for ext in "${FILE_EXTENSIONS[@]}"; do
        while IFS= read -r -d '' file; do
            FILES_TO_CONVERT+=("$file")
        done < <(find "$INPUT_DIR" -maxdepth 1 -type f -name "*.$ext" -print0 2>/dev/null)
    done
    
    FILE_COUNT=${#FILES_TO_CONVERT[@]}
    
    if [ $FILE_COUNT -eq 0 ]; then
        echo -e "${RED}${ICON_ERROR} No matching files found in: $INPUT_DIR${NC}"
        echo -e "${YELLOW}Looking for: ${FILE_EXTENSIONS[*]}${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}${ICON_SUCCESS} Found $FILE_COUNT file(s) to convert:${NC}"
    echo ""
    for file in "${FILES_TO_CONVERT[@]}"; do
        filename=$(basename "$file")
        filesize=$(ls -lh "$file" | awk '{print $5}')
        echo -e "   ${CYAN}•${NC} $filename ($filesize)"
    done
}

# Confirm before processing
confirm_conversion() {
    print_section "${ICON_ROCKET} Ready to Convert"
    
    echo ""
    echo -e "  ${CYAN}Input:${NC}      $INPUT_DIR"
    echo -e "  ${CYAN}Output:${NC}     $OUTPUT_DIR"
    echo -e "  ${CYAN}Files:${NC}      $FILE_COUNT file(s)"
    echo -e "  ${CYAN}Quality:${NC}    $QUALITY"
    echo -e "  ${CYAN}Tile size:${NC}  ${TILE_SIZE}px"
    echo ""
    
    read -r -p "Proceed with conversion? [Y/n]: " CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Nn] ]]; then
        echo -e "${YELLOW}${ICON_WARNING} Conversion cancelled.${NC}"
        exit 0
    fi
}

# Convert files
convert_files() {
    print_section "${ICON_MICROSCOPE} Converting Files"
    
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    
    for file in "${FILES_TO_CONVERT[@]}"; do
        filename=$(basename "$file")
        name="${filename%.*}"
        output_path="$OUTPUT_DIR/$name"
        
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${ICON_MICROSCOPE} Converting: ${YELLOW}$filename${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        START_TIME=$(date +%s)
        
        if vips dzsave "$file" "$output_path" --tile-size=$TILE_SIZE --overlap=1 --Q=$QUALITY 2>&1; then
            END_TIME=$(date +%s)
            DURATION=$((END_TIME - START_TIME))
            
            # Get stats
            if [ -f "${output_path}.dzi" ]; then
                DZI_SIZE=$(ls -lh "${output_path}.dzi" | awk '{print $5}')
                TILES_COUNT=$(find "${output_path}_files" -type f \( -name "*.jpeg" -o -name "*.jpg" -o -name "*.png" \) 2>/dev/null | wc -l | tr -d ' ')
                LEVELS_COUNT=$(find "${output_path}_files" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
                
                echo -e "${GREEN}${ICON_SUCCESS} Success!${NC}"
                echo -e "   📊 DZI file: $DZI_SIZE"
                echo -e "   🔢 Tiles: $TILES_COUNT"
                echo -e "   📐 Zoom levels: $LEVELS_COUNT"
                echo -e "   ⏱️  Time: ${DURATION}s"
                
                ((SUCCESS_COUNT++))
            fi
        else
            echo -e "${RED}${ICON_ERROR} Failed to convert: $filename${NC}"
            echo -e "${YELLOW}   💡 Try running: VIPS_INFO=1 vips dzsave \"$file\" test_output${NC}"
            ((FAIL_COUNT++))
        fi
    done
    
    # Print summary
    print_section "📊 Conversion Summary"
    
    echo ""
    echo -e "  ${GREEN}${ICON_SUCCESS} Successful:${NC} $SUCCESS_COUNT"
    echo -e "  ${RED}${ICON_ERROR} Failed:${NC}     $FAIL_COUNT"
    echo -e "  ${CYAN}📁 Output:${NC}    $OUTPUT_DIR"
    echo ""
    
    if [ $SUCCESS_COUNT -gt 0 ]; then
        echo -e "${GREEN}${ICON_PARROT} Your DZI files are ready!${NC}"
        echo -e "${CYAN}Open the DZI Viewer and select your .dzi files to view them.${NC}"
    fi
    echo ""
}

# Main function
main() {
    print_banner
    check_vips
    get_input_directory
    get_output_directory
    select_file_types
    get_quality_settings
    find_files
    confirm_conversion
    convert_files
}

# Run main function
main
