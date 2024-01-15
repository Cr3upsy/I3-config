#!/bin/bash

BLANK='#00000000'
CLEAR='ffffff22'
DEFAULT='#fffed6'
TEXT='#fffed6'
WRONG='#880000bb'
VERIFYING='#fffed6'


# Set the path to your image folder
IMAGE_FOLDER="~/Documents/Background/i3lock"

# Get the screen dimensions
screen_dimensions=$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/')


# Loop through all files in the folder
for image_path in "$IMAGE_FOLDER"/*; do
    # Check if the image name contains "retouched"
    if [[ "$image_path" == *"retouched"* ]]; then
        echo "No processing is done on the image $image_path"
    else
        # Resize the image based on the screen dimensions, maintaining proportions
        convert "$image_path" -resize "$screen_dimensions^" -gravity center -extent "$screen_dimensions" "${image_path%.*}.${image_path##*.}"

        echo "Processing applied to $image_path. New file: ${image_path%.*}_resized.${image_path##*.}"
        # Get the dimensions of the image
        read width height <<< $(identify -format "%w %h" "$image_path")

        # Calculate the coordinates of the center of the image
        center_x=$((width / 2))
        center_y=$((height / 2))

        # Set the size of the black square (300x300 pixels)
        square_size="300"
        
        # Set radius to square borders
        radius="20"        
        
        # Set the transparency (60%)
        transparency="0.8"

        # Use ImageMagick to add a semi-transparent black square to the center of the image
        convert "$image_path" -fill "rgba(0,0,0,$transparency)" -draw "roundrectangle $((center_x - square_size/2)),$((center_y - square_size/2)) $((center_x + square_size/2)),$((center_y + square_size/2)) $radius,$radius" "${image_path%.*}_retouched.${image_path##*.}"

        echo "Processing applied to $image_path. New file: ${image_path%.*}_retouched.${image_path##*.}"
        # Removing the original image
        rm "${image_path%.*}.${image_path##*.}"
    fi
done

# Check that only .png files are in the repository, i3lock doesn't accept other format.
# Get a random image from the folder
RANDOM_IMAGE=$(find "$IMAGE_FOLDER" -type f -name "*.png" | shuf -n 1)

# suspend message display
pkill -u "$USER" -USR1 dunst
i3-msg bar mode invisible
 
i3lock \
--insidever-color=$CLEAR     \
--ringver-color=$VERIFYING   \
\
--insidewrong-color=$CLEAR   \
--ringwrong-color=$WRONG     \
\
--inside-color=$BLANK        \
--ring-color=$DEFAULT        \
--line-color=$BLANK          \
--separator-color=$DEFAULT   \
\
--verif-color=$TEXT          \
--wrong-color=$TEXT          \
--time-color=$TEXT           \
--date-color=$TEXT           \
--layout-color=$TEXT         \
--keyhl-color=$WRONG         \
--bshl-color=$WRONG          \
--wrong-text="Try again"	     \
--screen 1                   \
--clock                      \
--indicator                  \
--time-str="%H:%M:%S"        \
--date-str="%A, %m %Y"       \
--keylayout 1                \
--image $RANDOM_IMAGE

# resume message display
pkill -u "$USER" -USR2 dunst
i3-msg bar mode dock

