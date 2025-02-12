## repoCleaner - GitHub Repository & Branch Cleanup Utility

## Overview

repoCleaner is a shell script that automates the cleanup of stale branches in GitHub repositories based on a predefined time window. It provides an interactive way for users to review and delete branches that haven't been updated in over a year.

## Features

Reads a list of repositories from masterRepoList.txt.

Identifies branches with last commits older than 1 year.

Allows users to selectively delete stale branches.

Ensures users cannot delete non-stale branches.

Provides an executive summary of deleted branches and recommendations for repository cleanup.

Handles network failures and can resume from the last checkpoint.

## Prerequisites

Ensure the following dependencies are installed:

curl (for API requests)

jq (for JSON parsing)

git (for repository operations)

GitHub Personal Access Token

Running repoCleaner

## Make the script executable:

chmod +x repoCleaner.sh

## Run the script: 

./repoCleaner.sh
