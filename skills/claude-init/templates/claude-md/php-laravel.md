# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Stack

- PHP {{PHP_VERSION}} / Laravel {{LARAVEL_VERSION}}
- Database: {{DATABASE}}
- Testing: Pest
- Formatting: {{FORMATTER}}
- Package Manager: Composer

## Local Development

- **Dev URL**: {{DEV_URL}}
- **Start**: `php artisan serve` or {{DEV_COMMAND}}
- **Tests**: `php artisan test --compact`
- **Format**: `./vendor/bin/{{FORMATTER_COMMAND}}`

## Architecture

{{ARCHITECTURE_NOTES}}

### Key Directories

| Directory | Purpose |
|---|---|
| `app/Http/Controllers/` | HTTP controllers |
| `app/Models/` | Eloquent models |
| `app/Http/Resources/` | API resource transformers |
| `app/Http/Requests/` | Form request validation |
| `database/migrations/` | Database migrations |
| `routes/` | Route definitions |
| `tests/` | Pest test files |

## Conventions

- **Indentation**: Tabs (enforced by {{FORMATTER}})
- **Naming**: PSR-12 conventions
- **Models**: Always use factories in tests, never raw DB inserts
- **Migrations**: Always include `down()` method; never run `migrate:fresh` on primary DB
- **API responses**: snake_case keys, consistent error shape
- **Tests**: Pest `describe`/`it` syntax, function imports for helpers

## Workflow Automation

### Task Assessment

Use `EnterPlanMode` for any task that:
- Touches 2+ files
- Creates a new endpoint, migration, or model
- Involves refactoring across files

### Post-Implementation

After modifying 2+ files:
- Offer to run `php artisan test --compact --filter=RelevantTest`
- Offer to run `./vendor/bin/{{FORMATTER_COMMAND}} lint`
- Offer a code review via the security-reviewer agent

### Context Management

- After completing a unit of work, suggest `/compact`
- After 5+ exchanges on different topics, suggest `/clear`

## Things to Watch For

- **Migration safety**: Never `migrate:fresh` or `migrate:reset` on primary DB
- **Mass assignment**: Always define `$fillable` or `$guarded` on models
- **N+1 queries**: Use eager loading (`with()`) for relationships
- **.env files**: Never edit directly — modify `.env.example` instead
