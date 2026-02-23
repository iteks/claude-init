---
description: Scaffold a new Laravel API endpoint with route, controller, resource, form request, and tests. Invoke with /new-api-endpoint followed by the resource name.
---

# New API Endpoint

Create a complete Laravel API endpoint for "$ARGUMENTS".

## Workflow

### 1. Detect API Structure

Before scaffolding, scan the project to determine:
- **API route file**: Look for `routes/api.php`, `routes/api/v2.php`, `routes/api/v1.php`, or similar
- **API namespace**: Look for existing controllers in `app/Http/Controllers/Api/` — detect if they use versioned subdirectories (`V1/`, `V2/`) or a flat structure
- **Existing patterns**: Read 1-2 existing API controllers, resources, and form requests to match the project's conventions

Use the detected structure for all file paths below. If no API structure exists, default to `app/Http/Controllers/Api/`.

### 2. Plan the Endpoint

Determine the resource structure:
- **Resource name**: $ARGUMENTS (singular, PascalCase)
- **Route prefix**: `/{resource}` (pluralized, kebab-case) in the detected route file
- **HTTP methods**: Decide which CRUD operations are needed (index, show, store, update, destroy)
- Ask the user to confirm or adjust before proceeding

### 3. Create the Route

Add routes to the detected API route file:

```php
Route::apiResource('{{RESOURCE_PLURAL}}', {{RESOURCE_NAME}}Controller::class);
```

Or individual routes if only specific methods are needed.

### 4. Create the Controller

Create the controller in the detected API controller namespace:
- Extend the base API controller
- Implement only the methods defined in step 2
- Use form request validation for store/update
- Return API resources for consistent response shapes
- Follow existing controller patterns in the project

### 5. Create the Form Request

Create the form request in the detected API request namespace:
- Define validation rules for store/update
- Use `authorize()` for authorization logic
- Follow existing form request patterns

### 6. Create the API Resource

Create the API resource in the detected API resource namespace:
- Define the response shape in `toArray()`
- Use snake_case keys for JSON output
- Include only necessary fields
- Follow existing resource patterns

### 7. Create Tests

Create the test file following existing test directory structure:
- Use Pest `describe`/`it` syntax
- Test each endpoint method (index, show, store, update, destroy)
- Test validation rules
- Test authorization
- Use model factories for test data
- Follow existing test patterns in the project

### 8. Verify

- Run the new tests: `php artisan test --compact --filter={{RESOURCE_NAME}}`
- Check route registration: `php artisan route:list --path={{RESOURCE_PLURAL}}`
- Verify no lint errors: `./vendor/bin/{{FORMATTER_COMMAND}}`

## Output

After completing all steps, report:
- Files created (with paths)
- Routes registered
- Test results
