---
paths:
  - "src/components/**"
  - "components/**"
  - "app/**/components/**"
---

# React Component Conventions

## Component Structure

- Use functional components with hooks — no class components
- Export components as named exports (not default) for better refactoring
- Keep components focused — extract sub-components when a file exceeds ~200 lines

## Hooks

- Custom hooks live in `hooks/` directory with `use` prefix
- Extract shared logic into custom hooks
- Follow the Rules of Hooks (no conditional hooks, only call at top level)

## Props

- Define prop types with TypeScript interfaces
- Destructure props in the function signature
- Use `React.FC` sparingly — prefer explicit return types

## State Management

- Use `useState` for local component state
- Use `useReducer` for complex state logic
- Lift state up to the nearest common ancestor

## Naming

- Component files: PascalCase (`UserProfile.tsx`)
- Hook files: camelCase with `use` prefix (`useAuth.ts`)
- Utility files: camelCase (`formatDate.ts`)
