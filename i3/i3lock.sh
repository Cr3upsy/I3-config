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

# Declare an associative array to store screen positions
declare -A screen_positions

# Declare an associative array to store workspaces
declare -A workspace_assignments


# Save the current positions of the screens and workspaces
connected_screens=$(xrandr | grep " connected" | awk '{ print $1 }')

# Run i3-msg command and store the output in a variable
i3_msg_output=$(i3-msg -t get_workspaces)

# Check if jq is available
if command -v jq > /dev/null; then
    # Parse the JSON output and extract 'num' and 'output' values to store workspace location on monitors
    mapfile -t workspace_array < <(echo "$i3_msg_output" | jq -c '.[] | {num: .num, output: .output}')
else
    echo "jq is not installed. Please install jq to run this script."
fi


for screen in $connected_screens; do
    if [ "$screen" != "$primary_screen" ]; then
        # Extract the position from the 'xrandr' output using awk
        position=$(xrandr --query | awk -v screen="$screen" '/\ connected/ && $1 == screen {print $3}' | awk -F'[+x]' '{print $(NF-1)"x"$NF}')
        screen_positions["$screen"]=$position
        xrandr --output $screen --off

    elif [ "$screen" == "$primary_screen" ]; then
        position=$(xrandr --query | awk -v screen="$screen" '/\ connected/ && $1 == screen {print  $4}' | awk -F'[+x]' '{print $(NF-1)"x"$NF}')
        screen_positions["$screen"]=$position

    fi

done

# Create an array to store the keys and values
temp_array=()
for key in "${!screen_positions[@]}"; do
    temp_array+=("$key ${screen_positions[$key]}")
done

# Sort the array by the second column (values)
IFS=$'\n' sorted_array=($(sort -k2n <<<"${temp_array[*]}"))
unset IFS

# Create an array to store the sorted keys
ordered_screens=()
for element in "${sorted_array[@]}"; do
    key=${element%% *}
    ordered_screens+=("$key")
done

# Suspend message display
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

# Resume message display
pkill -u "$USER" -USR2 dunst
i3-msg bar mode dock

# Restore the screen positions ordered by position
for screen in "${ordered_screens[@]}"; do
    position=${screen_positions["$screen"]}
    workspace=${workspace_assignments["$screen"]}
    echo "Setting position for $screen to $position"
    xrandr --output $screen --auto --pos $position
    feh --randomize --bg-scale ~/Documents/Background/i3_home
done


# Loop through the array and print key-value pairs
for workspace in "${workspace_array[@]}"; do
    num=$(jq -r '.num' <<< "$workspace")
    output=$(jq -r '.output' <<< "$workspace")
    echo "Restoring workspace $num, to output: $output"
    i3-msg "[workspace=$num]" move workspace to output $output

done
