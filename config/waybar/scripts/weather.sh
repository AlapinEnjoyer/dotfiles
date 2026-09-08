#!/usr/bin/env bash

for i in {1..5}; do
    text=$(curl -s "https://wttr.in/?format=1" 2>/dev/null)
    if [[ $? == 0 && -n "$text" && "$text" != *"Unknown"* ]]; then
        text=$(echo "$text" | sed -E "s/\s+/ /g" | xargs)
        
        tooltip=$(curl -s "https://wttr.in/?format=4" 2>/dev/null)
        if [[ $? == 0 && -n "$tooltip" ]]; then
            tooltip=$(echo "$tooltip" | sed -E "s/\s+/ /g" | xargs)
            echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
            exit 0
        fi
    fi
    sleep 2
done

echo "{\"text\":\" --\", \"tooltip\":\"Weather unavailable\"}"
