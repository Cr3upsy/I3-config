#!/bin/bash

BLANK='#00000000'
CLEAR='ffffff22'
DEFAULT='#fffed6'
TEXT='#fffed6'
WRONG='#880000bb'
VERIFYING='#fffed6'

# Get the list of connected screens
#screens=$(xrandr --query | grep " connected" | cut -d" " -f1)

# Set the path to your image folder
IMAGE_FOLDER="/home/corentin/Documents/Background/i3lock"

# Get the screen dimensions
screen_dimensions=$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/')

# Loop through all files in the folder
for image_path in "$IMAGE_FOLDER"/*; do
    # Check if the image name contains "retouched"
    if [[ "$image_path" == *"retouched"* ]]; then
        echo "No processing is done on the image $image_path"
    else
        # Resize the image based on the screen dimensions&, maintaining proportions
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

# Set the name of the primary screen
primary_screen="eDP"

# Set the name of the primary screen
primary_screen="eDP"

# Declare an associative array to store screen positions
declare -A screen_positions

# Save the current positions of the screens
connected_screens=$(xrandr | grep " connected" | awk '{ print $1 }')

for screen in $connected_screens; do
    if [ "$screen" != "$primary_screen" ]; then
        # Extract the position from the 'xrandr' output using awk
        position=$(xrandr --query | awk -v screen="$screen" '/\ connected/ && $1 == screen {print $3}' | awk -F'[+x]' '{print $(NF-1)"x"$NF}')
        screen_positions["$screen"]=$position
        xrandr --output $screen --off
    fi
done


# suspend message display
pkill -u "$USER" -USR1 dunst
i3-msg bar mode invisible

i3lock -n \
--insidever-color=$CLEAR     \
--ringver-color=$VERIFYING   \
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
--clock                      \
--indicator                  \
--time-str="%H:%M:%S"        \
--keylayout 1                \
--date-str="%A, %m %Y"       \
--screen HDMI-A-0  \
--image $RANDOM_IMAGE

wait

# resume message display
pkill -u "$USER" -USR2 dunst
i3-msg bar mode dock

# Restore the screen positions from the variables
for screen in "${!screen_positions[@]}"; do
    position=${screen_positions["$screen"]}
    echo $position
    xrandr --output $screen --auto --pos $position
    feh --randomize --bg-scale ~/Documents/Background/i3_home
done
