#!/bin/bash
set -e

MODEL_URLS=(
	"https://huggingface.co/nomic-ai/ggml-replit-code-v1-3b/resolve/main/ggml-replit-code-v1-3b.bin"
	"https://huggingface.co/eachadea/ggml-nous-hermes-13b/resolve/main/ggml-v3-13b-hermes-q5_1.bin"
	"https://gpt4all.io/models/ggml-gpt4all-l13b-snoozy.bin"
	"https://gpt4all.io/models/ggml-gpt4all-j-v1.1-breezy.bin"
	"https://gpt4all.io/models/ggml-gpt4all-j-v1.2-jazzy.bin"
	"https://gpt4all.io/models/ggml-gpt4all-j-v1.3-groovy.bin"
	"https://gpt4all.io/models/ggml-gpt4all-j.bin"
	"https://gpt4all.io/models/ggml-mpt-7b-base.bin"
	"https://gpt4all.io/models/ggml-mpt-7b-instruct.bin"
	"https://gpt4all.io/models/ggml-nous-gpt4-vicuna-13b.bin"
	"https://gpt4all.io/models/ggml-stable-vicuna-13B.q4_2.bin"
	"https://gpt4all.io/models/ggml-vicuna-13b-1.1-q4_2.bin"
	"https://gpt4all.io/models/ggml-vicuna-7b-1.1-q4_2.bin"
	"https://gpt4all.io/models/ggml-wizard-13b-uncensored.bin"
	"https://gpt4all.io/models/ggml-wizardLM-7B.q4_2.bin"
)

dead_links=()

max_length=0
for url in "${MODEL_URLS[@]}"; do
	if [ ${#url} -gt $max_length ]; then
		max_length=${#url}
	fi
done

c1_len=$max_length
c2_len=10
c3_len=10

printf "%-${c1_len}s %-${c2_len}s %-${c3_len}s\n" "URL" "Status" "Size"
# print header underline
printf "%-${c1_len}s %-${c2_len}s %-${c3_len}s\n" "$(printf '%*s' "$c1_len" | tr ' ' '=')" "$(printf '%*s' "$c2_len" | tr ' ' '=')" "$(printf '%*s' "$c3_len" | tr ' ' '=')"

for url in "${MODEL_URLS[@]}"; do
	# use -L option to follow redirects
	if curl -L --output /dev/null --silent --head --fail "$url"; then
		# use -L option to follow redirects
		size_bytes=$(curl -LsI "$url" | grep -i Content-Length | awk '{print $2}' | tr -d '\r' | tail -n1)
		size_human=$(numfmt --to=iec --suffix=B --format="%.2f" "$size_bytes")
		printf "%-${c1_len}s %-${c2_len}s %-${c3_len}s\n" "$url" "Live" "$size_human"
	else
		printf "%-${c1_len}s %-${c2_len}s %-${c3_len}s\n" "$url" "-" "-"
		dead_links+=("$url")
	fi
done

echo
if [ ${#dead_links[@]} -gt 0 ]; then
	echo "Dead links:"
	for link in "${dead_links[@]}"; do
		echo "$link"
	done
fi
