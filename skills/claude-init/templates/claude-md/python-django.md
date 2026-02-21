# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Stack

- Python {{PYTHON_VERSION}} / Django {{DJANGO_VERSION}}
- Database: {{DATABASE}}
- Testing: pytest + pytest-django
- Formatting: {{FORMATTER}}
- Package Manager: {{PACKAGE_MANAGER}}

## Local Development

- **Dev**: `python manage.py runserver`
- **Tests**: `pytest`
- **Migrations**: `python manage.py migrate`
- **Format**: `{{FORMAT_COMMAND}}`
- **Shell**: `python manage.py shell_plus` (if django-extensions installed)

## Architecture

{{ARCHITECTURE_NOTES}}

### Key Directories

| Directory | Purpose |
|---|---|
| `{{PROJECT_SLUG}}/` | Project settings and root URL config |
| `apps/` | Django applications |
| `templates/` | HTML templates |
| `static/` | Static assets |
| `tests/` | Test files |

## Conventions

- **Indentation**: 4 spaces (PEP 8)
- **Imports**: isort ordering (stdlib → third-party → local)
- **Models**: Always define `__str__()`, use `Meta` class for ordering
- **Views**: Prefer class-based views for CRUD, function-based for custom logic
- **URLs**: Use `path()` with named URL patterns
- **Migrations**: Always include reverse migration; never run `migrate --fake` without understanding

## Workflow Automation

### Task Assessment

Use `EnterPlanMode` for any task that:
- Touches 2+ files
- Creates a new model, view, or URL pattern
- Involves refactoring across apps

### Post-Implementation

After modifying 2+ files:
- Offer to run `pytest --tb=short`
- Offer to run `{{FORMAT_COMMAND}}`
- Offer a code review via the security-reviewer agent

### Context Management

- After completing a unit of work, suggest `/compact`
- After 5+ exchanges on different topics, suggest `/clear`

## Things to Watch For

- **Migration safety**: Never `migrate --fake` or delete migration files on shared databases
- **Settings**: Use environment variables for secrets, never hardcode
- **QuerySets**: Watch for N+1 queries — use `select_related()` and `prefetch_related()`
- **CSRF**: Ensure forms include `{% csrf_token %}`, API views use proper authentication
