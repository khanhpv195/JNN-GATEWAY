#!/bin/bash

LOG_FILE="memory_usage.log"
ALERT_THRESHOLD=80

while true; do
    echo "=== $(date) ===" >> $LOG_FILE
    
    # Log tổng quan
    free -h >> $LOG_FILE
    
    # Log từng service
    docker stats --no-stream >> $LOG_FILE
    
    # Check usage của từng service
    for SERVICE in mongodb redis moon user iam lead property maintenance; do
        USAGE=$(docker stats --no-stream --format "{{.MemPerc}}" crm_$SERVICE)
        if [[ ${USAGE%.*} -gt $ALERT_THRESHOLD ]]; then
            echo "WARNING: $SERVICE memory usage > $ALERT_THRESHOLD%" >> $LOG_FILE
        fi
    done
    
    echo "-------------------" >> $LOG_FILE
    sleep 300  # Check mỗi 5 phút
done 