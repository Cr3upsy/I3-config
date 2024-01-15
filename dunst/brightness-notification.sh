#!/bin/bash

# Path to icons, edit path if you want to change icons used
Brightness_icon_medium="/snap/gtk-common-themes/1535/share/icons/elementary-xfce/notifications/48/notification-display-brightness-medium.png"
Brightness_icon_low="/snap/gtk-common-themes/1535/share/icons/elementary-xfce/notifications/48/notification-display-brightness-low.png"
Brightness_icon_high="/snap/gtk-common-themes/1535/share/icons/elementary-xfce/notifications/48/notification-display-brightness-high.png"


icon="$Brightness_icon_medium"

# Modify icon used, depends of the brightness level
check_brightness() {
    local value=$(echo "$1" | tr -cd '0-9')
    icon=""

    if ((value < 40)); then
    	icon="$Brightness_icon_low"
    elif ((value >= 40 && value <= 70)); then
    	icon="$Brightness_icon_medium"
    else
    	icon="$Brightness_icon_high"
    fi
    echo "$icon"
}


if [ "$1" == "Up" ]; then
    #Increase brightness level
    brightnessctl set +10
    
elif [ "$1" == "Down" ]; then
    #Decrease brighness level
    brightnessctl set 10-    
    
else
    echo "Invalid argument. Usage: $0 [Up|Down]"
    exit 1
fi

# Get the current brightness level
brightness=$(brightnessctl i | grep "Current brightness:" -m 1 | awk -F '[(%]' '{print $2}')
icon=$(check_brightness "$brightness")
notification="Brightness: $brightness"

# Send the notification to Dunst
dunstify -t 2000 -r 9910 -u normal "$notification%" -i "$icon"
