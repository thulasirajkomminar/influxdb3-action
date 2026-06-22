#!/bin/sh -e

# Download and run InfluxDB 3
echo "Downloading and running InfluxDB 3..."
docker pull quay.io/influxdb/influxdb3-core:latest
docker tag quay.io/influxdb/influxdb3-core:latest influxdb3-core
docker run -d --name influxdb3 -p 8181:8181 influxdb3-core serve --node-id=node0 --object-store memory > /dev/null

# Extract an apiv3_ token from the CLI output. Matching the token pattern
# directly is robust against ANSI colour codes and output-format changes.
extract_token() {
    grep -oE 'apiv3_[A-Za-z0-9_=+/-]+' | head -n1
}

# Create the admin token, retrying until the server is ready to serve it.
# State.Running flips to true almost immediately, well before the API and
# token subsystem are accepting requests, so the previous Running check
# raced ahead and left ADMIN_TOKEN empty in CI.
echo "Creating admin token..."
ADMIN_TOKEN=""
for i in $(seq 1 60); do
    ADMIN_TOKEN=$(docker exec influxdb3 influxdb3 create token --admin 2>/dev/null | extract_token || true)
    if [ -n "$ADMIN_TOKEN" ]; then
        break
    fi
    sleep 1
done

if [ -z "$ADMIN_TOKEN" ]; then
    echo "Failed to create admin token" >&2
    docker logs influxdb3 >&2 || true
    exit 1
fi
echo "InfluxDB 3 is up and running"
echo "Admin token created successfully."

# Create the database
echo "Creating database: $INFLUXDB3_DATABASE"
docker exec influxdb3 influxdb3 create database --token "$ADMIN_TOKEN" "$INFLUXDB3_DATABASE"
echo "Database $INFLUXDB3_DATABASE created."

if [ "$INFLUXDB3_CREATE_TOKEN" = "true" ]
then
    echo "Creating token..."
    INFLUXDB3_TOKEN=$(docker exec influxdb3 influxdb3 create token --admin --token "$ADMIN_TOKEN" --name influxdb3-token | extract_token)
    if [ -z "$INFLUXDB3_TOKEN" ]; then
        echo "Failed to create token" >&2
        exit 1
    fi
    echo "Token created successfully. This will grant you access to every HTTP endpoint or deny it otherwise."

    # Export the token to GITHUB_OUTPUT
    echo "influxdb3-auth-token=$INFLUXDB3_TOKEN" >> "$GITHUB_OUTPUT"
fi
