#!/bin/bash
set -euo pipefail

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	-s | --source)
		LINK_SOURCE_DIR="$2"
		shift 2
		;;
	-t | --target)
		LINK_TARGET_DIRS+=("$2")
		shift 2
		;;
	-f | --force)
		FORCE=true
		shift
		;;
	*)
		echo "Usage: $0 [-s|--source <source_dir>] [-t|--target <target_dir>] [-f|--force]" >&2
		exit 1
		;;
	esac
done

# Create the .env file with default values if it doesn't exist
if [[ ! -f .env ]]; then
	echo "# Comment out the source and targets in the .env file" >.env
	echo "LINK_SOURCE_DIR=" >>.env
	echo "LINK_TARGET_DIRS=(" >>.env
	echo "# \"/path/to/target/directory\"" >>.env
	echo ")" >>.env
	echo "FORCE=false" >>.env
fi

# Read the .env file and set default values for environment variables
source .env
LINK_SOURCE_DIR="${LINK_SOURCE_DIR:-}"
LINK_TARGET_DIRS=("${LINK_TARGET_DIRS[@]:-}")
FORCE="${FORCE:-false}"

# Update the .env file with the new values
echo "LINK_SOURCE_DIR=\"$LINK_SOURCE_DIR\"" >.env.tmp
echo "LINK_TARGET_DIRS=(" >>.env.tmp
for target_dir in "${LINK_TARGET_DIRS[@]}"; do
	echo "  \"$target_dir\"" >>.env.tmp
done
echo ")" >>.env.tmp
echo "FORCE=$FORCE" >>.env.tmp
mv .env.tmp .env

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
