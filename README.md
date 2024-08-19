# Compare Code Coverage GitHub Action

This GitHub Action compares code coverage between the current branch and a specified target branch using either PCOV or Xdebug. It also posts the results as a comment on the pull request.

## Inputs

- **`coverage-tool`**: The code coverage tool to use. Options are `pcov` (default) and `xdebug`.
- **`target-branch`**: The branch to compare against. Defaults to `HEAD`.

## Outputs

This action will post a comment on the pull request with the following information:

- Branch coverage percentage.
- Target branch coverage percentage.
- A message indicating whether the coverage has improved, decreased, or remained the same.

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
        uses: byronfichardt/code-coverage-compare@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          coverage-tool: 'xdebug'
          target-branch: 'development'
```
## How It Works

### Checkout Code
The action checks out the repository code using `actions/checkout`.

### Run Coverage Comparison

- The action compares the code coverage between the current branch and the specified target branch using the selected coverage tool (PCOV or Xdebug).
- It calculates the coverage for both branches and compares them.

### Post Comment on Pull Request

- If the workflow is triggered by a pull request, the action will post a comment on the PR with the coverage results, indicating whether the coverage has improved, decreased, or remained the same compared to the target branch.

## Customization

You can customize the action by specifying:

- **Coverage Tool**: Choose between PCOV and Xdebug depending on your preference or project requirements.
- **Target Branch**: Specify the branch you want to compare the coverage against. If no branch is specified, the default is `HEAD`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
