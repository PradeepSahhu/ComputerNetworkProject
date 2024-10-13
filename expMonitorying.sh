#!/bin/bash

# File with DNS names (hosts) to ping
filename="./dnsNames.txt"
# Output CSV file to store ping results
csv_output="ping_results.csv"

# Create/overwrite the CSV file with headers
echo "Host,Server Name,Status,Public IP,Response Time (ms)" > "$csv_output"

# Function to get public IP
get_public_ip() {
    host="$1"
    ip=$(dig +short "$host" | head -n 1)
    echo "$ip"
}

# Continuous pinging
while true; do
    # Recreate/overwrite the CSV file with headers at the beginning of each cycle
    echo "Host,Server Name,Status,Public IP,Response Time (ms)" > "$csv_output"

    while IFS= read -r line; do
        public_ip=$(get_public_ip "$line")

        # Check if the ping was successful and extract response time
        if ping -c 1 "$line" &> /dev/null; then
            status="Online"
            # Extract the response time in milliseconds
            response_time=$(ping -c 1 "$line" | awk -F'time=' '{print $2}' | cut -d ' ' -f 1)
        else
            status="Offline"
            response_time="N/A"
        fi

        # Log the status and response time for debugging
        echo "Status: $status, Response Time: $response_time"

        # Write to CSV with quotes for result
        echo "$line,\"$line\",\"$status\",\"$public_ip\",\"$response_time\"" >> "$csv_output"
    done < "$filename"

    echo "Ping results updated in $csv_output"

    # Wait for a specified interval before the next ping cycle (e.g., 10 seconds)
    sleep 10
done

