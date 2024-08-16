# Compare Code Coverage GitHub Action

This GitHub Action compares code coverage between the current branch and a specified target branch using either PCOV or Xdebug.

## Inputs

- `coverage-tool`: The code coverage tool to use. Options are `pcov` (default) and `xdebug`.
- `target-branch`: The branch to compare against. Defaults to `HEAD`.

## Example Usage

```yaml
name: Compare Code Coverage

on: [push, pull_request]

jobs:
  coverage-comparison:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Compare Code Coverage
        uses: your-username/compare-code-coverage@v1
        with:
          coverage-tool: 'xdebug'
          target-branch: 'development'
