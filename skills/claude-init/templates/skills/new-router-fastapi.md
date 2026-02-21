---
description: Scaffold a new FastAPI router with models, schemas, service layer, and tests. Invoke with /new-router followed by the resource name.
---

# New FastAPI Router

Create a new FastAPI router for "$ARGUMENTS".

## Workflow

### 1. Plan the Router

Determine the router structure:
- **Resource name**: $ARGUMENTS (lowercase, snake_case)
- **Endpoints**: Ask the user which CRUD operations are needed (list, get, create, update, delete)
- **Database model**: Ask if a new SQLAlchemy/Tortoise model is needed
- **Authentication**: Ask if endpoints require authentication
- Ask the user to confirm before proceeding

### 2. Create the Pydantic Schemas

Create `schemas/$ARGUMENTS.py` (or follow project's schema directory convention):
- `{{RESOURCE_NAME}}Base` — shared fields
- `{{RESOURCE_NAME}}Create` — fields for creation (inherits Base)
- `{{RESOURCE_NAME}}Update` — fields for update (all optional)
- `{{RESOURCE_NAME}}Response` — response shape (inherits Base, adds id + timestamps)
- Use proper Pydantic v2 field types and validators
- Follow existing schema patterns

### 3. Create the Database Model (if needed)

Create `models/$ARGUMENTS.py`:
- Define SQLAlchemy model with proper column types
- Add relationships with `relationship()` and foreign keys
- Include `__tablename__` following project naming convention
- Follow existing model patterns

### 4. Create the Service Layer

Create `services/$ARGUMENTS.py`:
- Implement CRUD operations as async functions
- Accept database session as parameter
- Use proper error handling (raise HTTPException for not found, etc.)
- Follow existing service patterns

### 5. Create the Router

Create `routers/$ARGUMENTS.py`:
- Define `router = APIRouter(prefix="/$ARGUMENTS", tags=["$ARGUMENTS"])`
- Implement endpoint functions calling the service layer
- Use proper status codes (201 for create, 204 for delete)
- Add response_model for type safety
- Use Depends() for database session and authentication
- Follow existing router patterns

### 6. Register the Router

Add the new router to the main FastAPI app:
```python
app.include_router(router)
```

### 7. Create Tests

Create `tests/test_$ARGUMENTS.py`:
- Use {{TEST_FRAMEWORK}} with httpx AsyncClient
- Test each endpoint (list, get, create, update, delete)
- Test validation errors (422 responses)
- Test not-found cases (404 responses)
- Test authentication if required
- Use factories or fixtures for test data
- Follow existing test patterns

### 8. Verify

- Run tests: `python -m pytest tests/test_$ARGUMENTS.py -v`
- Check for lint errors: `ruff check .`
- Verify the new routes: start the app and check `/docs`

## Output

After completing all steps, report:
- Files created (with paths)
- Endpoints registered (method, path, description)
- Test results
