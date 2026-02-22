---
paths:
  - "*/migrations/**"
---

# Migration Safety Rules

## Forbidden Commands

- **NEVER** run `python manage.py migrate --run-syncdb` on the primary database
- **NEVER** run `python manage.py flush` on production or staging
- These commands can destroy data and cannot be easily restored
- Use `python manage.py migrate` only to apply pending migrations
- `migrate --database=test` is allowed (the test database is disposable)

## RunPython Safety

When using `RunPython` or `RunSQL` for data migrations, always include `reverse_code`:

```python
# BAD — no reverse operation
operations = [
    migrations.RunPython(set_default_status),
]

# GOOD — includes reverse operation
operations = [
    migrations.RunPython(
        set_default_status,
        reverse_code=clear_status,
    ),
]
```

Always use `apps.get_model()` inside migration functions instead of direct model imports:

```python
# BAD — direct import creates dependency on current model state
from myapp.models import User

def set_default_status(apps, schema_editor):
    User.objects.filter(status__isnull=True).update(status='active')

# GOOD — uses historical model from migration state
def set_default_status(apps, schema_editor):
    User = apps.get_model('myapp', 'User')
    User.objects.filter(status__isnull=True).update(status='active')
```

## Data Migrations vs Schema Migrations

- Keep schema changes (adding/removing fields, tables) separate from data migrations
- Schema migration: `AddField`, `RemoveField`, `CreateModel`, `AlterField`
- Data migration: `RunPython`, `RunSQL` for transforming existing data
- Run schema migration first, then data migration in a separate file if needed
- Never mix complex data transformations with schema changes in the same migration

## Column Removal Safety

When removing a field from a model:

1. **First migration**: Remove the field reference from Python code (model class), deploy
2. **Second migration**: Create and run the migration that removes the database column
3. This two-step process prevents errors from code trying to access a removed column

```python
# Step 1: Remove field from model, deploy code
class User(models.Model):
    name = models.CharField(max_length=255)
    # old_field removed from Python code

# Step 2: Generate and run migration
# python manage.py makemigrations
# This creates: migrations.RemoveField(model_name='user', name='old_field')
```

## Circular Dependency Prevention

- Avoid importing models from other apps in migration files
- Use `apps.get_model('app_name', 'ModelName')` instead
- Be careful with `ForeignKey` relationships across apps — they create migration dependencies
- Check `dependencies` list in migration files to prevent circular references

## General Practices

- Always include operations that reverse the migration (either via `reverse_code` or reversible operations)
- Non-reversible operations require `migrations.RunPython.noop` or `migrations.RunSQL.noop` as reverse
- Test migrations locally with `python manage.py migrate` and `migrate --fake-initial` before committing
- Test reverse with `python manage.py migrate app_name previous_migration_name`
- Name migrations descriptively: Django auto-generates names, but you can customize with `--name`
- Use `migrations.SeparateDatabaseAndState` for complex schema changes requiring multiple steps
- Always check for data loss — use `null=True` temporarily when adding non-nullable fields to populated tables
