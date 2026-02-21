---
description: Start the development server
disable-model-invocation: true
---

Start the project's development server.

Use the detected dev command: `{{DEV_COMMAND}}`

If the dev command is not configured, detect it from:
- `package.json` scripts (look for "dev", "serve", "start")
- `composer.json` scripts
- `Makefile` targets (look for "dev", "serve")
- Common commands: `php artisan serve`, `npm run dev`, `python manage.py runserver`

If $ARGUMENTS is provided, pass them as additional flags to the dev command.

Run the command and report the server URL when it starts.
