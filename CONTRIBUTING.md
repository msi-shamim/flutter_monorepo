# Contributing to flutter_monorepo

Thank you for your interest in contributing! This guide will help you get started.

## Development Setup

```bash
git clone https://github.com/msi-shamim/flutter_monorepo.git
cd flutter_monorepo
dart pub get
```

## Running Tests

```bash
dart test
```

## Code Style

- Follow Dart conventions and the existing code patterns
- Run `dart analyze` before submitting — zero warnings required
- Run `dart format .` to ensure consistent formatting

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/msi-shamim/flutter_monorepo/issues) first
2. Create a new issue with the **Bug Report** template
3. Include: steps to reproduce, expected behavior, actual behavior, environment info

### Suggesting Features

1. Check [existing issues](https://github.com/msi-shamim/flutter_monorepo/issues) for similar requests
2. Create a new issue with the **Feature Request** template
3. Describe the problem, proposed solution, and alternatives considered

### Submitting Code

1. Fork the repository
2. Create a feature branch from `master` (`git checkout -b feat/my-feature`)
3. Make your changes
4. Add or update tests as needed
5. Ensure all checks pass: `dart analyze && dart test`
6. Commit with conventional messages (`feat:`, `fix:`, `docs:`, `chore:`)
7. Push and open a Pull Request

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat: add new state management option`
- `fix: resolve JSON parse error in config template`
- `docs: update README with new flags`
- `chore: bump dependencies`
- `refactor: simplify template strategy pattern`
- `test: add tests for version resolver`

## Architecture

See the [Wiki Architecture page](https://github.com/msi-shamim/flutter_monorepo/wiki/Architecture) for details on the strategy pattern, template system, and how to add new options.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.
