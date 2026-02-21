---
description: Scaffold a new Django app with models, views, URLs, serializers, and tests. Invoke with /new-django-app followed by the app name.
---

# New Django App

Create a new Django app named "$ARGUMENTS".

## Workflow

### 1. Plan the App

Determine the app structure:
- **App name**: $ARGUMENTS (lowercase, snake_case)
- **Models**: Ask the user what models this app needs
- **API endpoints**: Ask if this app needs API endpoints (DRF serializers + views)
- **Admin**: Ask if models need admin panel registration
- Ask the user to confirm before proceeding

### 2. Create the App

Run `python manage.py startapp $ARGUMENTS` to scaffold the basic structure.

### 3. Register the App

Add `'$ARGUMENTS'` (or `'$ARGUMENTS.apps.{{APP_CONFIG_NAME}}'`) to `INSTALLED_APPS` in the project settings.

### 4. Define Models

Edit `$ARGUMENTS/models.py`:
- Create model classes based on the plan
- Add proper field types, validators, and help_text
- Define `__str__` methods
- Add `Meta` class with ordering, verbose names
- Define relationships (ForeignKey, ManyToMany) with related_name
- Follow existing model patterns in the project

### 5. Create Migrations

Run `python manage.py makemigrations $ARGUMENTS` to generate the initial migration.

### 6. Create Serializers (if API needed)

Create `$ARGUMENTS/serializers.py`:
- Define ModelSerializer for each model
- Include validation logic
- Follow existing serializer patterns

### 7. Create Views

Create views in `$ARGUMENTS/views.py`:
- For API: Use DRF ViewSets or APIViews
- For web: Use class-based views
- Include proper permissions
- Follow existing view patterns

### 8. Create URLs

Create `$ARGUMENTS/urls.py`:
- Define URL patterns for all views
- Use DRF router for ViewSets
- Include the app URLs in the project's main `urls.py`

### 9. Create Admin Configuration

Edit `$ARGUMENTS/admin.py`:
- Register models with `@admin.register`
- Add `list_display`, `list_filter`, `search_fields`
- Follow existing admin patterns

### 10. Create Tests

Create `$ARGUMENTS/tests/`:
- `test_models.py` — model creation, validation, string representation
- `test_views.py` — endpoint responses, permissions, CRUD operations
- `test_serializers.py` — serialization, validation
- Use {{TEST_FRAMEWORK}} conventions
- Use factories or fixtures for test data
- Follow existing test patterns

### 11. Verify

- Run migrations: `python manage.py migrate`
- Run tests: `python -m pytest $ARGUMENTS/tests/ -v`
- Check for issues: `python manage.py check`

## Output

After completing all steps, report:
- Files created (with paths)
- Models and their fields
- API endpoints registered
- Test results
