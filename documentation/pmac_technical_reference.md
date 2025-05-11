# Technical Quick Reference Guide
## AI-Powered Scrum Refinement System

This quick reference guide provides essential technical information for developers working on the AI-Powered Scrum Refinement System. Use this as a go-to resource for coding standards, architecture details, and implementation patterns.

## Table of Contents
1. [Technology Stack](#1-technology-stack)
2. [Code Organization](#2-code-organization)
3. [API Design Patterns](#3-api-design-patterns)
4. [Database Models](#4-database-models)
5. [Authentication](#5-authentication)
6. [Error Handling](#6-error-handling)
7. [Testing Approach](#7-testing-approach)
8. [AI Integration](#8-ai-integration)
9. [Common Code Snippets](#9-common-code-snippets)
10. [Troubleshooting](#10-troubleshooting)

## 1. Technology Stack

### Backend
- **Language**: Python 3.11+
- **Web Framework**: FastAPI 0.104.0+
- **ORM**: SQLAlchemy 2.0+
- **API Documentation**: OpenAPI/Swagger via FastAPI
- **Task Queue**: Redis with Celery (for async operations)
- **Authentication**: JWT tokens

### Frontend
- **Language**: TypeScript 5.0+
- **Framework**: React 18.0+
- **UI Library**: Material UI 5.0+
- **State Management**: React Query for server state, Context API for local state
- **Routing**: React Router 6.0+
- **API Client**: Axios

### Database
- **Primary DB**: PostgreSQL 15+
- **Caching**: Redis 7+

### DevOps
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana

## 2. Code Organization

### Integration Service Structure
```
integration-service/
├── app/
│   ├── api/
│   │   ├── routes/         # API endpoint definitions
│   │   └── dependencies.py # Shared API dependencies
│   ├── config/             # Configuration and settings
│   ├── models/             # Database models
│   ├── services/           # Business logic services
│   │   ├── jira/           # Jira integration
│   │   └── github/         # GitHub integration
│   ├── utils/              # Utility functions
│   └── main.py             # Application entrypoint
├── tests/                  # Test suite
├── Dockerfile              # Container definition
├── poetry.lock             # Locked dependencies
└── pyproject.toml          # Project configuration
```

### AI Orchestration Service Structure
```
ai-orchestration/
├── app/
│   ├── api/
│   │   ├── routes/         # API endpoint definitions
│   │   └── dependencies.py # Shared API dependencies
│   ├── config/             # Configuration and settings
│   ├── models/             # Database models
│   ├── services/
│   │   ├── ai/             # AI service integration
│   │   ├── personas/       # Persona management
│   │   └── conversation/   # Conversation orchestration
│   ├── utils/              # Utility functions
│   └── main.py             # Application entrypoint
├── tests/                  # Test suite
├── Dockerfile              # Container definition
├── poetry.lock             # Locked dependencies
└── pyproject.toml          # Project configuration
```

### Frontend Structure
```
frontend/
├── public/                 # Static assets
├── src/
│   ├── components/         # Reusable UI components
│   ├── pages/              # Page components
│   ├── services/           # API clients
│   ├── hooks/              # Custom React hooks
│   ├── utils/              # Utility functions
│   ├── types/              # TypeScript type definitions
│   ├── App.tsx             # Main application component
│   └── index.tsx           # Application entrypoint
├── tests/                  # Test suite
├── Dockerfile              # Container definition
├── package.json            # Project configuration
└── tsconfig.json           # TypeScript configuration
```

## 3. API Design Patterns

### RESTful Endpoint Structure

All API endpoints should follow this pattern:

- Collection endpoints: `/api/resource`
  - GET: List resources
  - POST: Create a new resource

- Instance endpoints: `/api/resource/{id}`
  - GET: Get a specific resource
  - PUT: Update a resource
  - DELETE: Delete a resource

- Related endpoints: `/api/resource/{id}/related`
  - GET: List related resources

### Response Structure

All API responses should follow this structure:

```json
{
  "data": [...],           // Response data
  "meta": {                // Metadata
    "pagination": {
      "page": 1,
      "size": 10,
      "total": 100
    }
  },
  "error": null            // Null when no error
}
```

Error responses:

```json
{
  "data": null,
  "meta": {},
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [...]
  }
}
```

### API Versioning

API versioning is in the URL path: `/api/v1/resource`

### Pagination

All list endpoints should support pagination with these query parameters:
- `page`: Page number (default: 1)
- `size`: Page size (default: 20, max: 100)

## 4. Database Models

### Key Database Models

#### Integration Service

**Story Model**
```python
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
```

**AcceptanceCriteria Model**
```python
class AcceptanceCriteria(Base):
    __tablename__ = "acceptance_criteria"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    story_id = Column(UUID(as_uuid=True), ForeignKey("stories.id", ondelete="CASCADE"), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String, nullable=False, default="PENDING")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    story = relationship("Story", back_populates="acceptance_criteria")
```

#### AI Orchestration Service

**Persona Model**
```python
class Persona(Base):
    __tablename__ = "personas"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    role = Column(String, nullable=False)
    prompt_template = Column(Text, nullable=False)
    active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    metadata = Column(JSONB, nullable=True)
```

### Database Migration

We use Alembic for database migrations:

```bash
# Create a new migration
alembic revision --autogenerate -m "Add new table"

# Run migrations
alembic upgrade head
```

## 5. Authentication

### JWT Authentication

We use JWT tokens for authentication:

```python
# Creating a token
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

# Using token in FastAPI
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    # Get user from database
    user = await get_user(username)
    if user is None:
        raise credentials_exception
    return user
```

### API Token Management

External API tokens (Jira, GitHub, etc.) are stored securely:

1. Environment variables for local development
2. Kubernetes secrets for production
3. Never log or expose tokens in responses

## 6. Error Handling

### Backend Error Handling

Use FastAPI's exception handling:

```python
# Custom exception classes
class NotFoundError(Exception):
    pass

class ValidationError(Exception):
    def __init__(self, errors: List[Dict[str, Any]]):
        self.errors = errors

# Exception handlers
@app.exception_handler(NotFoundError)
async def not_found_exception_handler(request: Request, exc: NotFoundError):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"data": None, "meta": {}, "error": {"code": "NOT_FOUND", "message": str(exc)}},
    )

@app.exception_handler(ValidationError)
async def validation_exception_handler(request: Request, exc: ValidationError):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"data": None, "meta": {}, "error": {"code": "VALIDATION_ERROR", "message": "Validation error", "details": exc.errors}},
    )
```

### Frontend Error Handling

Use React Query error handling:

```typescript
const { data, error, isLoading } = useQuery(
  ['story', storyId], 
  () => api.getStory(storyId),
  {
    onError: (error) => {
      // Handle specific errors
      if (error.response?.status === 404) {
        setNotFound(true);
      } else {
        // Show generic error message
        toast.error('Failed to load story');
      }
    }
  }
);
```

## 7. Testing Approach

### Backend Testing

We use pytest for backend testing:

```python
# Unit test example
def test_transform_jira_to_internal():
    # Given
    jira_issue = create_mock_jira_issue()
    
    # When
    result = transform_jira_to_internal(jira_issue)
    
    # Then
    assert result["jira_key"] == jira_issue.key
    assert result["title"] == jira_issue.fields.summary
    assert result["story_points"] == jira_issue.fields.customfield_10001

# Integration test example
async def test_get_story(client, db, create_test_story):
    # Given
    story = await create_test_story()
    
    # When
    response = await client.get(f"/api/stories/{story.id}")
    
    # Then
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["jira_key"] == story.jira_key
```

### Frontend Testing

We use React Testing Library for frontend testing:

```typescript
// Component test example
test('renders story card with title', () => {
  const story = {
    id: '123',
    title: 'Test Story',
    jira_key: 'PROJ-123',
    status: 'To Do'
  };
  
  render(<StoryCard story={story} />);
  
  expect(screen.getByText('Test Story')).toBeInTheDocument();
  expect(screen.getByText('PROJ-123')).toBeInTheDocument();
});
```

## 8. AI Integration

### Claude API Integration

Basic usage:

```python
from anthropic import Anthropic

async def analyze_story(story_data, persona_prompt):
    client = Anthropic(api_key=settings.ANTHROPIC_API_KEY)
    
    # Format story for prompt
    story_content = f"""
    # {story_data['title']}
    
    **Status:** {story_data['status']}
    **Points:** {story_data['story_points']}
    
    ## Description
    {story_data['description']}
    
    ## Acceptance Criteria
    """
    
    for ac in story_data['acceptance_criteria']:
        story_content += f"- {ac['description']}\n"
    
    # Call Claude API
    response = await client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=2000,
        temperature=0.2,
        system=persona_prompt,
        messages=[
            {"role": "user", "content": f"Please analyze this user story:\n\n{story_content}"}
        ]
    )
    
    return response
```

### Prompt Template Variables

Standard variables for prompt templates:

- `{story_title}`: The title of the story
- `{story_description}`: The full description
- `{acceptance_criteria}`: Formatted acceptance criteria
- `{story_points}`: Current story point estimate
- `{status}`: Current status
- `{priority}`: Current priority
- `{jira_key}`: Jira identifier

### Conversation Management

Basic conversation flow:

```python
async def simulate_conversation(story_data, personas, history=None):
    """
    Simulate a conversation between AI personas about a story.
    
    Args:
        story_data: Dictionary containing story information
        personas: List of persona configurations
        history: Optional conversation history
    
    Returns:
        The next conversation turn and updated history
    """
    history = history or []
    
    # Determine which persona should speak next
    next_persona = select_next_speaker(personas, history)
    
    # Format the prompt with conversation history
    messages = []
    
    # Add story context for the first message
    if not history:
        story_content = format_story_content(story_data)
        messages.append({
            "role": "user",
            "content": f"Here is the user story to refine:\n\n{story_content}"
        })
    else:
        # Add previous conversation turns
        for turn in history:
            role = "assistant" if turn.get("is_ai") else "user"
            messages.append({
                "role": role,
                "content": turn["content"]
            })
        
        # Add instruction for next turn
        messages.append({
            "role": "user",
            "content": f"Continue the refinement discussion as the {next_persona['role']} persona. Respond to the previous comments and provide your perspective."
        })
    
    # Call the AI service
    client = Anthropic(api_key=settings.ANTHROPIC_API_KEY)
    response = await client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=2000,
        temperature=0.3,
        system=next_persona["prompt_template"],
        messages=messages
    )
    
    # Format the response
    turn = {
        "content": response.content[0].text,
        "persona_id": next_persona["id"],
        "persona_name": next_persona["name"],
        "persona_role": next_persona["role"],
        "is_ai": True,
        "timestamp": datetime.utcnow().isoformat()
    }
    
    # Update history
    updated_history = history + [turn]
    
    return turn, updated_history
```

## 9. Common Code Snippets

### Database Session Management

```python
# In FastAPI dependency
from fastapi import Depends
from sqlalchemy.orm import Session
from app.models.database import SessionLocal

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Using in endpoint
@router.get("/stories/{story_id}")
async def get_story(story_id: uuid.UUID, db: Session = Depends(get_db)):
    story = db.query(Story).filter(Story.id == story_id).first()
    if not story:
        raise HTTPException(status_code=404, detail="Story not found")
    return story
```

### Pagination Implementation

```python
# Pagination schema
class PaginationParams(BaseModel):
    page: int = 1
    size: int = 20
    
    @validator('size')
    def size_must_be_valid(cls, v):
        if v < 1:
            return 1
        if v > 100:
            return 100
        return v
    
    @validator('page')
    def page_must_be_positive(cls, v):
        if v < 1:
            return 1
        return v

# In endpoint
@router.get("/stories")
async def list_stories(
    pagination: PaginationParams = Depends(),
    db: Session = Depends(get_db)
):
    skip = (pagination.page - 1) * pagination.size
    
    # Get stories with pagination
    stories = db.query(Story).offset(skip).limit(pagination.size).all()
    
    # Get total count
    total = db.query(Story).count()
    
    # Return with pagination metadata
    return {
        "data": stories,
        "meta": {
            "pagination": {
                "page": pagination.page,
                "size": pagination.size,
                "total": total,
                "pages": math.ceil(total / pagination.size)
            }
        }
    }
```

### Frontend API Client

```typescript
// api.ts
import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.REACT_APP_API_URL || '/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth token to requests
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle common errors
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    // Handle 401 Unauthorized
    if (error.response?.status === 401) {
      // Redirect to login
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// API methods
export const api = {
  // Stories
  getStories: async (page = 1, size = 20) => {
    const response = await apiClient.get(`/stories?page=${page}&size=${size}`);
    return response.data;
  },
  
  getStory: async (id) => {
    const response = await apiClient.get(`/stories/${id}`);
    return response.data;
  },
  
  createStory: async (storyData) => {
    const response = await apiClient.post('/stories', storyData);
    return response.data;
  },
  
  updateStory: async (id, storyData) => {
    const response = await apiClient.put(`/stories/${id}`, storyData);
    return response.data;
  },
  
  // Import from Jira
  importFromJira: async (jiraKey, createGithubIssue = false) => {
    const response = await apiClient.post(`/stories/from-jira/${jiraKey}`, {
      create_github_issue: createGithubIssue
    });
    return response.data;
  },
  
  // AI Refinement
  startRefinement: async (storyId) => {
    const response = await apiClient.post(`/refinement/start`, { story_id: storyId });
    return response.data;
  },
  
  getRefinementSession: async (sessionId) => {
    const response = await apiClient.get(`/refinement/${sessionId}`);
    return response.data;
  },
  
  addRefinementMessage: async (sessionId, message) => {
    const response = await apiClient.post(`/refinement/${sessionId}/message`, { content: message });
    return response.data;
  }
};
```

### React Query Hook Example

```typescript
// useStories.ts
import { useQuery, useMutation, useQueryClient } from 'react-query';
import { api } from '../services/api';

export function useStories(page = 1, size = 20) {
  return useQuery(
    ['stories', page, size],
    () => api.getStories(page, size),
    {
      keepPreviousData: true,
    }
  );
}

export function useStory(id) {
  return useQuery(
    ['story', id],
    () => api.getStory(id),
    {
      enabled: !!id, // Only run if id exists
    }
  );
}

export function useCreateStory() {
  const queryClient = useQueryClient();
  
  return useMutation(
    (storyData) => api.createStory(storyData),
    {
      onSuccess: () => {
        // Invalidate stories cache to trigger refetch
        queryClient.invalidateQueries('stories');
      },
    }
  );
}

export function useUpdateStory() {
  const queryClient = useQueryClient();
  
  return useMutation(
    ({ id, data }) => api.updateStory(id, data),
    {
      onSuccess: (data, variables) => {
        // Update cache for this specific story
        queryClient.setQueryData(['story', variables.id], data);
        // Invalidate stories list
        queryClient.invalidateQueries('stories');
      },
    }
  );
}
```

## 10. Troubleshooting

### Common Issues and Solutions

#### Docker Environment Issues

**Issue**: Services can't connect to PostgreSQL  
**Solution**: Check the database connection string, ensure the host is `postgres` not `localhost`.

**Issue**: Changes not appearing in Docker development environment  
**Solution**: Ensure volumes are properly mounted in docker-compose.yml.

#### API Connection Issues

**Issue**: Authentication failures with Jira/GitHub  
**Solutions**:
- Verify API token permissions
- Check token expiration
- Ensure correct API URL
- Check network connectivity
- Look for rate limiting

#### Database Issues

**Issue**: Alembic migrations failing  
**Solutions**:
- Check current database state with `alembic current`
- Run manual revision with `alembic revision --autogenerate`
- Fix migration scripts for type compatibility

#### AI Service Issues

**Issue**: Claude API returning errors  
**Solutions**:
- Verify API key is valid
- Check for rate limiting (429 errors)
- Ensure prompt is within token limits
- Check for restricted content in prompts

### Logging and Debugging

#### Backend Logging

```python
import logging

logger = logging.getLogger(__name__)

# Usage
logger.debug("Detailed information for debugging")
logger.info("General information about operation")
logger.warning("Unexpected event occurred, but operation continues")
logger.error("Operation failed due to error")
logger.critical("System is in an unusable state")
```

#### Frontend Debugging

- Use React DevTools for component debugging
- Use Network tab in browser dev tools for API issues
- Add temporary debug logging with `console.log()` but remove before committing

### Support Resources

- Project Documentation: [Wiki URL]
- API Documentation: [API Docs URL]
- Error Codes Reference: [Error Codes URL]
- Team Slack Channel: #ai-refinement-help