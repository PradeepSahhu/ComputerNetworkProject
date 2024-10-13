#!/bin/bash

# File with DNS names (hosts) to ping
filename="./dnsNames.txt"
# Output CSV file to store ping results
csv_output="ping_results.csv"

# Create/overwrite the CSV file with headers
echo "Host,Server Name,Status,Public IP" > "$csv_output"

# Function to get public IP
get_public_ip() {
    host="$1"
    ip=$(dig +short "$host" | head -n 1)
    echo "$ip"
}

# Continuous pinging
while true; do
    while IFS= read -r line; do
        public_ip=$(get_public_ip "$line")
        
        if ping -c 1 "$line" &> /dev/null; then
            status="Online"
        else
            status="Offline"
        fi
        
        # Write to CSV with quotes for result
        echo "$line,\"$line\",\"$status\",\"$public_ip\"" >> "$csv_output"
    done < "$filename"
    
    echo "Ping results updated in $csv_output"
    
    # Wait for a specified interval before the next ping cycle (e.g., 10 seconds)
    sleep 10
done

