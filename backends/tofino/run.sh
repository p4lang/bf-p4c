#!/bin/bash

find . -type f \( -name "*.def" -o -name "*.def" \) | while read -r file; do
	echo "processing $file"
	./process.sh "$file"
done

echo "All files processed"
