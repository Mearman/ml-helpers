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
		echo "Creating symbolic links for $file"
		# Get the file name from the full path
		file_name=$(basename "$file")

		# Create a symbolic link in each target directory
		for target_dir in "${target_dirs[@]}"; do
			echo "Creating symbolic link in $target_dir"
			if [[ -f "$target_dir/$file_name" ]]; then
				echo "File $target_dir/$file_name already exists"
				# check if file is already symlink
				if [[ -L "$target_dir/$file_name" ]]; then
					echo "File $target_dir/$file_name is a symlink, removing"
					rm "$target_dir/$file_name"
				else
					echo "File $target_dir/$file_name is not a symlink, skipping"
					continue
				fi
			else
				echo "File $target_dir/$file_name does not exist"
			fi
			ln -s "$file" "$target_dir/$file_name"
		done
	else
		echo "$file is not a file, skipping"
	fi
	echo
done

echo "Symbolic links created successfully!"
