#!/bin/sh

# Simple test to check if a gif has a strobe effect.
# 2019-12-17 Joshua I. James @DFIRScience
# https://DFIR.Science

if [ -f "$1" ]; then
    echo "Checking file $1"
else
    echo "Please give the path to a valid file."
fi

# Check for imagemagic identify tool
IMGID=$(which identify)
if [ $IMGID ]; then
    echo "Identify command found at $IMGID"
else
    echo "Please install imagemagick to continue..."
    exit 255
fi

# Check the strobe counter
# Exit if greater >= 2
checkStrobeC () {
    strobeC=$1
    echo "check strobe : $1"
    if [ $strobeC -eq 2 ]; then
        echo "The image seems to have some strobe effect..."
        exit 1
    fi
}

# Check for stobe effect using transparency values
checkTransparencyStrobe () {
    strobeC=0 # If this is over 2, classify as strobe
    R=0
    G=0
    B=0
    # Get each line and check differences between grames
    for line in $(identify -verbose $1 | grep srgba | grep Trans | awk '{print $3}' | sed s/srgba\(//g | sed s/\)//g); do
        R2=$(echo $line | awk -F"," '{print $1}')
        G2=$(echo $line | awk -F"," '{print $2}')
        B2=$(echo $line | awk -F"," '{print $3}')
        echo "Prior:   Red: $R  Green: $G  Blue: $B"
        echo "Current: Red: $R2  Green: $G2  Blue: $B2"
        # Compare the last frame. We are looking for an inverse of R&B.
        # 150 was selected since it is a big difference, but not max (255)
        # The first check is if R increased a lot and B decreased a lot.
        # The second check is if R decreased a lot and B increased a lot.
        # Each major change is flagged as 1 strobe - strobeC
        if [ $R2 -gt $(($R + 150)) ] && [ $B2 -lt $(($B - 150)) ]; then
            echo "Increase in red detected..."
            strobeC=$((strobeC+1))
            checkStrobeC $strobeC
        elif [ $R2 -lt $(($R - 150)) ] && [ $B2 -gt $(($B + 150)) ]; then
            echo "Increase in blue detected..."
            strobeC=$((strobeC+1))
            checkStrobeC $strobeC
        fi
        # Set the colors for the next round of checks.
        R=$R2
        G=$G2
        B=$B2
    done
}


### Main
checkTransparencyStrobe $1

# If we made it this far, the image looks clean
echo "No strobe detected..."
exit 0

