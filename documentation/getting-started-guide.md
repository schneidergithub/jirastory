When interacting with other personas, explain technical concepts clearly while respecting their non-technical perspective. Balance technical optimality with practical business needs.',
    TRUE,
    '{"expertise": ["technical implementation", "architecture", "effort estimation", "technical dependencies", "coding"]}'
);

-- Insert default QA Engineer persona
INSERT INTO personas (name, role, prompt_template, active, metadata)
VALUES (
    'QA Engineer',
    'QA Engineer',
    'You are an experienced QA Engineer AI assistant participating in a story refinement session. Your focus is on testability, edge cases, and quality assurance.

When analyzing a user story, consider:
- Is the story testable as written?
- What edge cases or boundary conditions need to be considered?
- Are there any potential regression risks?
- What test scenarios would validate this story?
- Are there any ambiguities that could lead to quality issues?

For this refinement session, focus specifically on:
1. Testability of requirements and acceptance criteria
2. Missing edge cases or boundary conditions
3. Potential regression risks
4. Test scenarios needed to validate the story
5. Ambiguities that could lead to quality issues

When interacting with other personas, advocate for quality while acknowledging both business needs and technical constraints. Be thorough in identifying potential issues before they reach production.',
    TRUE,
    '{"expertise": ["testing", "edge cases", "quality assurance", "test planning", "defect prevention"]}'
);

-- Insert default Architect persona
INSERT INTO personas (name, role, prompt_template, active, metadata)
VALUES (
    'Architect',
    'Architect',
    'You are an experienced Architect AI assistant participating in a story refinement session. Your focus is on architectural impacts, standards compliance, and non-functional requirements.

When analyzing a user story, consider:
- How does this story align with the overall system architecture?
- Are there non-functional requirements to consider (performance, security, scalability)?
- Does the implementation comply with technical standards and patterns?
- Are there cross-cutting concerns or system-wide impacts?
- What are the potential technical debt implications?

For this refinement session, focus specifically on:
1. Architectural impact and alignment with system design
2. Non-functional requirements (performance, security, scalability)
3. Compliance with technical standards and patterns
4. Cross-cutting concerns or system-wide impacts
5. Potential technical debt implications

When interacting with other personas, balance immediate implementation needs with long-term architectural health. Explain architectural concepts clearly while acknowledging business priorities.',
    TRUE,
    '{"expertise": ["system architecture", "design patterns", "non-functional requirements", "technical standards", "long-term vision"]}'
);

-- Insert default Scrum Master persona
INSERT INTO personas (name, role, prompt_template, active, metadata)
VALUES (
    'Scrum Master',
    'Scrum Master',
    'You are an experienced Scrum Master AI assistant facilitating a story refinement session. Your focus is on guiding the conversation, ensuring all perspectives are heard, and driving toward clearer, well-refined stories.

As facilitator, your responsibilities include:
1. Guiding the conversation through a structured refinement flow
2. Ensuring balanced input from all specialized personas
3. Identifying when the team is going off-track and redirecting
4. Summarizing key points and decisions
5. Determining when sufficient refinement has occurred

For this refinement session:
- Start by asking the Product Owner to assess business clarity
- Then involve the Developer for technical feasibility and estimation
- Next bring in the QA Engineer for testability and edge cases
- Finally include the Architect for system-wide considerations
- Throughout, look for improvement opportunities and missing details
- Conclude by summarizing all key decisions and changes

When interacting with other personas, maintain neutrality while keeping the conversation productive and focused. Your goal is a well-refined story, not necessarily a perfect one.',
    TRUE,
    '{"expertise": ["facilitation", "scrum process", "team dynamics", "consensus building", "impediment removal"]}'
);
EOF

# Add to the docker-compose.yml to include the persona initialization
cat >> scripts/init-db.sql << EOF

-- Import personas initialization
\i /docker-entrypoint-initdb.d/personas-init.sql
EOF
```

### 4. Start Building the Front-End (Day 8-10)

#### 4.1 Create Basic Dashboard Components
```bash
# Create Dashboard component
mkdir -p frontend/src/components
cat > frontend/src/components/Dashboard.js << EOF
import React, { useState, useEffect } from 'react';
import { 
  Box, 
  Typography, 
  Card, 
  CardContent, 
  Grid,
  Button,
  CircularProgress,
  Alert
} from '@mui/material';
import { useQuery } from 'react-query';
import axios from 'axios';

const fetchStories = async () => {
  const response = await axios.get('http://localhost:8000/api/stories');
  return response.data;
};

const Dashboard = () => {
  const { data: stories, isLoading, error, refetch } = useQuery('stories', fetchStories);

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mt: 2 }}>
        Error loading stories: {error.message}
      </Alert>
    );
  }

  return (
    <Box sx={{ mt: 4 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4">Story Dashboard</Typography>
        <Button variant="contained" color="primary" onClick={() => refetch()}>
          Refresh
        </Button>
      </Box>

      <Grid container spacing={3}>
        {stories && stories.length > 0 ? (
          stories.map((story) => (
            <Grid item xs={12} md={6} lg={4} key={story.id}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    {story.title}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Jira: {story.jira_key}
                    {story.github_issue_number && ` | GitHub: #${story.github_issue_number}`}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Status: {story.status} | Priority: {story.priority || 'N/A'}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Story Points: {story.story_points || 'Not estimated'}
                  </Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    {story.description
                      ? story.description.length > 100
                        ? `${story.description.substring(0, 100)}...`
                        : story.description
                      : 'No description provided.'}
                  </Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    Acceptance Criteria: {story.acceptance_criteria.length}
                  </Typography>
                  <Box sx={{ mt: 2, display: 'flex', justifyContent: 'flex-end' }}>
                    <Button size="small" color="primary">
                      View Details
                    </Button>
                    <Button size="small" color="secondary" sx={{ ml: 1 }}>
                      Refine
                    </Button>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          ))
        ) : (
          <Grid item xs={12}>
            <Alert severity="info">
              No stories found. Import stories from Jira to get started.
            </Alert>
          </Grid>
        )}
      </Grid>
    </Box>
  );
};

export default Dashboard;
EOF

# Create Header component
cat > frontend/src/components/Header.js << EOF
import React from 'react';
import { 
  AppBar, 
  Toolbar, 
  Typography, 
  Button, 
  Box,
  IconButton,
  Menu,
  MenuItem
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import { Link } from 'react-router-dom';

const Header = () => {
  const [anchorEl, setAnchorEl] = React.useState(null);
  const open = Boolean(anchorEl);
  
  const handleClick = (event) => {
    setAnchorEl(event.currentTarget);
  };
  
  const handleClose = () => {
    setAnchorEl(null);
  };

  return (
    <AppBar position="static">
      <Toolbar>
        <Typography 
          variant="h6" 
          component={Link} 
          to="/" 
          sx={{ 
            flexGrow: 1, 
            color: 'white', 
            textDecoration: 'none' 
          }}
        >
          AI Scrum Refinement
        </Typography>
        
        <Box sx={{ display: { xs: 'none', md: 'flex' } }}>
          <Button color="inherit" component={Link} to="/">
            Dashboard
          </Button>
          <Button color="inherit" component={Link} to="/import">
            Import
          </Button>
          <Button color="inherit" component={Link} to="/refine">
            Refine
          </Button>
          <Button color="inherit" component={Link} to="/settings">
            Settings
          </Button>
        </Box>
        
        <Box sx={{ display: { xs: 'flex', md: 'none' } }}>
          <IconButton
            size="large"
            edge="end"
            color="inherit"
            aria-label="menu"
            onClick={handleClick}
          >
            <MenuIcon />
          </IconButton>
          <Menu
            anchorEl={anchorEl}
            open={open}
            onClose={handleClose}
          >
            <MenuItem onClick={handleClose} component={Link} to="/">
              Dashboard
            </MenuItem>
            <MenuItem onClick={handleClose} component={Link} to="/import">
              Import
            </MenuItem>
            <MenuItem onClick={handleClose} component={Link} to="/refine">
              Refine
            </MenuItem>
            <MenuItem onClick={handleClose} component={Link} to="/settings">
              Settings
            </MenuItem>
          </Menu>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Header;
EOF

# Update App.js to use the new components
cat > frontend/src/App.js << EOF
import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { Box, Container } from '@mui/material';
import Header from './components/Header';
import Dashboard from './components/Dashboard';

// Placeholder components - replace with real implementations
const ImportPage = () => (
  <Box sx={{ mt: 4 }}>
    <h2>Import from Jira</h2>
    <p>This page will allow importing stories from Jira.</p>
  </Box>
);

const RefinePage = () => (
  <Box sx={{ mt: 4 }}>
    <h2>Story Refinement</h2>
    <p>This page will show the AI-powered refinement interface.</p>
  </Box>
);

const SettingsPage = () => (
  <Box sx={{ mt: 4 }}>
    <h2>Settings</h2>
    <p>This page will allow configuring the system.</p>
  </Box>
);

const App = () => {
  return (
    <Box>
      <Header />
      <Container maxWidth="lg">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/import" element={<ImportPage />} />
          <Route path="/refine" element={<RefinePage />} />
          <Route path="/settings" element={<SettingsPage />} />
        </Routes>
      </Container>
    </Box>
  );
};

export default App;
EOF
```

### 5. Set Up CI/CD and Documentation (Ongoing)

#### 5.1 GitHub Actions Workflow
```bash
# Create GitHub Actions workflow file
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << EOF
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
          
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install dependencies for integration service
        run: |
          pip install poetry
          cd integration-service
          poetry config virtualenvs.create false
          poetry install
          
      - name: Install dependencies for AI orchestration
        run: |
          cd ai-orchestration
          poetry config virtualenvs.create false
          poetry install
          
      - name: Run tests for integration service
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test
        run: |
          cd integration-service
          pytest
          
      - name: Run tests for AI orchestration
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test
        run: |
          cd ai-orchestration
          pytest

  build:
    name: Build Docker Images
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
        
      - name: Build integration service
        uses: docker/build-push-action@v4
        with:
          context: ./integration-service
          push: false
          tags: ai-scrum-refinement/integration-service:latest
          
      - name: Build AI orchestration
        uses: docker/build-push-action@v4
        with:
          context: ./ai-orchestration
          push: false
          tags: ai-scrum-refinement/ai-orchestration:latest
          
      - name: Build frontend
        uses: docker/build-push-action@v4
        with:
          context: ./frontend
          push: false
          tags: ai-scrum-refinement/frontend:latest
EOF

# Add a basic README for documentation
cat > DEVELOPMENT.md << EOF
# Development Guide

This guide provides instructions for setting up the development environment and working with the AI-Powered Scrum Refinement System.

## Prerequisites

- Docker and Docker Compose
- Python 3.11+
- Node.js 18+
- Poetry (for Python dependency management)

## Getting Started

### 1. Clone the repository
\`\`\`bash
git clone https://github.com/your-org/ai-scrum-refinement.git
cd ai-scrum-refinement
\`\`\`

### 2. Create environment file
\`\`\`bash
cp .env.example .env
# Edit .env with your API keys and configuration
\`\`\`

### 3. Start the development environment
\`\`\`bash
docker-compose up -d
\`\`\`

### 4. Initialize the database
The database should be automatically initialized by the Docker container. If you need to manually initialize or reset the database:

\`\`\`bash
docker-compose exec postgres psql -U refinement -d refinement -f /docker-entrypoint-initdb.d/init.sql
\`\`\`

### 5. Verify services are running
- Integration Service: http://localhost:8000/health
- AI Orchestration Service: http://localhost:8001/health
- Frontend: http://localhost:3000

## Development Workflow

### Integration Service

To work on the Integration Service:

\`\`\`bash
cd integration-service
poetry install  # Install dependencies
poetry run pytest  # Run tests
poetry run uvicorn app.main:app --reload  # Start development server
\`\`\`

### AI Orchestration Service

To work on the AI Orchestration Service:

\`\`\`bash
cd ai-orchestration
poetry install  # Install dependencies
poetry run pytest  # Run tests
poetry run uvicorn app.main:app --reload  # Start development server
\`\`\`

### Frontend

To work on the Frontend:

\`\`\`bash
cd frontend
npm install  # Install dependencies
npm start  # Start development server
npm test  # Run tests
\`\`\`

## API Documentation

Once the services are running, you can access the API documentation:

- Integration Service API: http://localhost:8000/docs
- AI Orchestration Service API: http://localhost:8001/docs

## Running Tests

\`\`\`bash
# Integration Service tests
cd integration-service
poetry run pytest

# AI Orchestration Service tests
cd ai-orchestration
poetry run pytest

# Frontend tests
cd frontend
npm test
\`\`\`

## Deployment

For production deployment, use the provided Dockerfiles and Kubernetes configurations in the \`k8s\` directory.

## Project Structure

- \`integration-service/\`: Service for Jira-GitHub integration
- \`ai-orchestration/\`: Service for AI-powered refinement
- \`frontend/\`: React-based user interface
- \`k8s/\`: Kubernetes deployment configurations
- \`scripts/\`: Utility scripts and database initialization
- \`docs/\`: Documentation
EOF

# Create Kubernetes base configuration
mkdir -p k8s/base
cat > k8s/base/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- integration-service.yaml
- ai-orchestration.yaml
- frontend.yaml
- database.yaml
EOF

cat > k8s/base/integration-service.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: integration-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: integration-service
  template:
    metadata:
      labels:
        app: integration-service
    spec:
      containers:
      - name: integration-service
        image: ai-scrum-refinement/integration-service
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: redis-url
        - name: JIRA_BASE_URL
          valueFrom:
            configMapKeyRef:
              name: refinement-config
              key: jira-base-url
        - name: JIRA_API_TOKEN
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: jira-api-token
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: github-token
        - name: GITHUB_REPOSITORY
          valueFrom:
            configMapKeyRef:
              name: refinement-config
              key: github-repository
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: integration-service
spec:
  selector:
    app: integration-service
  ports:
  - port: 80
    targetPort: 8000
  type: ClusterIP
EOF

cat > k8s/base/ai-orchestration.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-orchestration
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ai-orchestration
  template:
    metadata:
      labels:
        app: ai-orchestration
    spec:
      containers:
      - name: ai-orchestration
        image: ai-scrum-refinement/ai-orchestration
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: redis-url
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: anthropic-api-key
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: ai-orchestration
spec:
  selector:
    app: ai-orchestration
  ports:
  - port: 80
    targetPort: 8000
  type: ClusterIP
EOF

cat > k8s/base/frontend.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: ai-scrum-refinement/frontend
        ports:
        - containerPort: 3000
        env:
        - name: REACT_APP_API_URL
          value: "/api"
        - name: REACT_APP_AI_API_URL
          value: "/ai-api"
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
EOF

cat > k8s/base/database.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  selector:
    matchLabels:
      app: postgres
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: postgres-user
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: postgres-password
        - name: POSTGRES_DB
          valueFrom:
            secretKeyRef:
              name: refinement-secrets
              key: postgres-db
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        - name: init-scripts
          mountPath: /docker-entrypoint-initdb.d
      volumes:
      - name: postgres-data
        persistentVolumeClaim:
          claimName: postgres-pvc
      - name: init-scripts
        configMap:
          name: postgres-init-scripts
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF

mkdir -p k8s/overlays/dev
cat > k8s/overlays/dev/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
- ../../base

# Add dev-specific configurations here
EOF
```

## 6. Launching the System

Now that all the initial files are set up, you can launch the system using:

```bash
# Create your .env file with the required API keys
cp .env.example .env
# Edit the .env file with your specific values

# Start the development environment
docker-compose up -d

# Check the services are running
curl http://localhost:8000/health
curl http://localhost:8001/health
```

## 7. Next Steps

After successfully launching the basic system, here are the next steps to build out the functionality:

1. **Complete the Integration Layer**
   - Implement bidirectional synchronization
   - Add error handling and retry mechanisms
   - Create comprehensive tests

2. **Develop AI Orchestration**
   - Implement the conversation controller
   - Create decision extraction mechanisms
   - Build refinement history tracking

3. **Enhance Frontend**
   - Build out the refinement interface
   - Implement the import workflow
   - Create settings and configuration pages

4. **Implement Security**
   - Add authentication and authorization
   - Implement secure API access
   - Create user management

These initial files provide a solid foundation for your AI-Powered Scrum Refinement System. From here, you can incrementally build out features following the user stories defined in the implementation plan.
            criteria_lines = [line.strip() for line in ac_section.split('\n') if line.strip().startswith('- [ ]') or line.strip().startswith('- [x]')]
            acceptance_criteria = [line[6:].strip() for line in criteria_lines]
        
        return {
            "number": issue.number,
            "title": issue.title,
            "body": body,
            "state": issue.state,
            "created_at": issue.created_at,
            "updated_at": issue.updated_at,
            "jira_key": metadata.get("jira_key"),
            "story_points": metadata.get("story_points"),
            "status": metadata.get("status"),
            "priority": metadata.get("priority"),
            "acceptance_criteria": acceptance_criteria,
            "labels": [label.name for label in issue.labels]
        }
        
    def _extract_metadata(self, body: str) -> Dict[str, Any]:
        """Extract metadata from issue body."""
        metadata = {}
        if "<!-- METADATA" in body and "-->" in body:
            metadata_text = body.split("<!-- METADATA")[1].split("-->")[0]
            for line in metadata_text.split('\n'):
                line = line.strip()
                if ': ' in line:
                    key, value = line.split(': ', 1)
                    metadata[key] = value
        return metadata
EOF
```

#### 2.3 Create Basic API Routes
```bash
# Create API routes for stories
mkdir -p integration-service/app/api/routes
cat > integration-service/app/api/routes/stories.py << EOF
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid

from app.models.database import get_db
from app.models.story import Story, StoryCreate, StoryRead, StoryUpdate, AcceptanceCriteria
from app.services.jira_connector import JiraConnector
from app.services.github_connector import GitHubConnector

router = APIRouter(
    prefix="/stories",
    tags=["stories"],
)

# Initialize services
jira_connector = JiraConnector()
github_connector = GitHubConnector()

@router.get("/", response_model=List[StoryRead])
async def get_stories(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db)
):
    """Get all stories with pagination."""
    stories = db.query(Story).offset(skip).limit(limit).all()
    return stories

@router.get("/{story_id}", response_model=StoryRead)
async def get_story(
    story_id: uuid.UUID, 
    db: Session = Depends(get_db)
):
    """Get a specific story by ID."""
    story = db.query(Story).filter(Story.id == story_id).first()
    if story is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Story not found")
    return story

@router.post("/", response_model=StoryRead)
async def create_story(
    story: StoryCreate, 
    db: Session = Depends(get_db)
):
    """Create a new story."""
    # Check if story with same Jira key already exists
    existing = db.query(Story).filter(Story.jira_key == story.jira_key).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, 
            detail=f"Story with Jira key {story.jira_key} already exists"
        )
    
    # Create new story
    db_story = Story(
        jira_key=story.jira_key,
        title=story.title,
        description=story.description,
        story_points=story.story_points,
        status=story.status,
        priority=story.priority,
    )
    
    # Add acceptance criteria
    for ac in story.acceptance_criteria:
        db_story.acceptance_criteria.append(
            AcceptanceCriteria(
                description=ac.description,
                status=ac.status
            )
        )
    
    # Save to database
    db.add(db_story)
    db.commit()
    db.refresh(db_story)
    
    return db_story

@router.post("/from-jira/{jira_key}", response_model=StoryRead)
async def import_from_jira(
    jira_key: str, 
    create_github_issue: bool = False,
    db: Session = Depends(get_db)
):
    """Import a story from Jira."""
    # Check if story already exists
    existing = db.query(Story).filter(Story.jira_key == jira_key).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, 
            detail=f"Story with Jira key {jira_key} already exists"
        )
    
    # Get story from Jira
    try:
        jira_story = await jira_connector.get_story_details(jira_key)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to get story from Jira: {str(e)}"
        )
    
    # Create story in database
    db_story = Story(
        jira_key=jira_story["key"],
        title=jira_story["title"],
        description=jira_story["description"],
        story_points=jira_story["story_points"],
        status=jira_story["status"],
        priority=jira_story["priority"],
        last_jira_update=jira_story["updated"],
    )
    
    # Add acceptance criteria
    for ac_text in jira_story["acceptance_criteria"]:
        db_story.acceptance_criteria.append(
            AcceptanceCriteria(
                description=ac_text,
                status="PENDING"
            )
        )
    
    # Save to database
    db.add(db_story)
    db.commit()
    db.refresh(db_story)
    
    # Create GitHub issue if requested
    if create_github_issue:
        try:
            github_issue = await github_connector.create_issue({
                "jira_key": db_story.jira_key,
                "title": db_story.title,
                "description": db_story.description,
                "story_points": db_story.story_points,
                "status": db_story.status,
                "priority": db_story.priority,
                "acceptance_criteria": [ac.description for ac in db_story.acceptance_criteria],
                "labels": []  # Add default labels if needed
            })
            
            # Update story with GitHub issue number
            db_story.github_issue_number = github_issue["number"]
            db_story.last_github_update = github_issue["updated_at"]
            db_story.sync_status = "SYNCED"
            db.commit()
            db.refresh(db_story)
        except Exception as e:
            # Don't fail the whole operation if GitHub creation fails
            db_story.sync_status = "GITHUB_FAILED"
            db.commit()
    
    return db_story

@router.put("/{story_id}", response_model=StoryRead)
async def update_story(
    story_id: uuid.UUID,
    story: StoryUpdate,
    sync_to_jira: bool = False,
    sync_to_github: bool = False,
    db: Session = Depends(get_db)
):
    """Update an existing story."""
    db_story = db.query(Story).filter(Story.id == story_id).first()
    if db_story is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Story not found")
    
    # Update fields
    if story.title is not None:
        db_story.title = story.title
    if story.description is not None:
        db_story.description = story.description
    if story.story_points is not None:
        db_story.story_points = story.story_points
    if story.status is not None:
        db_story.status = story.status
    if story.priority is not None:
        db_story.priority = story.priority
    
    # Save to database
    db.commit()
    db.refresh(db_story)
    
    # TODO: Add synchronization logic for Jira and GitHub
    
    return db_story

@router.delete("/{story_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_story(
    story_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    """Delete a story."""
    db_story = db.query(Story).filter(Story.id == story_id).first()
    if db_story is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Story not found")
    
    # Delete from database
    db.delete(db_story)
    db.commit()
    
    return None
EOF

# Update main.py to include routes
cat > integration-service/app/main.py << EOF
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import stories

app = FastAPI(
    title="Integration Service",
    description="API for Jira-GitHub synchronization",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(stories.router, prefix="/api")

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/")
async def root():
    return {
        "service": "Integration Service",
        "version": "0.1.0",
        "status": "running",
    }
EOF
```

### 3. Begin AI Orchestration Implementation (Day 6-7)

#### 3.1 Create AI Persona Configuration System
```bash
# Create database models for AI personas
mkdir -p ai-orchestration/app/models
cat > ai-orchestration/app/models/database.py << EOF
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config.settings import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF

cat > ai-orchestration/app/models/persona.py << EOF
from sqlalchemy import Column, String, Boolean, Text, DateTime, JSON
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel

from .database import Base


class Persona(Base):
    __tablename__ = "personas"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    role = Column(String, nullable=False)
    prompt_template = Column(Text, nullable=False)
    active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    metadata = Column(JSON, nullable=True)


# Pydantic models for API
class PersonaCreate(BaseModel):
    name: str
    role: str
    prompt_template: str
    active: bool = True
    metadata: Optional[Dict[str, Any]] = None


class PersonaRead(BaseModel):
    id: uuid.UUID
    name: str
    role: str
    prompt_template: str
    active: bool
    metadata: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class PersonaUpdate(BaseModel):
    name: Optional[str] = None
    role: Optional[str] = None
    prompt_template: Optional[str] = None
    active: Optional[bool] = None
    metadata: Optional[Dict[str, Any]] = None
EOF

# Create AI service for Claude API interaction
mkdir -p ai-orchestration/app/services
cat > ai-orchestration/app/services/ai_service.py << EOF
import logging
import anthropic
from typing import Dict, Any, List, Optional
from app.config.settings import settings

logger = logging.getLogger(__name__)

class AIService:
    def __init__(self):
        """Initialize the AI service with API key."""
        self.api_key = settings.ANTHROPIC_API_KEY
        self.client = anthropic.Anthropic(api_key=self.api_key)
        
    async def analyze_story(
        self,
        persona_prompt: str,
        story_data: Dict[str, Any],
        max_tokens: int = 2000
    ) -> Dict[str, Any]:
        """
        Have an AI persona analyze a story.
        
        Args:
            persona_prompt: The prompt template for the persona
            story_data: The story data to analyze
            max_tokens: Maximum tokens in the response
            
        Returns:
            AI analysis results
        """
        try:
            # Format the story content for the prompt
            story_content = self._format_story_content(story_data)
            
            # Prepare the messages
            messages = [
                {
                    "role": "user", 
                    "content": f"Here is the user story to analyze:\n\n{story_content}"
                }
            ]
            
            # Create the prompt with the persona template
            system_prompt = persona_prompt
            
            # Call the Claude API
            response = await self.client.messages.create(
                model="claude-3-opus-20240229",  # or your preferred model
                max_tokens=max_tokens,
                temperature=0.2,  # Lower temperature for more consistent results
                system=system_prompt,
                messages=messages
            )
            
            # Process and structure the response
            processed_response = self._process_ai_response(response)
            
            return processed_response
        except Exception as e:
            logger.error(f"Error in AI analysis: {str(e)}")
            raise
            
    async def simulate_conversation(
        self,
        personas: List[Dict[str, Any]],
        story_data: Dict[str, Any],
        conversation_history: Optional[List[Dict[str, Any]]] = None,
        max_tokens: int = 2000
    ) -> Dict[str, Any]:
        """
        Simulate a conversation between AI personas about a story.
        
        Args:
            personas: List of persona configurations
            story_data: The story data to discuss
            conversation_history: Optional history of previous turns
            max_tokens: Maximum tokens in the response
            
        Returns:
            AI conversation results
        """
        try:
            # Determine which persona should speak next
            next_persona = self._select_next_speaker(personas, conversation_history or [])
            
            # Format the story content for the prompt
            story_content = self._format_story_content(story_data)
            
            # Prepare the system prompt for the selected persona
            system_prompt = next_persona["prompt_template"]
            
            # Format conversation history for the prompt
            messages = []
            
            # Add the initial story context if this is the first turn
            if not conversation_history or len(conversation_history) == 0:
                messages.append({
                    "role": "user", 
                    "content": f"Here is the user story for refinement:\n\n{story_content}\n\nPlease begin the refinement discussion."
                })
            else:
                # Format previous conversation turns
                for turn in conversation_history:
                    role = "assistant" if turn.get("is_ai") else "user"
                    messages.append({
                        "role": role,
                        "content": turn["content"]
                    })
                
                # Add instruction for next turn
                messages.append({
                    "role": "user",
                    "content": f"Continue the refinement discussion as the {next_persona['role']} persona. Respond to the previous comments and provide your perspective on the story."
                })
            
            # Call the Claude API
            response = await self.client.messages.create(
                model="claude-3-opus-20240229",  # or your preferred model
                max_tokens=max_tokens,
                temperature=0.3,
                system=system_prompt,
                messages=messages
            )
            
            # Process and structure the response
            processed_response = self._process_ai_response(response)
            processed_response["persona"] = {
                "id": next_persona["id"],
                "name": next_persona["name"],
                "role": next_persona["role"]
            }
            
            return processed_response
        except Exception as e:
            logger.error(f"Error in AI conversation: {str(e)}")
            raise
    
    def _format_story_content(self, story_data: Dict[str, Any]) -> str:
        """Format story data into a structured text format for the prompt."""
        content = f"# {story_data.get('title', 'Untitled Story')}\n\n"
        
        # Add basic info
        content += f"**ID:** {story_data.get('jira_key', 'N/A')}\n"
        content += f"**Status:** {story_data.get('status', 'N/A')}\n"
        content += f"**Priority:** {story_data.get('priority', 'N/A')}\n"
        content += f"**Story Points:** {story_data.get('story_points', 'N/A')}\n\n"
        
        # Add description
        content += "## Description\n\n"
        content += f"{story_data.get('description', 'No description provided.')}\n\n"
        
        # Add acceptance criteria
        content += "## Acceptance Criteria\n\n"
        if story_data.get("acceptance_criteria") and len(story_data["acceptance_criteria"]) > 0:
            for i, criteria in enumerate(story_data["acceptance_criteria"], 1):
                content += f"{i}. {criteria}\n"
        else:
            content += "No acceptance criteria specified.\n"
            
        return content
        
    def _process_ai_response(self, response) -> Dict[str, Any]:
        """Process and structure the AI response."""
        return {
            "content": response.content[0].text,
            "model": response.model,
            "usage": {
                "input_tokens": response.usage.input_tokens,
                "output_tokens": response.usage.output_tokens
            },
            "stop_reason": response.stop_reason,
            "stop_sequence": response.stop_sequence,
            "decisions": []  # Placeholder for extracted decisions
        }
        
    def _select_next_speaker(
        self, 
        personas: List[Dict[str, Any]], 
        conversation_history: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Determine which persona should speak next in the conversation.
        
        This is a simplified implementation. In a real system, this would be more sophisticated.
        """
        if not conversation_history:
            # If no history, start with the Scrum Master
            for persona in personas:
                if persona["role"] == "Scrum Master":
                    return persona
            # Fallback to first persona if no Scrum Master
            return personas[0]
        
        # Get the last speaking persona
        last_persona_id = None
        for turn in reversed(conversation_history):
            if turn.get("persona_id"):
                last_persona_id = turn["persona_id"]
                break
                
        # Simple round-robin selection
        if last_persona_id:
            for i, persona in enumerate(personas):
                if persona["id"] == last_persona_id:
                    # Select next persona in the list
                    next_index = (i + 1) % len(personas)
                    return personas[next_index]
        
        # Fallback to first persona
        return personas[0]
EOF

# Create API routes for personas
mkdir -p ai-orchestration/app/api/routes
cat > ai-orchestration/app/api/routes/personas.py << EOF
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid

from app.models.database import get_db
from app.models.persona import Persona, PersonaCreate, PersonaRead, PersonaUpdate

router = APIRouter(
    prefix="/personas",
    tags=["personas"],
)

@router.get("/", response_model=List[PersonaRead])
async def get_personas(
    active_only: bool = False,
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db)
):
    """Get all personas with pagination."""
    query = db.query(Persona)
    if active_only:
        query = query.filter(Persona.active == True)
    personas = query.offset(skip).limit(limit).all()
    return personas

@router.get("/{persona_id}", response_model=PersonaRead)
async def get_persona(
    persona_id: uuid.UUID, 
    db: Session = Depends(get_db)
):
    """Get a specific persona by ID."""
    persona = db.query(Persona).filter(Persona.id == persona_id).first()
    if persona is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Persona not found")
    return persona

@router.post("/", response_model=PersonaRead)
async def create_persona(
    persona: PersonaCreate, 
    db: Session = Depends(get_db)
):
    """Create a new persona."""
    db_persona = Persona(
        name=persona.name,
        role=persona.role,
        prompt_template=persona.prompt_template,
        active=persona.active,
        metadata=persona.metadata,
    )
    
    db.add(db_persona)
    db.commit()
    db.refresh(db_persona)
    
    return db_persona

@router.put("/{persona_id}", response_model=PersonaRead)
async def update_persona(
    persona_id: uuid.UUID,
    persona: PersonaUpdate,
    db: Session = Depends(get_db)
):
    """Update an existing persona."""
    db_persona = db.query(Persona).filter(Persona.id == persona_id).first()
    if db_persona is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Persona not found")
    
    # Update fields
    if persona.name is not None:
        db_persona.name = persona.name
    if persona.role is not None:
        db_persona.role = persona.role
    if persona.prompt_template is not None:
        db_persona.prompt_template = persona.prompt_template
    if persona.active is not None:
        db_persona.active = persona.active
    if persona.metadata is not None:
        db_persona.metadata = persona.metadata
    
    db.commit()
    db.refresh(db_persona)
    
    return db_persona

@router.delete("/{persona_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_persona(
    persona_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    """Delete a persona."""
    db_persona = db.query(Persona).filter(Persona.id == persona_id).first()
    if db_persona is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Persona not found")
    
    db.delete(db_persona)
    db.commit()
    
    return None
EOF

# Create API routes for refinement
cat > ai-orchestration/app/api/routes/refinement.py << EOF
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
import uuid
import httpx
from datetime import datetime

from app.models.database import get_db
from app.models.persona import Persona
from app.services.ai_service import AIService

router = APIRouter(
    prefix="/refinement",
    tags=["refinement"],
)

# Initialize services
ai_service = AIService()

@router.post("/analyze")
async def analyze_story(
    story_data: Dict[str, Any],
    persona_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    """
    Analyze a story with a specific AI persona.
    
    Args:
        story_data: The story data to analyze
        persona_id: The ID of the persona to use
        
    Returns:
        Analysis results
    """
    # Get the persona
    persona = db.query(Persona).filter(Persona.id == persona_id, Persona.active == True).first()
    if persona is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Persona not found or inactive")
    
    # Perform analysis
    try:
        result = await ai_service.analyze_story(
            persona_prompt=persona.prompt_template,
            story_data=story_data
        )
        
        # Add persona information to result
        result["persona"] = {
            "id": str(persona.id),
            "name": persona.name,
            "role": persona.role
        }
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Analysis failed: {str(e)}"
        )

@router.post("/simulate")
async def simulate_conversation(
    story_data: Dict[str, Any],
    conversation_history: Optional[List[Dict[str, Any]]] = None,
    persona_id: Optional[uuid.UUID] = None,
    db: Session = Depends(get_db)
):
    """
    Simulate the next turn in a refinement conversation.
    
    Args:
        story_data: The story data being discussed
        conversation_history: Optional history of previous turns
        persona_id: Optional specific persona to use for the next turn
        
    Returns:
        Conversation turn results
    """
    # Get active personas
    personas_query = db.query(Persona).filter(Persona.active == True)
    
    # If specific persona requested, filter for it
    if persona_id is not None:
        personas_query = personas_query.filter(Persona.id == persona_id)
        if personas_query.count() == 0:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Requested persona not found or inactive")
    
    personas = personas_query.all()
    if not personas:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No active personas available")
    
    # Convert personas to dict format for the service
    persona_dicts = [
        {
            "id": str(p.id),
            "name": p.name,
            "role": p.role,
            "prompt_template": p.prompt_template
        }
        for p in personas
    ]
    
    # Simulate conversation
    try:
        result = await ai_service.simulate_conversation(
            personas=persona_dicts,
            story_data=story_data,
            conversation_history=conversation_history or []
        )
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Conversation simulation failed: {str(e)}"
        )
EOF

# Update main.py to include routes
cat > ai-orchestration/app/main.py << EOF
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import personas, refinement

app = FastAPI(
    title="AI Orchestration Service",
    description="API for AI-powered story refinement",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(personas.router, prefix="/api")
app.include_router(refinement.router, prefix="/api")

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/")
async def root():
    return {
        "service": "AI Orchestration Service",
        "version": "0.1.0",
        "status": "running",
    }
EOF
```

#### 3.2 Add Database Initialization for Default Personas
```bash
# Create database initialization script for personas
mkdir -p scripts
cat > scripts/init-personas.sql << EOF
-- Add this to scripts/init-db.sql or run separately

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create personas table if it doesn't exist
CREATE TABLE IF NOT EXISTS personas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL,
    prompt_template TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB
);

-- Insert default Product Owner persona
INSERT INTO personas (name, role, prompt_template, active, metadata)
VALUES (
    'Product Owner',
    'Product Owner',
    'You are an experienced Product Owner AI assistant participating in a story refinement session. Your focus is on business value, clarity, and well-defined acceptance criteria.

When analyzing a user story, consider:
- Is the user value clear and specific?
- Are all acceptance criteria measurable and testable?
- Is the scope appropriately defined (not too large, not too small)?
- Are there missing edge cases or scenarios?

For this refinement session, focus specifically on:
1. Clarity of the user need and business value
2. Completeness and testability of acceptance criteria
3. Appropriate scope definition
4. Any missing requirements or edge cases
5. Alignment with product goals

When interacting with other personas, maintain a collaborative tone while advocating for user needs and business value. You may respectfully challenge technical perspectives if they seem to overlook user value.',
    TRUE,
    '{"expertise": ["business value", "user needs", "acceptance criteria", "scope management", "prioritization"]}'
);

-- Insert default Developer persona
INSERT INTO personas (name, role, prompt_template, active, metadata)
VALUES (
    'Developer',
    'Developer',
    'You are an experienced Developer AI assistant participating in a story refinement session. Your focus is on technical feasibility, implementation approach, and effort estimation.

When analyzing a user story, consider:
- Is the technical implementation clear and feasible?
- Are there architectural implications or dependencies?
- What level of effort is required (story points)?
- Are there technical edge cases or performance considerations?

For this refinement session, focus specifically on:
1. Technical feasibility of implementation
2. Potential technical approaches or solutions
3. Required effort estimation (story points)
4. Technical dependencies or prerequisites
5. Any technical acceptance criteria missing
6. Potential technical risks or challenges

When interacting with other personas, explain technical concepts clearly while respecting their non-technical perspective. Balance technicalANTHROPIC_API_KEY=your-anthropic-api-key

# Database Configuration
DATABASE_URL=postgresql://refinement:refinement@postgres:5432/refinement
REDIS_URL=redis://redis:6379/0

# Security
JWT_SECRET=change-this-to-a-secure-random-string
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOF

# Create DB initialization script directory
mkdir -p scripts
cat > scripts/init-db.sql << EOF
-- Initial database schema

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create stories table
CREATE TABLE stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jira_key TEXT NOT NULL UNIQUE,
    github_issue_number INTEGER,
    title TEXT NOT NULL,
    description TEXT,
    story_points FLOAT,
    status TEXT NOT NULL,
    priority TEXT,
    last_jira_update TIMESTAMP,
    last_github_update TIMESTAMP,
    last_sync TIMESTAMP,
    sync_status TEXT NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create acceptance criteria table
CREATE TABLE acceptance_criteria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create sync_sessions table
CREATE TABLE sync_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    status TEXT NOT NULL DEFAULT 'IN_PROGRESS',
    source TEXT NOT NULL,
    target TEXT NOT NULL,
    items_total INTEGER,
    items_processed INTEGER DEFAULT 0,
    items_succeeded INTEGER DEFAULT 0,
    items_failed INTEGER DEFAULT 0,
    error_message TEXT,
    created_by TEXT
);

-- Create indexes
CREATE INDEX idx_stories_jira_key ON stories(jira_key);
CREATE INDEX idx_stories_github_issue_number ON stories(github_issue_number);
CREATE INDEX idx_acceptance_criteria_story_id ON acceptance_criteria(story_id);
CREATE INDEX idx_sync_sessions_status ON sync_sessions(status);
EOF
```

#### 1.3 Integration Service Setup
```bash
# Create Dockerfile for integration service
cat > integration-service/Dockerfile << EOF
FROM python:3.11-slim

WORKDIR /app

# Install Poetry
RUN pip install poetry==1.5.1

# Copy Poetry configuration
COPY pyproject.toml poetry.lock* /app/

# Configure Poetry
RUN poetry config virtualenvs.create false

# Install dependencies
RUN poetry install --no-interaction --no-ansi --no-root

# Copy application code
COPY . /app/

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Create Poetry configuration
cat > integration-service/pyproject.toml << EOF
[tool.poetry]
name = "integration-service"
version = "0.1.0"
description = "Integration service for Jira-GitHub synchronization"
authors = ["Your Team <team@example.com>"]

[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.104.0"
uvicorn = "^0.23.2"
sqlalchemy = "^2.0.23"
psycopg2-binary = "^2.9.9"
pydantic = "^2.4.2"
pydantic-settings = "^2.0.3"
python-jose = "^3.3.0"
passlib = "^1.7.4"
bcrypt = "^4.0.1"
jira = "^3.5.1"
PyGithub = "^2.1.1"
redis = "^5.0.1"
httpx = "^0.25.1"
python-multipart = "^0.0.6"

[tool.poetry.dev-dependencies]
pytest = "^7.4.3"
pytest-asyncio = "^0.21.1"
pytest-cov = "^4.1.0"
black = "^23.10.1"
isort = "^5.12.0"
mypy = "^1.6.1"
pre-commit = "^3.5.0"

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
target-version = ['py311']

[tool.isort]
profile = "black"
line_length = 88

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
EOF

# Create empty poetry.lock file
touch integration-service/poetry.lock

# Create main application file
mkdir -p integration-service/app
cat > integration-service/app/main.py << EOF
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Integration Service",
    description="API for Jira-GitHub synchronization",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/")
async def root():
    return {
        "service": "Integration Service",
        "version": "0.1.0",
        "status": "running",
    }
EOF

# Create basic service structure
mkdir -p integration-service/app/config
cat > integration-service/app/config/settings.py << EOF
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # Database settings
    DATABASE_URL: str
    
    # Redis settings
    REDIS_URL: str
    
    # Jira settings
    JIRA_BASE_URL: str
    JIRA_API_TOKEN: str
    
    # GitHub settings
    GITHUB_TOKEN: str
    GITHUB_REPOSITORY: str
    
    # Security settings
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    class Config:
        env_file = ".env"


settings = Settings()
EOF
```

#### 1.4 AI Orchestration Service Setup
```bash
# Create Dockerfile for AI orchestration service
cat > ai-orchestration/Dockerfile << EOF
FROM python:3.11-slim

WORKDIR /app

# Install Poetry
RUN pip install poetry==1.5.1

# Copy Poetry configuration
COPY pyproject.toml poetry.lock* /app/

# Configure Poetry
RUN poetry config virtualenvs.create false

# Install dependencies
RUN poetry install --no-interaction --no-ansi --no-root

# Copy application code
COPY . /app/

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Create Poetry configuration
cat > ai-orchestration/pyproject.toml << EOF
[tool.poetry]
name = "ai-orchestration"
version = "0.1.0"
description = "AI orchestration service for story refinement"
authors = ["Your Team <team@example.com>"]

[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.104.0"
uvicorn = "^0.23.2"
sqlalchemy = "^2.0.23"
psycopg2-binary = "^2.9.9"
pydantic = "^2.4.2"
pydantic-settings = "^2.0.3"
anthropic = "^0.5.0"
redis = "^5.0.1"
httpx = "^0.25.1"
python-jose = "^3.3.0"
passlib = "^1.7.4"
bcrypt = "^4.0.1"
python-multipart = "^0.0.6"

[tool.poetry.dev-dependencies]
pytest = "^7.4.3"
pytest-asyncio = "^0.21.1"
pytest-cov = "^4.1.0"
black = "^23.10.1"
isort = "^5.12.0"
mypy = "^1.6.1"
pre-commit = "^3.5.0"

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
target-version = ['py311']

[tool.isort]
profile = "black"
line_length = 88

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
EOF

# Create empty poetry.lock file
touch ai-orchestration/poetry.lock

# Create main application file
mkdir -p ai-orchestration/app
cat > ai-orchestration/app/main.py << EOF
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="AI Orchestration Service",
    description="API for AI-powered story refinement",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/")
async def root():
    return {
        "service": "AI Orchestration Service",
        "version": "0.1.0",
        "status": "running",
    }
EOF

# Create basic service structure
mkdir -p ai-orchestration/app/config
cat > ai-orchestration/app/config/settings.py << EOF
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # Database settings
    DATABASE_URL: str
    
    # Redis settings
    REDIS_URL: str
    
    # Anthropic settings
    ANTHROPIC_API_KEY: str
    
    # Security settings
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    class Config:
        env_file = ".env"


settings = Settings()
EOF
```

#### 1.5 Frontend Setup
```bash
# Create Dockerfile for frontend
cat > frontend/Dockerfile << EOF
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci

# Copy application code
COPY . .

# Build the application for production
RUN npm run build

# Install serve to run the application
RUN npm install -g serve

# Serve the application
CMD ["serve", "-s", "build", "-l", "3000"]
EOF

# Initialize package.json
cat > frontend/package.json << EOF
{
  "name": "frontend",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "@emotion/react": "^11.11.1",
    "@emotion/styled": "^11.11.0",
    "@mui/icons-material": "^5.14.16",
    "@mui/material": "^5.14.16",
    "@testing-library/jest-dom": "^5.17.0",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^13.5.0",
    "axios": "^1.6.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-query": "^3.39.3",
    "react-router-dom": "^6.18.0",
    "react-scripts": "5.0.1",
    "web-vitals": "^2.1.4"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
EOF

# Create basic React application
mkdir -p frontend/src
cat > frontend/src/index.js << EOF
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';

const queryClient = new QueryClient();

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <BrowserRouter>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <App />
        </ThemeProvider>
      </QueryClientProvider>
    </BrowserRouter>
  </React.StrictMode>
);
EOF

cat > frontend/src/App.js << EOF
import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { Box, Container, Typography } from '@mui/material';

// Placeholder components - replace with real implementations
const Dashboard = () => (
  <Box sx={{ mt: 4 }}>
    <Typography variant="h4">Dashboard</Typography>
    <Typography variant="body1" sx={{ mt: 2 }}>
      Welcome to the AI-Powered Scrum Refinement System
    </Typography>
  </Box>
);

const App = () => {
  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Typography variant="h3" component="h1" gutterBottom>
          AI-Powered Scrum Refinement
        </Typography>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          {/* Add more routes as needed */}
        </Routes>
      </Box>
    </Container>
  );
};

export default App;
EOF

# Create public directory and index.html
mkdir -p frontend/public
cat > frontend/public/index.html << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta
      name="description"
      content="AI-Powered Scrum Refinement System"
    />
    <link rel="apple-touch-icon" href="%PUBLIC_URL%/logo192.png" />
    <link rel="manifest" href="%PUBLIC_URL%/manifest.json" />
    <title>AI Scrum Refinement</title>
    <link
      rel="stylesheet"
      href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700&display=swap"
    />
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF

cat > frontend/public/manifest.json << EOF
{
  "short_name": "AI Refinement",
  "name": "AI-Powered Scrum Refinement System",
  "icons": [
    {
      "src": "favicon.ico",
      "sizes": "64x64 32x32 24x24 16x16",
      "type": "image/x-icon"
    }
  ],
  "start_url": ".",
  "display": "standalone",
  "theme_color": "#000000",
  "background_color": "#ffffff"
}
EOF

# Create a simple favicon
echo "Create a favicon.ico file in frontend/public/"
```

### 2. Implement Core Integration Services (Day 3-5)

#### 2.1 Jira Connector Implementation
```bash
# Create Jira connector module
mkdir -p integration-service/app/services
cat > integration-service/app/services/jira_connector.py << EOF
import logging
from typing import List, Dict, Any, Optional
from jira import JIRA
from app.config.settings import settings

logger = logging.getLogger(__name__)

class JiraConnector:
    def __init__(self):
        """Initialize Jira connector with authentication details."""
        self.base_url = settings.JIRA_BASE_URL
        self.auth_token = settings.JIRA_API_TOKEN
        self.client = self._create_client()
        
    def _create_client(self) -> JIRA:
        """Create authenticated Jira client."""
        try:
            return JIRA(
                server=self.base_url,
                token_auth=self.auth_token
            )
        except Exception as e:
            logger.error(f"Failed to create Jira client: {str(e)}")
            raise
        
    async def get_sprint_backlog(self, sprint_id: int) -> List[Dict[str, Any]]:
        """
        Retrieve all stories from a sprint backlog.
        
        Args:
            sprint_id: The ID of the sprint
            
        Returns:
            List of story data dictionaries
        """
        try:
            jql = f"sprint = {sprint_id} ORDER BY rank"
            issues = self.client.search_issues(
                jql,
                maxResults=100,
                fields="summary,description,customfield_10001,status,priority,labels,components,issuelinks"
            )
            
            return [self._transform_issue(issue) for issue in issues]
        except Exception as e:
            logger.error(f"Failed to get sprint backlog: {str(e)}")
            raise
            
    async def get_story_details(self, story_key: str) -> Dict[str, Any]:
        """
        Get detailed information about a specific story.
        
        Args:
            story_key: The Jira key of the story (e.g., PROJ-123)
            
        Returns:
            Story data dictionary
        """
        try:
            issue = self.client.issue(
                story_key,
                fields="summary,description,customfield_10001,status,priority,labels,components,issuelinks,comment,created,updated"
            )
            return self._transform_issue(issue)
        except Exception as e:
            logger.error(f"Failed to get story details: {str(e)}")
            raise
            
    def _transform_issue(self, issue) -> Dict[str, Any]:
        """Transform Jira issue to standard dictionary format."""
        # Extract story points - assumes customfield_10001 is story points
        story_points = getattr(issue.fields, 'customfield_10001', None)
        
        # Extract acceptance criteria - would be customized based on your Jira setup
        # This is just a placeholder
        acceptance_criteria = []
        description = issue.fields.description or ""
        if description and "Acceptance Criteria:" in description:
            ac_section = description.split("Acceptance Criteria:")[1].strip()
            criteria_items = [item.strip() for item in ac_section.split('\n') if item.strip()]
            acceptance_criteria = criteria_items
        
        return {
            "key": issue.key,
            "title": issue.fields.summary,
            "description": description,
            "story_points": story_points,
            "status": issue.fields.status.name,
            "priority": issue.fields.priority.name if hasattr(issue.fields, 'priority') and issue.fields.priority else None,
            "labels": [label for label in issue.fields.labels] if hasattr(issue.fields, 'labels') else [],
            "components": [component.name for component in issue.fields.components] if hasattr(issue.fields, 'components') else [],
            "acceptance_criteria": acceptance_criteria,
            "created": issue.fields.created,
            "updated": issue.fields.updated
        }
EOF

# Create DB models
mkdir -p integration-service/app/models
cat > integration-service/app/models/database.py << EOF
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config.settings import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF

cat > integration-service/app/models/story.py << EOF
from sqlalchemy import Column, String, Float, Integer, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

from .database import Base

class Story(Base):
    __tablename__ = "stories"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    jira_key = Column(String, nullable=False, unique=True)
    github_issue_number = Column(Integer, nullable=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    story_points = Column(Float, nullable=True)
    status = Column(String, nullable=False)
    priority = Column(String, nullable=True)
    last_jira_update = Column(DateTime, nullable=True)
    last_github_update = Column(DateTime, nullable=True)
    last_sync = Column(DateTime, nullable=True)
    sync_status = Column(String, nullable=False, default="PENDING")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    acceptance_criteria = relationship("AcceptanceCriteria", back_populates="story", cascade="all, delete-orphan")


class AcceptanceCriteria(Base):
    __tablename__ = "acceptance_criteria"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    story_id = Column(UUID(as_uuid=True), ForeignKey("stories.id", ondelete="CASCADE"), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String, nullable=False, default="PENDING")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    story = relationship("Story", back_populates="acceptance_criteria")


# Pydantic models for API
class AcceptanceCriteriaCreate(BaseModel):
    description: str
    status: str = "PENDING"


class AcceptanceCriteriaRead(BaseModel):
    id: uuid.UUID
    description: str
    status: str
    
    class Config:
        from_attributes = True


class StoryCreate(BaseModel):
    jira_key: str
    title: str
    description: Optional[str] = None
    story_points: Optional[float] = None
    status: str
    priority: Optional[str] = None
    acceptance_criteria: List[AcceptanceCriteriaCreate] = []


class StoryRead(BaseModel):
    id: uuid.UUID
    jira_key: str
    github_issue_number: Optional[int] = None
    title: str
    description: Optional[str] = None
    story_points: Optional[float] = None
    status: str
    priority: Optional[str] = None
    sync_status: str
    acceptance_criteria: List[AcceptanceCriteriaRead] = []
    
    class Config:
        from_attributes = True


class StoryUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    story_points: Optional[float] = None
    status: Optional[str] = None
    priority: Optional[str] = None
EOF
```

#### 2.2 GitHub Connector Implementation
```bash
# Create GitHub connector module
cat > integration-service/app/services/github_connector.py << EOF
import logging
from typing import Dict, Any, Optional, List
from github import Github, Issue
from app.config.settings import settings

logger = logging.getLogger(__name__)

class GitHubConnector:
    def __init__(self):
        """Initialize GitHub connector with authentication details."""
        self.token = settings.GITHUB_TOKEN
        self.repository_name = settings.GITHUB_REPOSITORY
        self.client = self._create_client()
        self.repo = self._get_repository()
        
    def _create_client(self) -> Github:
        """Create authenticated GitHub client."""
        try:
            return Github(self.token)
        except Exception as e:
            logger.error(f"Failed to create GitHub client: {str(e)}")
            raise
            
    def _get_repository(self):
        """Get the repository object."""
        try:
            return self.client.get_repo(self.repository_name)
        except Exception as e:
            logger.error(f"Failed to get repository: {str(e)}")
            raise
            
    async def create_issue(self, story_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a new issue in GitHub.
        
        Args:
            story_data: Story data including title, description, etc.
            
        Returns:
            Created issue data
        """
        try:
            # Format the body to include metadata and acceptance criteria
            body = self._format_issue_body(story_data)
            
            # Create labels if they don't exist
            labels = await self._ensure_labels_exist(story_data.get("labels", []))
            
            # Create the issue
            issue = self.repo.create_issue(
                title=story_data["title"],
                body=body,
                labels=labels
            )
            
            return self._transform_issue(issue)
        except Exception as e:
            logger.error(f"Failed to create GitHub issue: {str(e)}")
            raise
            
    async def update_issue(self, issue_number: int, story_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Update an existing issue in GitHub.
        
        Args:
            issue_number: The GitHub issue number
            story_data: Updated story data
            
        Returns:
            Updated issue data
        """
        try:
            issue = self.repo.get_issue(issue_number)
            
            # Update fields as needed
            update_data = {}
            
            if "title" in story_data:
                update_data["title"] = story_data["title"]
                
            if "description" in story_data or "acceptance_criteria" in story_data:
                body = self._format_issue_body(story_data)
                update_data["body"] = body
                
            if "labels" in story_data:
                labels = await self._ensure_labels_exist(story_data["labels"])
                update_data["labels"] = labels
                
            # Apply updates
            issue.edit(**update_data)
            
            return self._transform_issue(issue)
        except Exception as e:
            logger.error(f"Failed to update GitHub issue: {str(e)}")
            raise
            
    async def get_issue(self, issue_number: int) -> Dict[str, Any]:
        """
        Get details of a specific GitHub issue.
        
        Args:
            issue_number: The GitHub issue number
            
        Returns:
            Issue data
        """
        try:
            issue = self.repo.get_issue(issue_number)
            return self._transform_issue(issue)
        except Exception as e:
            logger.error(f"Failed to get GitHub issue: {str(e)}")
            raise
            
    async def _ensure_labels_exist(self, label_names: List[str]) -> List[str]:
        """
        Ensure all required labels exist in the repository.
        
        Args:
            label_names: List of label names
            
        Returns:
            List of verified label names
        """
        try:
            existing_labels = {label.name: label for label in self.repo.get_labels()}
            
            for label_name in label_names:
                if label_name not in existing_labels:
                    # Create label if it doesn't exist
                    self.repo.create_label(name=label_name, color="bfdadc")
                    
            return label_names
        except Exception as e:
            logger.error(f"Failed to ensure labels exist: {str(e)}")
            raise
                
    def _format_issue_body(self, story_data: Dict[str, Any]) -> str:
        """Format the issue body with metadata and structured content."""
        # Start with description
        body = story_data.get("description", "") or ""
        
        # Add metadata section (hidden in HTML comment)
        body += f"\n\n<!-- METADATA\n"
        body += f"jira_key: {story_data.get('jira_key', '')}\n"
        body += f"story_points: {story_data.get('story_points', '')}\n"
        body += f"status: {story_data.get('status', '')}\n"
        body += f"priority: {story_data.get('priority', '')}\n"
        body += f"-->\n\n"
        
        # Add acceptance criteria section
        if story_data.get("acceptance_criteria"):
            body += "## Acceptance Criteria\n\n"
            for criteria in story_data["acceptance_criteria"]:
                body += f"- [ ] {criteria}\n"
                
        return body
            
    def _transform_issue(self, issue: Issue) -> Dict[str, Any]:
        """Transform GitHub issue to standard dictionary format."""
        # Extract metadata from body
        metadata = self._extract_metadata(issue.body or "")
        
        # Extract acceptance criteria
        acceptance_criteria = []
        body = issue.body or ""
        if "## Acceptance Criteria" in body:
            ac_section = body.split("## Acceptance Criteria")[1].strip()
            criteria_lines = [line.strip() for line in ac_section.split('\n') if line.strip().startswith('- [ ]') or line.strip().# Getting Started Implementation Guide
## AI-Powered Scrum Refinement System

This guide provides concrete steps to begin implementing the AI-Powered Scrum Refinement System. It focuses on the critical first steps to establish a foundation and build momentum.

## Immediate Next Steps

### 1. Set Up Project Infrastructure (Day 1-2)

#### 1.1 Repository Setup
```bash
# Create the GitHub repository
git init ai-scrum-refinement
cd ai-scrum-refinement

# Create basic directory structure
mkdir -p integration-service/app/{api,models,services,utils}
mkdir -p ai-orchestration/app/{api,models,services,utils}
mkdir -p frontend/src/{components,pages,services,utils}
mkdir -p k8s/{base,overlays/{dev,staging,prod}}
mkdir -p docs/{user,admin,api}

# Create initial README
cat > README.md << EOF
# AI-Powered Scrum Refinement System

Automated Jira-GitHub integration with AI-powered story refinement.

## Overview

This system automates the Scrum refinement process by:
1. Exporting Jira stories to GitHub
2. Facilitating AI-powered refinement sessions
3. Synchronizing refined stories back to Jira

## Documentation

See the [docs](./docs) directory for detailed documentation.

## Getting Started

See [DEVELOPMENT.md](./DEVELOPMENT.md) for setup instructions.
EOF

# Create initial .gitignore
cat > .gitignore << EOF
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Node.js
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
.pnpm-debug.log
.yarn-integrity
.env.local
.env.development.local
.env.test.local
.env.production.local

# Environment variables
.env
.env.*
!.env.example

# IDE
.idea/
.vscode/
*.swp
*.swo

# Docker
.docker/

# Misc
.DS_Store
.coverage
htmlcov/
.pytest_cache/
EOF

# Initial commit
git add .
git commit -m "Initial project structure"
```

#### 1.2 Docker Environment Setup
```bash
# Create Docker Compose configuration
cat > docker-compose.yml << EOF
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: refinement
      POSTGRES_PASSWORD: refinement
      POSTGRES_DB: refinement
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
      
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
      
  integration-service:
    build:
      context: ./integration-service
      dockerfile: Dockerfile
    volumes:
      - ./integration-service:/app
    environment:
      DATABASE_URL: postgresql://refinement:refinement@postgres:5432/refinement
      REDIS_URL: redis://redis:6379/0
      JIRA_BASE_URL: \${JIRA_BASE_URL}
      JIRA_API_TOKEN: \${JIRA_API_TOKEN}
      GITHUB_TOKEN: \${GITHUB_TOKEN}
      GITHUB_REPOSITORY: \${GITHUB_REPOSITORY}
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - redis
      
  ai-orchestration:
    build:
      context: ./ai-orchestration
      dockerfile: Dockerfile
    volumes:
      - ./ai-orchestration:/app
    environment:
      DATABASE_URL: postgresql://refinement:refinement@postgres:5432/refinement
      REDIS_URL: redis://redis:6379/0
      ANTHROPIC_API_KEY: \${ANTHROPIC_API_KEY}
    ports:
      - "8001:8000"
    depends_on:
      - postgres
      - redis
      
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    volumes:
      - ./frontend:/app
    ports:
      - "3000:3000"
    environment:
      REACT_APP_API_URL: http://localhost:8000/api
      REACT_APP_AI_API_URL: http://localhost:8001/api
      
volumes:
  postgres-data:
  redis-data:
EOF

# Create example environment file
cat > .env.example << EOF
# Jira Configuration
JIRA_BASE_URL=https://your-org.atlassian.net
JIRA_API_TOKEN=your-jira-api-token

# GitHub Configuration
GITHUB_TOKEN=your-github-token
GITHUB_REPOSITORY=your-org/your-repo

# AI Configuration
ANTHROPIC_API_KEY=your-anthropic-