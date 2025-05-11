#!/bin/bash

# Enhanced GitHub project setup script
# Prerequisites:
# - GitHub CLI installed and authenticated
# - jq installed (for JSON parsing)
# - Set REPO and USER before running

REPO="schneidergithub/pmac-github-scrum-starter"
USER="schneidergithub"
PROJECT_NAME="Scrum Board"

echo "Creating project '$PROJECT_NAME' for $REPO"

# Step 1: Create a new project
gh project create --title "$PROJECT_NAME" --format json > project.json
PROJECT_ID=$(jq -r '.id' project.json)

echo "Project created with ID: $PROJECT_ID"

# Step 2: Create custom fields
gh project field-create "$PROJECT_ID" --name "Status" --data-type single_select
gh project field-create "$PROJECT_ID" --name "Story Points" --data-type number
gh project field-create "$PROJECT_ID" --name "Priority" --data-type single_select
gh project field-create "$PROJECT_ID" --name "Sprint" --data-type text

echo "Custom fields created."

# Step 3: Create views
gh project view-create "$PROJECT_ID" --title "Kanban Board" --layout board
gh project view-create "$PROJECT_ID" --title "Sprint Table" --layout table

echo "Views created."

# Step 4: Label setup for automation
gh label create "needs-review" --color FF9F1C --description "Issue ready for review" --repo "$REPO"
gh label create "story" --color 1D76DB --description "User Story" --repo "$REPO"
gh label create "bug" --color D73A4A --description "Bug Report" --repo "$REPO"
gh label create "enhancement" --color A2EEEF --description "Feature Request" --repo "$REPO"

echo "Labels created."

# Step 5: Link existing issues to the new project board (optional)
ISSUE_NUMBERS=$(gh issue list --repo "$REPO" --json number --jq '.[].number')
for ISSUE in $ISSUE_NUMBERS; do
  echo "Adding issue #$ISSUE to project..."
  gh project item-add "$PROJECT_ID" --issue "$USER/$REPO#$ISSUE"
done

echo "All existing issues linked to the project board."

# Step 6: Print summary
echo "✅ Project board setup complete."
echo "🌐 Visit: https://github.com/$REPO/projects"
