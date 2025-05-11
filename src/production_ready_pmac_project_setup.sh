#!/bin/bash

# Production-Ready GitHub Projects (Beta) Automation Script
# Prerequisites:
# - gh CLI with `gh projects` extension installed: gh extension install github/gh-projects
# - jq installed: brew install jq (Mac)

REPO="pmac-github-scrum-starter"
USER="schneidergithub"
PROJECT_NAME="Scrum Board"

echo "🔧 Creating project '$PROJECT_NAME' under user: $USER"

# Step 1: Create the new project and capture its ID
PROJECT_JSON=$(gh projects create --title "$PROJECT_NAME" --user "$USER" --format json)
PROJECT_ID=$(echo "$PROJECT_JSON" | jq -r '.id')

if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ Failed to create project. Check authentication and username."
  exit 1
fi

echo "✅ Project created: $PROJECT_ID"

# Step 2: Add custom fields
gh projects fields-add --project-id "$PROJECT_ID" --name "Status" --data-type SINGLE_SELECT
gh projects fields-add --project-id "$PROJECT_ID" --name "Story Points" --data-type NUMBER
gh projects fields-add --project-id "$PROJECT_ID" --name "Priority" --data-type SINGLE_SELECT
gh projects fields-add --project-id "$PROJECT_ID" --name "Sprint" --data-type TEXT

echo "✅ Custom fields added."

# Step 3: Add "Status" options
STATUS_FIELD_ID=$(gh projects fields-list --project-id "$PROJECT_ID" --format json | jq -r '.[] | select(.name == "Status") | .id')

for OPTION in "Backlog" "Selected for Development" "In Progress" "In Review" "Done"; do
  gh projects fields-options-add --project-id "$PROJECT_ID" --field-id "$STATUS_FIELD_ID" --name "$OPTION"
done

echo "✅ Status options added."

# Step 4: Create views
gh projects views-add --project-id "$PROJECT_ID" --name "Kanban Board" --layout BOARD
gh projects views-add --project-id "$PROJECT_ID" --name "Sprint Table" --layout TABLE

echo "✅ Views created."

# Step 5: Add default labels (force update if they exist)
LABELS=("bug:D73A4A:Bug Report" "story:1D76DB:User Story" "enhancement:A2EEEF:Feature Request" "needs-review:FF9F1C:Ready for Review")

for LABEL_DEF in "${LABELS[@]}"; do
  IFS=':' read -r NAME COLOR DESC <<< "$LABEL_DEF"
  gh label create "$NAME" --color "$COLOR" --description "$DESC" --repo "$USER/$REPO" || gh label edit "$NAME" --color "$COLOR" --description "$DESC" --repo "$USER/$REPO"
done

echo "✅ Labels created or updated."

# Step 6: Link existing issues to project and apply status based on labels
ISSUE_NUMBERS=$(gh issue list --repo "$USER/$REPO" --json number --jq '.[].number')

declare -A LABEL_TO_STATUS=(
  ["bug"]="In Progress"
  ["story"]="Selected for Development"
  ["enhancement"]="Backlog"
  ["needs-review"]="In Review"
)

for ISSUE in $ISSUE_NUMBERS; do
  echo "🔗 Linking issue #$ISSUE to project..."
  gh projects items-add --project-id "$PROJECT_ID" --issue "$USER/$REPO#$ISSUE"

  ITEM_ID=$(gh projects items-list --project-id "$PROJECT_ID" --format json | jq -r ".[] | select(.content.url | contains("$ISSUE")) | .id")

  if [[ -z "$ITEM_ID" ]]; then
    echo "⚠️ Could not locate item for issue #$ISSUE"
    continue
  fi

  LABELS=$(gh issue view "$ISSUE" --repo "$USER/$REPO" --json labels --jq '.labels[].name')

  for LABEL in $LABELS; do
    if [[ -n "${LABEL_TO_STATUS[$LABEL]}" ]]; then
      STATUS_OPTION="${LABEL_TO_STATUS[$LABEL]}"
      OPTION_ID=$(gh projects fields-options-list --project-id "$PROJECT_ID" --field-id "$STATUS_FIELD_ID" --format json | jq -r ".[] | select(.name == \"$STATUS_OPTION\") | .id")

      gh projects fields-update --project-id "$PROJECT_ID" --item-id "$ITEM_ID" --field-id "$STATUS_FIELD_ID" --single-select-option-id "$OPTION_ID"
      echo "   → Status set to $STATUS_OPTION"
      break
    fi
  done
done

echo "🎉 Project board setup complete: https://github.com/users/$USER/projects"
