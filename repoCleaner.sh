#!/bin/bash

GITHUB_TOKEN="your token"

# Define the time window (1 year in seconds)
TIME_WINDOW=$((365 * 24 * 60 * 60))

# Input file containing repositories
REPO_FILE="masterRepoList.txt"

# Log file for progress tracking
LOG_FILE="repoCleaner.log"

# Check if required tools are installed
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "Error: 'jq' and 'curl' are required. Install them and rerun the script."
    exit 1
fi

# Function to fetch stale branches
get_stale_branches() {
    local repo=$1
    local owner=$(echo "$repo" | cut -d'/' -f4)
    local repo_name=$(echo "$repo" | cut -d'/' -f5)
    local stale_branches=()

    echo "Fetching branches for $repo_name..."
    branches=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$owner/$repo_name/branches" | jq -r '.[] | .name')

    for branch in $branches; do
        last_commit_date=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$owner/$repo_name/branches/$branch" | jq -r '.commit.commit.author.date')

        last_commit_timestamp=$(date -d "$last_commit_date" +%s)
        current_timestamp=$(date +%s)
        age=$((current_timestamp - last_commit_timestamp))

        if (( age > TIME_WINDOW )); then
            stale_branches+=("$branch")
        fi
    done

    echo "${stale_branches[@]}"
}

# Function to delete selected branches
delete_branches() {
    local repo=$1
    local owner=$(echo "$repo" | cut -d'/' -f4)
    local repo_name=$(echo "$repo" | cut -d'/' -f5)
    local branches_to_delete=("${@:2}")

    for branch in "${branches_to_delete[@]}"; do
        echo "Deleting branch: $branch from $repo_name..."
        curl -X DELETE -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$owner/$repo_name/git/refs/heads/$branch"
        
        echo "$branch deleted from $repo_name" >> $LOG_FILE
    done
}

# Process each repository
while IFS= read -r repo; do
    echo "Processing repository: $repo"
    
    stale_branches=($(get_stale_branches "$repo"))
    
    if [[ ${#stale_branches[@]} -eq 0 ]]; then
        echo "No stale branches found for $repo"
        continue
    fi

    echo "Stale branches in $repo:"
    for i in "${!stale_branches[@]}"; do
        echo "$((i+1)). ${stale_branches[$i]}"
    done

    echo "Select branches to delete (comma-separated numbers or 'all' to delete all, 'none' to skip):"
    read -r choice

    if [[ "$choice" == "none" ]]; then
        echo "Skipping deletion for $repo"
        continue
    fi

    selected_branches=()
    if [[ "$choice" == "all" ]]; then
        selected_branches=("${stale_branches[@]}")
    else
        IFS=',' read -ra indices <<< "$choice"
        for index in "${indices[@]}"; do
            if [[ "$index" =~ ^[0-9]+$ ]] && (( index > 0 && index <= ${#stale_branches[@]} )); then
                selected_branches+=("${stale_branches[$((index-1))]}")
            fi
        done
    fi

    if [[ ${#selected_branches[@]} -gt 0 ]]; then
        delete_branches "$repo" "${selected_branches[@]}"
    fi

done < "$REPO_FILE"

echo "Cleanup completed. Check $LOG_FILE for details."
