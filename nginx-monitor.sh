#!/bin/bash
#
## Nginx health check, auto-restart & logging

LOG=~/bash/nginx-log.txt
timestamp=$(date)

## Nginx status check
status=$(sudo systemctl is-active nginx)

if [ "$status" = "active" ]; then
    echo "$timestamp - Nginx is running." >> "$LOG"
else
    echo "$timestamp - Nginx is not active! Restarting it..." >> "$LOG"
    sudo systemctl restart nginx

    ## Wait and then check again
    sleep 3
    timestamp=$(date)
    new_status=$(sudo systemctl is-active nginx)

    if [ "$new_status" = "active" ]; then
        echo "$timestamp - Nginx has been restarted successfully and is running" >> "$LOG"
    else
        echo "$timestamp - Restart failed! Nginx is still not active.. Manual intervention is required" >> "$LOG"
    fi
fi
