---
description: Scaffold a new Laravel API endpoint with route, controller, resource, form request, and tests. Invoke with /new-api-endpoint followed by the resource name.
---

# New API Endpoint

Create a complete Laravel API endpoint for "$ARGUMENTS".

## Workflow

### 1. Plan the Endpoint

Determine the resource structure:
- **Resource name**: $ARGUMENTS (singular, PascalCase)
- **Route prefix**: `/api/v2/{resource}` (pluralized, kebab-case)
- **HTTP methods**: Decide which CRUD operations are needed (index, show, store, update, destroy)
- Ask the user to confirm or adjust before proceeding

### 2. Create the Route

Add routes to the appropriate API route file (typically `routes/api/v2.php` or `routes/api.php`):

```php
Route::apiResource('{{RESOURCE_PLURAL}}', {{RESOURCE_NAME}}Controller::class);
```

Or individual routes if only specific methods are needed.

### 3. Create the Controller

Create `app/Http/Controllers/Api/V2/{{RESOURCE_NAME}}Controller.php`:
- Extend the base API controller
- Implement only the methods defined in step 1
- Use form request validation for store/update
- Return API resources for consistent response shapes
- Follow existing controller patterns in the project

### 4. Create the Form Request

Create `app/Http/Requests/Api/V2/{{RESOURCE_NAME}}Request.php`:
- Define validation rules for store/update
- Use `authorize()` for authorization logic
- Follow existing form request patterns

### 5. Create the API Resource

Create `app/Http/Resources/Api/V2/{{RESOURCE_NAME}}Resource.php`:
- Define the response shape in `toArray()`
- Use snake_case keys for JSON output
- Include only necessary fields
- Follow existing resource patterns

### 6. Create Tests

Create `tests/Feature/Api/V2/{{RESOURCE_NAME}}Test.php`:
- Use Pest `describe`/`it` syntax
- Test each endpoint method (index, show, store, update, destroy)
- Test validation rules
- Test authorization
- Use model factories for test data
- Follow existing test patterns in the project

### 7. Verify

- Run the new tests: `php artisan test --compact --filter={{RESOURCE_NAME}}`
- Check route registration: `php artisan route:list --path={{RESOURCE_PLURAL}}`
- Verify no lint errors: `./vendor/bin/{{FORMATTER_COMMAND}} lint`

## Output

After completing all steps, report:
- Files created (with paths)
- Routes registered
- Test results
