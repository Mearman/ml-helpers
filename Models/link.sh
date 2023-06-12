#!/bin/bash
set -euo pipefail

# Set default values
env_file=".env"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	-s | --source)
		SOURCE_DIR="$2"
		shift 2
		;;
	-t | --target)
		TARGET_DIR+=("$2")
		shift 2
		;;
	-f | --force)
		FORCE=true
		shift
		;;
	-d | --debug)
		DEBUG=true
		shift
		;;
	-e | --env)
		env_file="$2"
		shift 2
		;;
	*)
		echo "Usage: $0 [-s|--source <source_dir>] [-t|--target <target_dir>] [-f|--force] [-d|--debug] [-e|--env <env_file>]" >&2
		exit 1
		;;
	esac
done

# Enable debug mode if the debug flag is set
if [[ "${DEBUG:-false}" == true ]]; then
	set -x
fi

# Create the .env file with default values if it doesn't exist
if [[ ! -f "$env_file" ]]; then
	# echo "creating
	echo "# Comment out the source and targets in the .env file" >"$env_file"
	echo "# SOURCE_DIR=" >>"$env_file"
	echo "# TARGET_DIR=(" >>"$env_file"
	echo "# \"/path/to/target/directory\"" >>"$env_file"
	echo "# )" >>"$env_file"
	echo "# FORCE=false" >>"$env_file"
fi

# Read the .env file and set default values for environment variables
source "$env_file"
SOURCE_DIR="${SOURCE_DIR:-}"
TARGET_DIR=("${TARGET_DIR[@]:-}")
FORCE="${FORCE:-false}"

# exit if the source directory is not set
if [[ -z "$SOURCE_DIR" ]]; then
	echo "Error: source directory not set" >&2
	exit 1
fi

# Resolve the real paths if they are not empty
if [[ -n "$SOURCE_DIR" ]]; then
	SOURCE_DIR="$(realpath "$SOURCE_DIR")"
fi
if [[ ${#TARGET_DIR[@]} -gt 0 ]]; then
	if [[ -n "${TARGET_DIR[*]}" ]]; then
		TARGET_DIR=($(realpath "${TARGET_DIR[@]}"))
	else
		echo "Error: target directory is empty" >&2
		exit 1
	fi
else
	echo "Error: target directory not set" >&2
	exit 1
fi

# Update the .env file with the new values
echo "# Comment out the source and targets in the .env file" >"$env_file.tmp"
if [[ -n "$SOURCE_DIR" ]]; then
	echo "SOURCE_DIR=\"$SOURCE_DIR\"" >>"$env_file.tmp"
else
	echo "# SOURCE_DIR=" >>"$env_file.tmp"
fi
if [[ ${#TARGET_DIR[@]} -gt 0 ]]; then
	echo "TARGET_DIR=(" >>"$env_file.tmp"
	for target_dir in "${TARGET_DIR[@]}"; do
		if [[ -n "$target_dir" ]]; then
			echo "  \"$target_dir\"" >>"$env_file.tmp"
		fi
	done
	echo ")" >>"$env_file.tmp"
else
	echo "# TARGET_DIR=(" >>"$env_file.tmp"
	echo "# \"/path/to/target/directory\"" >>"$env_file.tmp"
	echo "# )" >>"$env_file.tmp"
fi
if [[ -n "$FORCE" ]]; then
	echo "FORCE=$FORCE" >>"$env_file.tmp"
else
	echo "# FORCE=false" >>"$env_file.tmp"
fi
mv "$env_file.tmp" "$env_file"

# exit if the source directory is not set
if [[ -z "$SOURCE_DIR" ]]; then
	echo "Error: source directory not set" >&2
	exit 1
fi
# exit if the target directories are not set or empty
if [[ ${#TARGET_DIR[@]} -eq 0 ]]; then
	echo "Error: target directories not set" >&2
	exit 1
fi
# Create the target directories if they don't exist
for target_dir in "${TARGET_DIR[@]}"; do
	mkdir -p "$target_dir" || echo "$target_dir already exists"
done

# Iterate over the files in the source directory
for target_dir in "${TARGET_DIR[@]}"; do
	# Make sure the target directory exists
	if [[ ! -d "$target_dir" ]]; then
		echo "Error: $target_dir does not exist" >&2
		continue
	fi
	# Create a symbolic link in each target directory
	for file in "$SOURCE_DIR"/*; do
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
