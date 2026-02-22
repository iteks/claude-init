---
paths:
  - "app/api/**"
  - "app/routers/**"
  - "app/schemas/**"
  - "routers/**"
  - "schemas/**"
---

# API Conventions

## Router Organization

- Use `APIRouter` with `prefix` and `tags` for grouping endpoints
- Bind routers in `main.py` with `app.include_router()`
- Keep route handlers thin — extract business logic into service functions

```python
# routers/users.py
from fastapi import APIRouter

router = APIRouter(
    prefix="/users",
    tags=["users"],
)

@router.get("/", response_model=list[UserResponse])
async def list_users():
    return await user_service.list_users()
```

## Pydantic Models for Request/Response Schemas

- All schema models extend `BaseModel` from Pydantic
- Use **snake_case** for all field names (FastAPI auto-converts to camelCase in JSON if configured)
- Define separate models for requests and responses (e.g., `UserCreate`, `UserUpdate`, `UserResponse`)
- Use `Field()` for validation, defaults, and descriptions

```python
# schemas/user.py
from pydantic import BaseModel, Field

class UserCreate(BaseModel):
    email: str = Field(..., description="User email address")
    name: str = Field(..., min_length=1, max_length=255)
    age: int | None = Field(None, ge=0, le=150)

class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
```

## Dependency Injection Patterns

- Use `Depends()` for reusable dependencies (database sessions, auth, pagination)
- Extract common logic into dependency functions
- Type hint dependencies for automatic validation

```python
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
    )
    # Verify token, return user
    ...

@router.get("/me", response_model=UserResponse)
async def read_current_user(
    current_user: User = Depends(get_current_user)
):
    return current_user
```

## Error Handling

Always use `HTTPException` with proper status codes:

```python
from fastapi import HTTPException, status

# 401 — Invalid credentials
raise HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Incorrect username or password",
    headers={"WWW-Authenticate": "Bearer"},
)

# 403 — Forbidden
raise HTTPException(
    status_code=status.HTTP_403_FORBIDDEN,
    detail="Not enough permissions",
)

# 404 — Not found
raise HTTPException(
    status_code=status.HTTP_404_NOT_FOUND,
    detail="User not found",
)

# 422 — Validation error (automatically handled by Pydantic)
# No need to raise manually for request body validation
```

For custom error responses, define exception handlers:

```python
@app.exception_handler(CustomException)
async def custom_exception_handler(request: Request, exc: CustomException):
    return JSONResponse(
        status_code=400,
        content={
            "error": exc.message,
            "code": exc.error_code,
        },
    )
```

## Response Models

- Use `response_model` parameter on route decorators to enforce response schema
- Use `response_model_exclude_unset=True` to omit fields with default values
- Use `status_code` parameter for non-200 success responses

```python
@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    return await user_service.create_user(db, user)

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: Session = Depends(get_db)
):
    user = await user_service.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

## Path and Query Parameter Typing

- Use type hints for automatic validation and OpenAPI documentation
- Use `Path()` for path parameters with validation
- Use `Query()` for query parameters with validation, defaults, and descriptions

```python
from fastapi import Path, Query

@router.get("/{user_id}")
async def get_user(
    user_id: int = Path(..., gt=0, description="The ID of the user"),
    include_posts: bool = Query(False, description="Include user posts"),
    limit: int = Query(10, ge=1, le=100),
):
    ...
```

## Authentication

- Use `OAuth2PasswordBearer` or `HTTPBearer` for token authentication
- Extract token validation into a reusable dependency
- Protected routes use `current_user: User = Depends(get_current_user)`

```python
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    token = credentials.credentials
    # Validate token, return user
    ...
```

## General Practices

- Return type hints on all route handlers (even `-> None` for 204 responses)
- Use `async def` for route handlers when using async ORMs or I/O operations
- Use `def` (sync) for CPU-bound operations or sync database drivers
- Group related endpoints in the same router file
- Use tags consistently across routers for OpenAPI grouping
- Document endpoints with docstrings — FastAPI includes them in OpenAPI schema
