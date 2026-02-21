# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Stack

- Python {{PYTHON_VERSION}} / FastAPI {{FASTAPI_VERSION}}
- Database: {{DATABASE}}
- Testing: pytest + httpx
- Formatting: {{FORMATTER}}
- Package Manager: {{PACKAGE_MANAGER}}

## Local Development

- **Dev**: `uvicorn {{PROJECT_SLUG}}.main:app --reload`
- **Tests**: `pytest`
- **Format**: `{{FORMAT_COMMAND}}`
- **Docs**: `http://localhost:8000/docs` (Swagger UI)

## Architecture

{{ARCHITECTURE_NOTES}}

### Key Directories

| Directory | Purpose |
|---|---|
| `{{PROJECT_SLUG}}/` | Application package |
| `{{PROJECT_SLUG}}/routers/` | Route handlers |
| `{{PROJECT_SLUG}}/models/` | Pydantic models and DB models |
| `{{PROJECT_SLUG}}/services/` | Business logic |
| `tests/` | Test files |

## Conventions

- **Indentation**: 4 spaces (PEP 8)
- **Imports**: isort ordering (stdlib, third-party, local)
- **Type hints**: Required on all function signatures
- **Models**: Use Pydantic BaseModel for request/response schemas
- **Dependencies**: Use FastAPI's Depends() for dependency injection
- **Async**: Prefer async def for I/O-bound route handlers

## Workflow Automation

### Task Assessment

Use `EnterPlanMode` for any task that:
- Touches 2+ files
- Creates a new router, model, or service
- Involves refactoring across modules

### Post-Implementation

After modifying 2+ files:
- Offer to run `pytest --tb=short`
- Offer to run `{{FORMAT_COMMAND}}`
- Offer a code review via the security-reviewer agent

### Context Management

- After completing a unit of work, suggest `/compact`
- After 5+ exchanges on different topics, suggest `/clear`

## Things to Watch For

- **Input validation**: Use Pydantic models for all request bodies; never trust raw input
- **Authentication**: Ensure protected routes use proper dependency injection
- **Async safety**: Don't mix sync and async database calls
- **Error handling**: Use HTTPException with appropriate status codes
- **Environment**: Use pydantic-settings for configuration, never hardcode secrets
