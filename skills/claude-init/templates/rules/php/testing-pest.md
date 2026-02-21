---
paths:
  - "tests/**"
---

# Pest Testing Conventions

## Syntax

- **Pest exclusively** — never use PHPUnit class syntax (`extends TestCase`)
- Use `describe()` / `it()` block structure
- Chain groups on describe blocks: `describe('Feature', function () { ... })->group('tag')`

## Imports

- Use function imports for Pest's Laravel helpers:

```php
use function Pest\Laravel\postJson;
use function Pest\Laravel\getJson;
use function Pest\Laravel\actingAs;
```

## Assertions

- Prefer expressive expectations over assert methods:
  - `expect($response)->toBeSuccessful()` over `$response->assertStatus(200)`
  - `expect($model->name)->toBe('foo')` over `$this->assertEquals('foo', $model->name)`
- HTTP response assertions are fine as chained methods: `->assertJson([...])`, `->assertStatus(422)`

## Setup

- Use `beforeEach()` inside `describe()` for shared setup
- Use `$this->` for shared state within a describe block (Pest binds to TestCase)

## Factories & Data

- Always use model factories — never manual `DB::insert()` or `new Model()`
- Use datasets for parameterized tests: `it('validates input', function ($input, $expected) { ... })->with([...])`

## File Organization

- Test files mirror the app structure
- Feature tests are the default — use `--unit` flag only for pure logic with no framework dependencies

## Running Tests

- `php artisan test --compact --filter=TestName` for targeted runs
- Never run the full suite unless explicitly asked
