#!/bin/bash
# Import stories from JSON to GitHub Issues using GitHub CLI

JSON_FILE="documentation/user_stories/user-stories-json-template.json"
REPO="your-username/your-repo"

# Create epic labels
echo "Creating epic labels..."
jq -c '.epics[]' "$JSON_FILE" | while read -r epic; do
    name=$(echo "$epic" | jq -r '.name')
    summary=$(echo "$epic" | jq -r '.summary')
    gh label create "$name" --description "$summary" --color "0366d6" --repo "$REPO" || \
    gh label edit "$name" --description "$summary" --color "0366d6" --repo "$REPO"
    echo "  Created/updated epic label: $name"
done

# Create sprint labels
echo "Creating sprint labels..."
jq -c '.sprints[]' "$JSON_FILE" | while read -r sprint; do
    name=$(echo "$sprint" | jq -r '.name')
    goal=$(echo "$sprint" | jq -r '.goal')
    gh label create "$name" --description "$goal" --color "5319e7" --repo "$REPO" || \
    gh label edit "$name" --description "$goal" --color "5319e7" --repo "$REPO"
    echo "  Created/updated sprint label: $name"
done

# Create stories
echo "Creating user stories..."
jq -c '.stories[]' "$JSON_FILE" | while read -r story; do
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
    body="## Description\n$description\n\n## Acceptance Criteria\n$acceptance_criteria\n\n## Tasks\n$tasks\n\n## Details\n- Story Points: $(echo "$story" | jq -r '.storyPoints')\n- Priority: $(echo "$story" | jq -r '.priority')\n- Epic: $epic_name\n- Sprint: $sprint_name"
    
    # Create the issue
    gh issue create --title "$title" --body "$body" --label "$labels" --repo "$REPO"
    echo "  Created issue: $title"
done

echo "✅ Import completed successfully!"