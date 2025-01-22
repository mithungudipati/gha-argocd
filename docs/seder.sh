#!/bin/bash

# Extract URLs from the yarn.lock file that are resolved to a local Artifactory cache
urls=$(grep "resolved" yarn.lock | grep "your.artifactory.domain" | awk '{print $2}' | tr -d '"')

# Directory to store the downloads
mkdir -p downloads
cd downloads

# File to store the list of failed dependencies
failed_dependencies="failed_downloads.txt"
> $failed_dependencies  # Clear the file if it exists

# Function to check each URL
check_url() {
    url=$1
    echo "Trying to download $url..."
    curl -O -f -s $url
    if [ $? -ne 0 ]; then
        echo "$url" >> "../$failed_dependencies"
    fi
}

# Export function to use in xargs
export -f check_url

# Download each file and check for failures
echo "$urls" | xargs -n1 -P10 -I{} bash -c 'check_url "{}"'

# Check if there were any failures
if [ -s $failed_dependencies ]; then
    echo "Failed dependencies:"
    cat "../$failed_dependencies"
else
    echo "All dependencies downloaded successfully."
fi

cd ..
