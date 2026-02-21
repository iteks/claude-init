# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Stack

- Expo {{EXPO_VERSION}} / React Native
- Language: TypeScript
- Styling: {{STYLING}}
- Navigation: Expo Router
- Testing: Jest + @testing-library/react-native
- Package Manager: {{PACKAGE_MANAGER}}

## Local Development

- **Dev**: `npx expo start`
- **iOS**: `npx expo run:ios`
- **Android**: `npx expo run:android`
- **Tests**: `{{TEST_COMMAND}}`
- **Lint**: `{{LINT_COMMAND}}`

## Architecture

{{ARCHITECTURE_NOTES}}

### Key Directories

| Directory | Purpose |
|---|---|
| `app/` | Expo Router screens and layouts |
| `components/` | Reusable UI components |
| `hooks/` | Custom React hooks |
| `api/` | API client functions and types |
| `constants/` | App constants and config |
| `assets/` | Images, fonts, and static assets |

## Conventions

- **Indentation**: 2 spaces (Prettier)
- **Components**: Functional with hooks, named exports
- **Styling**: {{STYLING_CONVENTIONS}}
- **Navigation**: File-based routing via Expo Router
- **API calls**: Centralized in `api/` directory with TypeScript interfaces

## Workflow Automation

### Task Assessment

Use `EnterPlanMode` for any task that:
- Touches 2+ files
- Creates a new screen, component, or API function
- Involves refactoring across files

### Post-Implementation

After modifying 2+ files:
- Offer to run `{{LINT_COMMAND}}`
- Offer to run TypeScript check: `npx tsc --noEmit`
- Offer a code review via the code-reviewer agent
- For security-sensitive changes (auth, data handling, API calls), offer the security-reviewer agent
- For new code lacking test coverage, offer the test-generator agent

### Context Management

- After completing a unit of work, suggest `/compact`
- After 5+ exchanges on different topics, suggest `/clear`

## Things to Watch For

- **Platform differences**: Test on both iOS and Android
- **Config files**: Confirm before modifying `app.config.*`, `metro.config.*`, `package.json`
- **Native modules**: Check Expo compatibility before adding native dependencies
- **Secure storage**: Use `expo-secure-store` for sensitive data, never AsyncStorage
