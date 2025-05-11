#!/bin/bash
# compare_github_state.sh - Compare GitHub state with JSON file

# Default values
JSON_FILE="project-sync.json"
VERBOSE=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      JSON_FILE="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [OPTIONS]"
      echo
      echo "Compare GitHub state with JSON file."
      echo
      echo "Options:"
      echo "  -f, --file FILE         Path to JSON state file (default: project-sync.json)"
      echo "  -v, --verbose           Show detailed output"
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

# Read repository from JSON
REPO=$(jq -r '.project.githubRepo' "$JSON_FILE")

echo "==== Comparing GitHub State with JSON File ===="
echo "JSON File: $JSON_FILE"
echo "GitHub Repository: $REPO"
echo

# Check epics (as labels or milestones)
echo "Checking epics..."
jq -c '.epics[]' "$JSON_FILE" | while read -r epic; do
  name=$(echo "$epic" | jq -r '.name')
  github_label=$(echo "$epic" | jq -r '.githubLabel')
  
  # Check if label exists
  if [[ -n "$github_label" ]]; then
    if gh label list --repo "$REPO" --json name | jq -e --arg label "$github_label" '.[] | select(.name == $label)' &>/dev/null; then
      echo "✅ Epic label exists: $github_label"
    else
      echo "❌ Epic label missing: $github_label"
    fi
  fi
}

# Check sprints (as labels or milestones)
echo "Checking sprints..."
jq -c '.sprints[]' "$JSON_FILE" | while read -r sprint; do
  name=$(echo "$sprint" | jq -r '.name')
  github_label=$(echo "$sprint" | jq -r '.githubLabel')
  github_milestone_number=$(echo "$sprint" | jq -r '.githubMilestoneNumber')
  
  # Check if label exists
  if [[ -n "$github_label" ]]; then
    if gh label list --repo "$REPO" --json name | jq -e --arg label "$github_label"
# Check sprints (as labels or milestones)
echo "Checking sprints..."
jq -c '.sprints[]' "$JSON_FILE" | while read -r sprint; do
  name=$(echo "$sprint" | jq -r '.name')
  github_label=$(echo "$sprint" | jq -r '.githubLabel')
  github_milestone_number=$(echo "$sprint" | jq -r '.githubMilestoneNumber')
  
  # Check if label exists
  if [[ -n "$github_label" ]]; then
    if gh label list --repo "$REPO" --json name | jq -e --arg label "$github_label" '.[] | select(.name == $label)' &>/dev/null; then
      echo "✅ Sprint label exists: $github_label"
    else
      echo "❌ Sprint label missing: $github_label"
    fi
  fi
  
  # Check if milestone exists
  if [[ -n "$github_milestone_number" && "$github_milestone_number" != "null" ]]; then
    if gh api "repos/$REPO/milestones/$github_milestone_number" &>/dev/null; then
      echo "✅ Sprint milestone exists: #$github_milestone_number"
    else
      echo "❌ Sprint milestone missing: #$github_milestone_number"
    fi
  fi
}

# Check stories (as issues)
echo "Checking stories..."
jq -c '.stories[]' "$JSON_FILE" | while read -r story; do
  id=$(echo "$story" | jq -r '.id')
  key=$(echo "$story" | jq -r '.key')
  summary=$(echo "$story" | jq -r '.summary')
  github_issue_number=$(echo "$story" | jq -r '.githubIssueNumber')
  
  # Skip if no GitHub issue number
  if [[ "$github_issue_number" == "null" || -z "$github_issue_number" || "$github_issue_number" == "0" ]]; then
    echo "⚠️ Story has no GitHub issue: $key - $summary"
    continue
  fi
  
  # Check if issue exists
  if gh issue view "$github_issue_number" --repo "$REPO" &>/dev/null; then
    echo "✅ Issue exists: #$github_issue_number - $summary"
    
    # Compare status if verbose
    if [[ "$VERBOSE" == "true" ]]; then
      # Get status from JSON
      json_status=$(echo "$story" | jq -r '.status')
      
      # Get labels from GitHub
      github_labels=$(gh issue view "$github_issue_number" --repo "$REPO" --json labels | jq -r '.labels[].name')
      github_state=$(gh issue view "$github_issue_number" --repo "$REPO" --json state | jq -r '.state')
      
      # Get expected GitHub status from mappings
      expected_github_state=$(jq -r --arg status "$json_status" '.mappings.status[] | select(.jira == $status) | .github.state' "$JSON_FILE")
      expected_github_labels=$(jq -r --arg status "$json_status" '.mappings.status[] | select(.jira == $status) | .github.labels[]' "$JSON_FILE")
      
      # Compare states
      if [[ "$github_state" == "$expected_github_state" ]]; then
        echo "  ✅ Status matches: $json_status → $github_state"
      else
        echo "  ❌ Status mismatch: Expected $expected_github_state, got $github_state"
      fi
      
      # Check for expected labels
      for label in $expected_github_labels; do
        if echo "$github_labels" | grep -q "$label"; then
          echo "  ✅ Label present: $label"
        else
          echo "  ❌ Label missing: $label"
        fi
      done
    fi
  else
    echo "❌ Issue missing: #$github_issue_number - $summary"
  fi
}

# Check custom labels
echo "Checking custom labels..."
json_labels=$(jq -r '.stories[].labels[]' "$JSON_FILE" | sort | uniq)
for label in $json_labels; do
  if gh label list --repo "$REPO" --json name | jq -e --arg label "$label" '.[] | select(.name == $label)' &>/dev/null; then
    echo "✅ Custom label exists: $label"
  else
    echo "❌ Custom label missing: $label"
  fi
done

echo
echo "==== Comparison Complete ===="