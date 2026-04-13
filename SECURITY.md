# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.3.x   | :white_check_mark: |
| < 1.3   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly.

**Do NOT open a public issue.**

Instead, email **im.msishamim@gmail.com** with:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Timeline

- **Acknowledgment:** within 48 hours
- **Assessment:** within 1 week
- **Fix release:** as soon as possible, depending on severity

## Scope

This security policy covers:

- The `flutter_monorepo` CLI tool itself
- The generated project templates and configurations
- Dependencies included in generated projects

## Best Practices for Generated Projects

The CLI generates projects with security in mind:

- `.gitignore` excludes `.env` files and secrets
- Auth templates use environment variables for secrets (never hardcoded)
- Production linting catches common security anti-patterns
- Generated `.env.example` documents required secrets without exposing values
