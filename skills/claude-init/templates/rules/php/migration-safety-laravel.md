---
paths:
  - "database/migrations/**"
---

# Migration Safety Rules

## Forbidden Commands

- **NEVER** run `php artisan migrate:fresh` or `php artisan migrate:reset` on the primary database
- These destroy the database and cannot be easily restored
- Use `php artisan migrate` only to apply pending migrations
- `migrate:fresh --database=testing` is allowed (the test database is disposable)

## Column Modifications

When modifying an existing column, the migration **must include all attributes** that were previously defined on that column. Laravel drops any unlisted attributes during column modification.

```php
// BAD — drops the existing default and nullable attributes
$table->string('name')->change();

// GOOD — preserves all existing attributes
$table->string('name')->nullable()->default('Unknown')->change();
```

Always check the current column definition before writing a modification migration.

## General Practices

- Always include a `down()` method that reverses the migration
- Test migrations locally with `php artisan migrate` before committing
- Name migrations descriptively: `add_availability_to_users_table`, not `update_users`
