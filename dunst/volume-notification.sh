#!/bin/bash

# Path to icons, edit path if you want to change icons used
Volume_icon_medium="/snap/gtk-common-themes/1535/share/icons/elementary-xfce/notifications/48/audio-volume-medium.png"
Volume_icon_low="/snap/gtk-common-themes/1535/share/icons/elementary-xfce/notifications/48/audio-volume-low.png"
Volume_icon_high="/snap/gtk-common-themes/1535/share/icons/elementary-xfce/notifications/48/audio-volume-high.png"
AudioMute_icon="/usr/share/icons/custom/diminuer-le-volume.png"
MicMute_icon="/usr/share/icons/custom/muet.png"

icon="$Volume_icon"

# Modify icon used, dedends of the volume level
check_volume() {
    local value=$(echo "$1" | tr -cd '0-9')
    icon=""

    if ((value < 40)); then
    	icon="$Volume_icon_low"
    elif ((value >= 40 && value <= 70)); then
    	icon="$Volume_icon_medium"
    else
    	icon="$Volume_icon_high"
    fi
    echo "$icon"
}


if [ "$1" == "Up" ]; then
    #Increase audio level
    pactl set-sink-volume @DEFAULT_SINK@ +10%
    
    # Get the current volume level
    volume=$(pactl list sinks | grep "Volume:" -m 1 | awk '{print $5}')
    # Create the notification message
    notification="Volume: $volume"
    icon=$(check_volume "$volume")
    
elif [ "$1" == "Down" ]; then
    #Decrease audio level
    pactl set-sink-volume @DEFAULT_SINK@ -10%
    
    # Get the current volume level
    volume=$(pactl list sinks | grep "Volume:" -m 1 | awk '{print $5}')
    # Create the notification message
    notification="Volume: $volume"
    icon=$(check_volume "$volume")
    echo "$icon"
    
elif [ "$1" == "AudioMute" ]; then
    # Mute / unmute audio
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    mute=$(pactl list sinks | awk '/Mute/ { lastMatch=$2 } END { print lastMatch }')
    
    if [ "$mute" == "yes" ]; then
        notification="Volume is muted"
        icon="$AudioMute_icon"
    else
        notification="Volume is active"
    fi

elif [ "$1" == "MicMute" ]; then
    # Mute / unmute mic
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
    mute=$(pactl list sources | awk '/Mute/ { lastMatch=$2 } END { print lastMatch }')
    
    if [ "$mute" == "yes" ]; then
        notification="Mic is muted"
        icon="$MicMute_icon"
    else
        notification="Micro is active"
    fi

else
    echo "Invalid argument. Usage: $0 [Up|Down|MicMute|AudioMute]"
    exit 1
fi


# Send the notification to Dunst
dunstify -t 2000 -r 9910 -u normal "$notification" -i "$icon"
