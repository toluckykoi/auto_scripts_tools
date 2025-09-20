#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-09-20 22:55:16
# @version     : bash
# @Update time :
# @Description : gnome 桌面壁纸自动切换


WALLPAPER_DIR="$HOME/Pictures/wallpapers/"
STATE_FILE="$HOME/Pictures/wallpapers/.wallpaper_index"

MODE="random"
export DISPLAY=":0"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper directory not found. Creating: $WALLPAPER_DIR"
    mkdir -p "$WALLPAPER_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory $WALLPAPER_DIR" >&2
        exit 1
    fi
fi

if [[ "$1" == "--sequential" || "$1" == "-s" ]]; then
    MODE="sequential"
elif [[ "$1" == "--random" || "$1" == "-r" ]]; then
    MODE="random"
fi

IMAGE_LIST=($(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.gif" \) | sort))
TOTAL_IMAGES=${#IMAGE_LIST[@]}

if [ $TOTAL_IMAGES -eq 0 ]; then
    echo "Error: No images found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Select wallpaper based on mode
if [ "$MODE" = "sequential" ]; then
    # Read last index from state file, default to -1
    if [ -f "$STATE_FILE" ]; then
        LAST_INDEX=$(cat "$STATE_FILE")
        # Validate index
        if ! [[ "$LAST_INDEX" =~ ^[0-9]+$ ]] || [ "$LAST_INDEX" -ge "$TOTAL_IMAGES" ]; then
            LAST_INDEX=-1
        fi
    else
        LAST_INDEX=-1
    fi

    NEXT_INDEX=$(( (LAST_INDEX + 1) % TOTAL_IMAGES ))
    SELECTED_WALLPAPER="${IMAGE_LIST[$NEXT_INDEX]}"
    echo "$NEXT_INDEX" > "$STATE_FILE"

else
    SELECTED_WALLPAPER=$(printf '%s\n' "${IMAGE_LIST[@]}" | shuf -n 1)
fi

COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)

if [ -z "$COLOR_SCHEME" ]; then
    COLOR_SCHEME="'default'"
fi

if [ "$COLOR_SCHEME" = "'prefer-dark'" ]; then
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$SELECTED_WALLPAPER"
    echo "Dark mode wallpaper set to: $SELECTED_WALLPAPER"
else
    gsettings set org.gnome.desktop.background picture-uri "file://$SELECTED_WALLPAPER"
    echo "Light mode wallpaper set to: $SELECTED_WALLPAPER"
fi
