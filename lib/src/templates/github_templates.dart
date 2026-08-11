import '../project_config.dart';

/// Contributor Covenant Code of Conduct v2.1.
String codeOfConduct(ProjectConfig c) => '''
# Contributor Covenant Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socio-economic status,
nationality, personal appearance, race, caste, color, religion, or sexual
identity and orientation.

We pledge to act and interact in ways that contribute to an open, welcoming,
diverse, inclusive, and healthy community.

## Our Standards

Examples of behavior that contributes to a positive environment:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior:

* Trolling, insulting or derogatory comments, and personal attacks
* Public or private harassment
* Publishing others' private information without explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

## Enforcement

Instances of unacceptable behavior may be reported to the project maintainers.
All complaints will be reviewed and investigated promptly and fairly.

## Attribution

This Code of Conduct is adapted from the
[Contributor Covenant](https://www.contributor-covenant.org), version 2.1,
available at
<https://www.contributor-covenant.org/version/2/1/code_of_conduct.html>.
''';

/// Placeholder FUNDING.yml for GitHub Sponsors.
String fundingYml(ProjectConfig c) => '''
# These are supported funding model platforms
#
# Uncomment and fill in the appropriate fields:

# github: [your-github-username]
# patreon: # Replace with a single Patreon username
# open_collective: # Replace with a single Open Collective username
# ko_fi: # Replace with a single Ko-fi username
# custom: ["https://your-link.com"]
''';

/// GitHub Issue template for bug reports.
String bugReportTemplate(ProjectConfig c) =>
    '''
---
name: Bug Report
about: Report a bug to help us improve ${c.pascal}
title: "[BUG] "
labels: bug
assignees: ""
---

## Describe the Bug

A clear and concise description of what the bug is.

## Steps to Reproduce

1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## Expected Behavior

A clear and concise description of what you expected to happen.

## Actual Behavior

What actually happened instead.

## Screenshots

If applicable, add screenshots to help explain your problem.

## Environment

- **Device:** [e.g., Pixel 7, iPhone 15]
- **OS:** [e.g., Android 14, iOS 17]
- **Flutter version:** [e.g., 3.24.0]
- **App version:** [e.g., 1.0.0]

## Additional Context

Add any other context about the problem here.
''';

/// GitHub Issue template for feature requests.
String featureRequestTemplate(ProjectConfig c) =>
    '''
---
name: Feature Request
about: Suggest an idea for ${c.pascal}
title: "[FEATURE] "
labels: enhancement
assignees: ""
---

## Problem Statement

A clear and concise description of the problem this feature would solve.
Ex. "I'm always frustrated when [...]"

## Proposed Solution

A clear and concise description of what you want to happen.

## Alternatives Considered

A description of any alternative solutions or features you've considered.

## Additional Context

Add any other context, mockups, or screenshots about the feature request here.
''';

/// GitHub Pull Request template.
String pullRequestTemplate(ProjectConfig c) => '''
## Summary

Brief description of what this PR does.

## Changes

- [ ] Change 1
- [ ] Change 2

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Refactoring (no functional changes)
- [ ] Documentation update

## Testing

- [ ] Tests added for new functionality
- [ ] All existing tests pass (`dart test`)
- [ ] Code analysis passes (`dart analyze`)
- [ ] Manually tested on target platform(s)

## Checklist

- [ ] My code follows the project style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have added/updated documentation as needed
- [ ] My changes do not introduce new warnings
- [ ] Package boundaries are respected (core, ui, network, l10n)
''';

/// GitHub Actions CI workflow.
String ciWorkflow(ProjectConfig c) =>
    '''
name: CI

on:
  push:
    branches: [main, master, develop]
  pull_request:
    branches: [main, master, develop]

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Install dependencies
        run: dart pub get

      - name: Analyze
        run: dart analyze --fatal-infos

      - name: Format check
        run: dart format --set-exit-if-changed .

  test:
    name: Test
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Install dependencies
        run: dart pub get

      - name: Test core package
        run: dart test packages/core/test

      - name: Test UI package
        run: flutter test packages/ui/test

      - name: Test network package
        run: flutter test packages/network/test

      - name: Test app
        run: flutter test ${c.app}/test
''';
