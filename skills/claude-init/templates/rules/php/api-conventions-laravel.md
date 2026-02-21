---
paths:
  - "routes/api/**"
  - "app/Http/Controllers/Api/**"
  - "app/Http/Resources/Api/**"
  - "app/Http/Requests/Api/**"
---

# API Conventions

## Controllers

- All public action methods return `JsonResponse` with explicit return type
- Keep public methods thin — extract logic into private helpers
- Use PHPDoc array shapes on private helpers

## Error Responses

Always return errors in this shape:

```php
return response()->json([
    'error' => 'Human-readable message',
    'code'  => 'snake_case_machine_code',
], $statusCode);
```

Common status codes: `401` (invalid credentials), `403` (forbidden), `404` (not found), `422` (validation).

## Route Registration

- Chain prefix + name on groups: `Route::prefix('resource')->name('resource.')`
- Bind controller at group level: `->controller(FooController::class)`
- Use dot-notation names: `resource.store`, `resource.show`
- Protected routes wrap in `Route::middleware(['auth:sanctum'])->group(...)`

## API Resources

- Extend `Illuminate\Http\Resources\Json\JsonResource`
- All output keys are **snake_case**
- Add `@mixin ModelClass` PHPDoc at class level
- Return type: `array<string, mixed>` on `toArray()`

## Form Requests

- Use a dedicated Form Request class when validation has 3+ rules
- Use inline `$request->validate()` for simpler cases
- Validation rules use **array syntax**: `['required', 'email', 'max:255']` (not pipe strings)
- `authorize()` returns `true` (authorization handled by middleware/policies)
