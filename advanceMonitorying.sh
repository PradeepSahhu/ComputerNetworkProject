#!/bin/bash

# File with DNS names (hosts) to ping
filename="./dnsNames.txt"
# Output CSV file to store ping results
csv_output="ping_results.csv"

# Create/overwrite the CSV file with headers
echo "Host,Server Name,Status,Public IP,Response Time (ms),Country,Region,Latitude,Longitude" > "$csv_output"

# Function to get public IP
get_public_ip() {
    host="$1"
    ip=$(dig +short "$host" | head -n 1)
    echo "$ip"
}

# Function to get geolocation (latitude, longitude, country, region)
get_geolocation() {
    ip="$1"
    if [[ -n "$ip" ]]; then
        # Use ipinfo.io to fetch geolocation data in JSON format
        response=$(curl -s "https://ipinfo.io/$ip/geo")
        
        # Extract latitude, longitude, country, and region from the response
        lat=$(echo "$response" | grep '"loc"' | cut -d '"' -f 4 | cut -d ',' -f 1)
        lon=$(echo "$response" | grep '"loc"' | cut -d '"' -f 4 | cut -d ',' -f 2)
        country=$(echo "$response" | grep '"country"' | cut -d '"' -f 4)
        region=$(echo "$response" | grep '"region"' | cut -d '"' -f 4)
        
        # Return the geolocation data
        echo "$country,$region,$lat,$lon"
    else
        # Return default values if IP is not available
        echo "N/A,N/A,N/A,N/A"
    fi
}

# Continuous pinging
while true; do
    # Recreate/overwrite the CSV file with headers at the beginning of each cycle
    echo "Host,Server Name,Status,Public IP,Response Time (ms),Country,Region,Latitude,Longitude" > "$csv_output"

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

        # Get geolocation data (country, region, latitude, longitude)
        geolocation=$(get_geolocation "$public_ip")
        country=$(echo "$geolocation" | cut -d ',' -f 1)
        region=$(echo "$geolocation" | cut -d ',' -f 2)
        latitude=$(echo "$geolocation" | cut -d ',' -f 3)
        longitude=$(echo "$geolocation" | cut -d ',' -f 4)

        # Log the status and response time for debugging
        echo "Status: $status, Response Time: $response_time, Country: $country, Region: $region, Latitude: $latitude, Longitude: $longitude"

        # Write to CSV with quotes for result
        echo "$line,\"$line\",\"$status\",\"$public_ip\",\"$response_time\",\"$country\",\"$region\",\"$latitude\",\"$longitude\"" >> "$csv_output"
    done < "$filename"

    echo "Ping results updated in $csv_output"

    # Wait for a specified interval before the next ping cycle (e.g., 10 seconds)
    sleep 10
done

