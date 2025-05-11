# Strategy Guide: Importing User Stories to Agile Boards

This guide provides a comprehensive strategy for converting your existing documentation into importable user stories for your Scrum/Agile board.

## Overview of the Process

1. **Structure the data** in a standardized JSON format
2. **Review and enhance** the user stories
3. **Choose the right import method** for your tool
4. **Execute the import** using scripts or APIs
5. **Verify and organize** the imported stories on your board

## Step 1: Prepare Your JSON Data Structure

We've created a comprehensive JSON template that organizes your stories with proper hierarchy:

- **Epics**: High-level categories (Integration Layer, AI Orchestration, etc.)
- **Sprints**: Time-boxed iterations (Sprint 1-6)
- **Stories**: Detailed user stories with acceptance criteria
- **Tasks**: Individual work items within each story

### Key Benefits of Using JSON

- **Preserves hierarchy**: Maintains the relationship between epics, stories, and tasks
- **Maintains rich formatting**: Preserves markdown formatting in descriptions
- **Flexible**: Can be easily transformed to match different tool requirements
- **Programmatically accessible**: Easy to process with scripts and APIs

## Step 2: Complete the JSON Template

1. **Review the existing user stories** in the template
2. **Add the remaining user stories** from the prioritized list in the documentation
3. **Verify all fields** are correctly populated:
   - Ensure each story has proper acceptance criteria
   - Check that story points and priorities align with your planning
   - Confirm all task breakdowns accurately reflect the implementation plan

## Step 3: Choose Your Import Method

### For GitHub Projects

**Option 1: GitHub CLI Script (Recommended)**
- Simple bash script using GitHub CLI
- Creates labels, issues, and relationships
- Easy to modify and execute
- Requires GitHub CLI to be installed and authenticated

**Option 2: Python Script with GitHub API**
- More flexibility and error handling
- Works across platforms
- Can be extended for custom workflows
- Requires Python environment

**Option 3: Manual Import via GitHub UI**
- For small numbers of stories
- No technical setup required
- Time-consuming for large backlogs

### For Jira

**Option 1: Python Script with Jira API**
- Comprehensive import of epics, stories, sub-tasks
- Preserves all relationships and metadata
- Handles custom fields
- Requires Python environment

**Option 2: CSV Export/Import**
- Convert JSON to Jira CSV format
- Use Jira's built-in CSV importer
- Good for simpler structures

**Option 3: Jira REST API Directly**
- For more control over the import process
- Requires API tokens and programming knowledge

### For Azure DevOps

**Option 1: Python Script with Azure DevOps API**
- Similar approach to GitHub/Jira scripts
- Uses Azure DevOps REST API
- Requires Python environment

**Option 2: CSV Import**
- Export JSON to Azure DevOps CSV format
- Use import wizard
- Works well for basic work items

## Step 4: Execute the Import

### Using the GitHub CLI Script

1. **Install prerequisites**:
   ```bash
   # Install GitHub CLI if needed
   brew install gh  # For macOS
   # Login to GitHub
   gh auth login
   # Install jq for JSON processing
   brew install jq  # For macOS
   ```

2. **Save the script** as `import-stories.sh`

3. **Make the script executable**:
   ```bash
   chmod +x import-stories.sh
   ```

4. **Run the script**:
   ```bash
   ./import-stories.sh user-stories.json
   ```

### Using the Python Script

1. **Set up environment**:
   ```bash
   # Create virtual environment
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   
   # Install required packages
   pip install requests
   ```

2. **Set environment variables**:
   ```bash
   # For GitHub
   export GITHUB_TOKEN=your_github_token
   export GITHUB_REPO=your-username/your-repo
   
   # For Jira
   export JIRA_TOKEN=your_base64_encoded_token
   export JIRA_URL=https://your-instance.atlassian.net
   export JIRA_PROJECT=PROJ
   ```

3. **Run the script**:
   ```bash
   python import_stories.py user-stories.json --target github
   # Or for Jira
   python import_stories.py user-stories.json --target jira
   ```

## Step 5: Verify and Organize

After import, verify your board:

1. **Check all stories were imported** correctly
2. **Verify relationships** between epics, stories, and tasks
3. **Set up your board views**:
   - Kanban board view for sprint planning
   - Task board for daily work
   - Epic view for long-term planning
4. **Adjust any missing metadata** manually if needed

## Customization Tips

### Adjusting for Your Workflow

1. **Custom fields**: If your Agile tool uses custom fields, update the script to include these
2. **Different state models**: Modify status mappings to match your workflow states
3. **Automations**: Set up automations after import to handle transitions

### Handling Large Backlogs

1. **Incremental imports**: Import one epic or sprint at a time
2. **Rate limiting**: Add delays between API calls to avoid rate limits
3. **Pagination**: Implement pagination for large datasets

## Best Practices

1. **Test in a sandbox first**: Try importing to a test project first
2. **Keep a backup**: Save your JSON file as the source of truth
3. **Version control**: Keep your import scripts in version control
4. **Document custom fields**: Note any custom field IDs needed for imports
5. **Schedule imports during off-hours**: For large imports to avoid disruption

## Troubleshooting

### Common Issues and Solutions

1. **API rate limiting**:
   - Add delays between requests
   - Use token with higher rate limits

2. **Missing relationships**:
   - Check if parent issues exist before creating children
   - Use two-pass import (create all issues first, then update relationships)

3. **Field mapping errors**:
   - Verify custom field IDs are correct
   - Check field types match (text, number, etc.)

4. **Authentication failures**:
   - Ensure tokens have correct permissions
   - Check token expiration

## Conclusion

By following this strategy guide, you can efficiently move your user stories from documentation to an Agile board with the proper structure and relationships maintained. The JSON-based approach gives you flexibility to adapt to different tools while keeping a single source of truth for your backlog.
