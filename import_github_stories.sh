#!/bin/bash
# Import stories from JSON to GitHub Issues using GitHub CLI

# Default values
JSON_FILE="documentation/user_stories/user-stories-json-template.json"
REPO=""
EPIC_LABEL_COLOR="0366d6"
SPRINT_LABEL_COLOR="5319e7"
CUSTOM_LABEL_COLOR="fbca04"  # Yellow for custom labels
DRY_RUN=false

# Print usage information
print_usage() {
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo
  echo "Import user stories from a JSON file to GitHub Issues."
  echo
  echo "Options:"
  echo "  -f, --file FILE       Path to JSON file with stories (default: $JSON_FILE)"
  echo "  -r, --repo REPO       GitHub repository in format 'username/repo'"
  echo "  --epic-color COLOR    Color for epic labels (default: $EPIC_LABEL_COLOR)"
  echo "  --sprint-color COLOR  Color for sprint labels (default: $SPRINT_LABEL_COLOR)"
  echo "  --custom-color COLOR  Color for custom labels (default: $CUSTOM_LABEL_COLOR)"
  echo "  --dry-run             Show what would be done without actually creating issues"
  echo "  -h, --help            Show this help message"
  echo
  echo "Requirements:"
  echo "  - GitHub CLI (gh) installed and authenticated"
  echo "  - jq installed for JSON processing"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      JSON_FILE="$2"
      shift 2
      ;;
    -r|--repo)
      REPO="$2"
      shift 2
      ;;
    --epic-color)
      EPIC_LABEL_COLOR="$2"
      shift 2
      ;;
    --sprint-color)
      SPRINT_LABEL_COLOR="$2"
      shift 2
      ;;
    --custom-color)
      CUSTOM_LABEL_COLOR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'"
      print_usage
      exit 1
      ;;
  esac
done

# Validate dependencies
if ! command -v gh &> /dev/null; then
  echo "Error: GitHub CLI (gh) is required but not installed."
  echo "Please install it: https://cli.github.com/manual/installation"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  echo "Please install it: https://stedolan.github.io/jq/download/"
  exit 1
fi

# Check if GitHub CLI is authenticated
if ! gh auth status &> /dev/null; then
  echo "Error: GitHub CLI is not authenticated."
  echo "Please run 'gh auth login' first."
  exit 1
fi

# Check if JSON file exists
if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: JSON file not found: $JSON_FILE"
  exit 1
fi

# If repo not specified, try to get it from current git config
if [[ -z "$REPO" ]]; then
  if git remote -v &>/dev/null; then
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [[ $remote_url =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
      REPO="${BASH_REMATCH[1]}"
      # Remove .git suffix if present
      REPO="${REPO%.git}"
      echo "Using repository from git config: $REPO"
    fi
  fi
  
  # If still empty, prompt user
  if [[ -z "$REPO" ]]; then
    echo "Error: Repository not specified."
    echo "Please provide a repository with --repo username/repo"
    exit 1
  fi
fi

# Validate repository format
if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
  echo "Error: Invalid repository format: $REPO"
  echo "Please use the format: username/repo"
  exit 1
fi

# Validate repository existence
if ! gh repo view "$REPO" &>/dev/null; then
  echo "Error: Repository not found or no access: $REPO"
  exit 1
fi

# Print configuration
echo "Configuration:"
echo "  JSON File: $JSON_FILE"
echo "  Repository: $REPO"
echo "  Epic Label Color: $EPIC_LABEL_COLOR"
echo "  Sprint Label Color: $SPRINT_LABEL_COLOR"
echo "  Custom Label Color: $CUSTOM_LABEL_COLOR"
echo "  Dry Run: $DRY_RUN"
echo

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Running in dry-run mode. No changes will be made."
  EXECUTE="echo '  [DRY RUN]'"
else
  EXECUTE=""
fi

# Extract and create all custom labels first
echo "Extracting custom labels from stories..."
custom_labels=$(jq -r '.stories[].labels[]' "$JSON_FILE" | sort | uniq)

echo "Creating custom labels..."
for label in $custom_labels; do
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY RUN] Would create custom label: $label (color: $CUSTOM_LABEL_COLOR)"
    else
      gh label create "$label" --color "$CUSTOM_LABEL_COLOR" --repo "$REPO" 2>/dev/null || \
      gh label edit "$label" --color "$CUSTOM_LABEL_COLOR" --repo "$REPO" 2>/dev/null
      echo "  Created/updated custom label: $label"
    fi
done

# Create epic labels
echo "Creating epic labels..."
jq -c '.epics[]' "$JSON_FILE" | while read -r epic; do
    name=$(echo "$epic" | jq -r '.name')
    summary=$(echo "$epic" | jq -r '.summary')
    
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY RUN] Would create/update epic label: $name (description: $summary, color: $EPIC_LABEL_COLOR)"
    else
      gh label create "$name" --description "$summary" --color "$EPIC_LABEL_COLOR" --repo "$REPO" 2>/dev/null || \
      gh label edit "$name" --description "$summary" --color "$EPIC_LABEL_COLOR" --repo "$REPO" 2>/dev/null
      echo "  Created/updated epic label: $name"
    fi
done

# Create sprint labels
echo "Creating sprint labels..."
jq -c '.sprints[]' "$JSON_FILE" | while read -r sprint; do
    name=$(echo "$sprint" | jq -r '.name')
    goal=$(echo "$sprint" | jq -r '.goal')
    
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY RUN] Would create/update sprint label: $name (description: $goal, color: $SPRINT_LABEL_COLOR)"
    else
      gh label create "$name" --description "$goal" --color "$SPRINT_LABEL_COLOR" --repo "$REPO" 2>/dev/null || \
      gh label edit "$name" --description "$goal" --color "$SPRINT_LABEL_COLOR" --repo "$REPO" 2>/dev/null
      echo "  Created/updated sprint label: $name"
    fi
done

# Create stories
echo "Creating user stories..."
jq -c '.stories[]' "$JSON_FILE" | while read -r story; do
    key=$(echo "$story" | jq -r '.key')
    title=$(echo "$story" | jq -r '.summary')
    description=$(echo "$story" | jq -r '.description')
    
    # Get related epic
    epic_id=$(echo "$story" | jq -r '.epicLink')
    epic_name=$(jq -r --arg id "$epic_id" '.epics[] | select(.id == $id) | .name' "$JSON_FILE")
    
    # Get related sprint
    sprint_id=$(echo "$story" | jq -r '.sprint')
    sprint_name=$(jq -r --arg id "$sprint_id" '.sprints[] | select(.id == $id) | .name' "$JSON_FILE")
    
    # Format acceptance criteria
    acceptance_criteria=$(echo "$story" | jq -r '.acceptanceCriteria | map("- [ ] " + .) | join("\n")')
    
    # Format tasks
    tasks=$(echo "$story" | jq -r '.tasks | map("- [ ] " + .summary + " (" + .estimate + ")") | join("\n")')
    
    # Create labels string
    labels=$(echo "$story" | jq -r '.labels | join(",")' | tr -d '[]" ')
    labels="$labels,$epic_name,$sprint_name"
    
    # Create body with markdown formatting
    body="## Description\n$description\n\n## Acceptance Criteria\n$acceptance_criteria\n\n## Tasks\n$tasks\n\n## Details\n- Key: $key\n- Story Points: $(echo "$story" | jq -r '.storyPoints')\n- Priority: $(echo "$story" | jq -r '.priority')\n- Epic: $epic_name\n- Sprint: $sprint_name"
    
    # Create the issue
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY RUN] Would create issue: $title"
      echo "    Labels: $labels"
      echo "    Body length: $(echo -e "$body" | wc -l) lines"
    else
      issue_url=$(gh issue create --title "$title" --body "$body" --label "$labels" --repo "$REPO")
      if [[ -n "$issue_url" ]]; then
        echo "  Created issue: $title ($issue_url)"
      else
        echo "  Error creating issue: $title"
      fi
    fi
done

echo "✅ Import completed successfully!"