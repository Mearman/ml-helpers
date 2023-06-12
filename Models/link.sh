#!/bin/bash
set -euo pipefail

source_dir="./Models"
target_dirs=(
	"../pautobot-data/models"
	"../LocalAI/models"
)

# Create the target directories if they don't exist
for target_dir in "${target_dirs[@]}"; do
	mkdir -p "$target_dir" || echo "$target_dir already exists"
done

# Iterate over the files in the source directory
for file in "$source_dir"/*; do
	echo "Processing $file"
	if [[ -f "$file" ]]; then
		# Get the file name from the full path
		file_name=$(basename "$file")
		# Create a symbolic link in each target directory
		for target_dir in "${target_dirs[@]}"; do
			echo "Creating symbolic link in $target_dir"

			ln -s "$file" "$target_dir/$file_name"
		done
	fi
	echo
done

echo "Symbolic links created successfully!"
