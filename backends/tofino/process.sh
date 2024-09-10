#!/bin/bash

# Check if a filename is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

filename="$1"

# Check if the file exists
if [ ! -f "$filename" ]; then
    echo "Error: File '$filename' not found."
    exit 1
fi

# Perform the replacement
sed -i 's/bf-p4c\//backends\/tofino\//g' "$filename"

echo "Replacement complete in $filename"

