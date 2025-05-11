#!/bin/bash
# sync_jira_github.sh - Synchronize Jira and GitHub based on JSON state file

# Default values
JSON_FILE="project-sync.json"
DIRECTION="bidirectional" # jira-to-github, github-to-jira, bidirectional
DRY_RUN=false
CONFLICT_RESOLUTION="ask" # jira-wins, github-wins, ask

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      JSON_FILE="$2"
      shift 2
      ;;
    -d|--direction)
      DIRECTION="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -c|--conflict)
      CONFLICT_RESOLUTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [OPTIONS]"
      echo
      echo "Synchronize Jira and GitHub based on JSON state file."
      echo
      echo "Options:"
      echo "  -f, --file FILE         Path to JSON state file (default: project-sync.json)"
      echo "  -d, --direction DIR     Sync direction: jira-to-github, github-to-jira, bidirectional (default)"
      echo "  --dry-run               Show what would be done without making changes"
      echo "  -c, --conflict MODE     Conflict resolution: jira-wins, github-wins, ask (default)"
      echo "  -h, --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'"
      exit 1
      ;;
  esac
done

# Check if JSON file exists
if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: JSON file not found: $JSON_FILE"
  exit 1
fi

# Read project info from JSON
REPO=$(jq -r '.project.githubRepo' "$JSON_FILE")
JIRA_PROJECT=$(jq -r '.project.key' "$JSON_FILE")

echo "==== Synchronizing Jira and GitHub ===="
echo "JSON File: $JSON_FILE"
echo "Jira Project: $JIRA_PROJECT"
echo "GitHub Repository: $REPO"
echo "Direction: $DIRECTION"
echo "Conflict Resolution: $CONFLICT_RESOLUTION"
echo "Dry Run: $DRY_RUN"
echo

# Function to sync a story from Jira to GitHub
sync_story_jira_to_github() {
  local story_id="$1"
  local story=$(jq -r --arg id "$story_id" '.stories[] | select(.id == $id)' "$JSON_FILE")
  local key=$(echo "$story" | jq -r '.key')
  local github_issue_number=$(echo "$story" | jq -r '.githubIssueNumber')
  
  echo "Syncing Jira story $key to GitHub issue #$github_issue_number"
  
  # Get the latest from Jira
  # (In a real implementation, you would call the Jira API here)
  
  # Update in GitHub
  if [[ "$github_issue_number" -gt 0 ]]; then
    # Update existing issue
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY RUN] Would update GitHub issue #$github_issue_number"
    else
      # Make actual GitHub API calls here
      echo "  Updating GitHub issue #$github_issue_number"
    fi
  else
    # Create new issue
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY RUN] Would create new GitHub issue for $key"
    else
      # Make actual GitHub API calls here
      echo "  Creating new GitHub issue for $key"
    fi
  fi
}

# Function to sync a story from GitHub to Jira
sync_story_github_to_jira() {
  local story_id="$1"
  local story=$(jq -r --arg id "$story_id" '.stories[] | select(.id == $id)' "$JSON_FILE")
  local key=$(echo "$story" | jq -r '.key')
  local github_issue_number=$(echo "$story" | jq -r '.githubIssueNumber')
  
  echo "Syncing GitHub issue #$github_issue_number to Jira story $key"
  
  # Get the latest from GitHub
  # (In a real implementation, you would call the GitHub API here)
  
  # Update in Jira
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would update Jira issue $key"
  else
    # Make actual Jira API calls here
    echo "  Updating Jira issue $key"
  fi
}

# Process all stories
jq -c '.stories[]' "$JSON_FILE" | while read -r story; do
  story_id=$(echo "$story" | jq -r '.id')
  key=$(echo "$story" | jq -r '.key')
  github_issue_number=$(echo "$story" | jq -r '.githubIssueNumber')
  
  # Check direction and sync accordingly
  if [[ "$DIRECTION" == "jira-to-github" || "$DIRECTION" == "bidirectional" ]]; then
    sync_story_jira_to_github "$story_id"
  fi
  
  if [[ "$DIRECTION" == "github-to-jira" || "$DIRECTION" == "bidirectional" ]]; then
    sync_story_github_to_jira "$story_id"
  fi
  
  # Update the JSON file with the latest state
  # (In a real implementation, you'd update the JSON with the new state)
  echo "  Updating JSON state file for $key"
done

echo
echo "==== Synchronization Complete ===="