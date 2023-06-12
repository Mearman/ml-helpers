#!/bin/bash
set -euo pipefail

# Set default values for environment variables
LINK_SOURCE_DIR="${LINK_SOURCE_DIR:-}"
LINK_TARGET_DIRS=("${LINK_TARGET_DIRS[@]:-}")

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
	-s | --source-dir)
		LINK_SOURCE_DIR="$2"
		shift
		shift
		;;
	-t | --target-dir)
		LINK_TARGET_DIRS+=("$2")
		shift
		shift
		;;
	-f | --force)
		FORCE=true
		shift
		;;
	*)
		echo "Unknown option: $1" >&2
		exit 1
		;;
	esac
done

# Check if source directory is specified
if [[ -z "${LINK_SOURCE_DIR:-}" ]]; then
	echo "Error: source directory not specified" >&2
	exit 1
fi

# Check if target directories are specified
if [[ ${#LINK_TARGET_DIRS[@]} -eq 0 ]]; then
	echo "Error: target directories not specified" >&2
	exit 1
fi

# Create the .env file
echo "# Comment out the source and targets in the .env file" >.env
echo "LINK_SOURCE_DIR=" >>.env
echo "LINK_TARGET_DIRS=(" >>.env
for target_dir in "${LINK_TARGET_DIRS[@]}"; do
	echo "\"$target_dir\"" >>.env
done
echo ")" >>.env

# Create the target directories if they don't exist
for target_dir in "${LINK_TARGET_DIRS[@]}"; do
	mkdir -p "$target_dir" || echo "$target_dir already exists"
done

# Iterate over the files in the source directory
for target_dir in "${LINK_TARGET_DIRS[@]}"; do
	# Make sure the target directory exists
	if [[ ! -d "$target_dir" ]]; then
		echo "Error: $target_dir does not exist" >&2
		continue
	fi
	# Create a symbolic link in each target directory
	for file in "$LINK_SOURCE_DIR"/*; do
		echo
		# Make sure the file exists
		if [[ ! -f "$file" ]]; then
			echo "Error: $file does not exist" >&2
			continue
		fi
		# Get the file name from the full path
		file_name=$(basename "$file")
		echo "File name: $file_name"
		# Check if a symbolic link already exists
		if [[ -L "$target_dir/$file_name" ]]; then
			if [[ "$FORCE" == true ]]; then
				echo "Overwriting symbolic link in $target_dir"
				rm "$target_dir/$file_name"
			else
				echo "Warning: symbolic link already exists in $target_dir" >&2
				ls -lh "$target_dir/$file_name"
				continue
			fi
		fi
		# Check if a file with the same name already exists
		if [[ -e "$target_dir/$file_name" ]]; then
			echo "Error: file with the same name already exists in $target_dir" >&2
			ls -lh "$target_dir/$file_name"
			continue
		fi
		# Create the symbolic link
		echo "Creating symbolic link in $target_dir"
		ln -s "$file" "$target_dir/$file_name"
		echo
	done
	echo
	echo "===================="
done

echo "Symbolic links created successfully!"
