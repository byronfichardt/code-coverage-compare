#!/bin/bash
set -e

# Get input parameters
COVERAGE_TOOL=$1
TARGET_BRANCH=$2

# Default to PCOV if no tool is specified
if [ -z "$COVERAGE_TOOL" ]; then
  COVERAGE_TOOL="pcov"
fi

# Default to HEAD if no branch is specified
if [ -z "$TARGET_BRANCH" ]; then
  TARGET_BRANCH="HEAD"
fi

# Enable the selected coverage tool
if [ "$COVERAGE_TOOL" = "pcov" ]; then
  echo "Enabling PCOV..."
  echo "pcov.enabled=1" | sudo tee -a $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")
  echo "pcov.directory=$(pwd)" | sudo tee -a $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")
elif [ "$COVERAGE_TOOL" = "xdebug" ]; then
  echo "Enabling Xdebug..."
  echo "xdebug.mode=coverage" | sudo tee -a $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")
else
  echo "Error: Invalid coverage tool specified. Use 'pcov' or 'xdebug'."
  exit 1
fi

# Run tests and generate coverage for the current branch
./vendor/bin/phpunit -d memory_limit=512M --coverage-clover=coverage.xml

# Fetch and checkout the target branch
git fetch origin $TARGET_BRANCH:$TARGET_BRANCH
git checkout $TARGET_BRANCH

# Install dependencies for the target branch
composer install --no-ansi --no-interaction --no-progress --prefer-dist

# Ensure the selected coverage tool is still enabled for the target branch
if [ "$COVERAGE_TOOL" = "pcov" ]; then
  echo "Ensuring PCOV is enabled on the $TARGET_BRANCH branch..."
  echo "pcov.enabled=1" | sudo tee -a $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")
  echo "pcov.directory=$(pwd)" | sudo tee -a $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")
elif [ "$COVERAGE_TOOL" = "xdebug" ]; then
  echo "Ensuring Xdebug is enabled on the $TARGET_BRANCH branch..."
  echo "xdebug.mode=coverage" | sudo tee -a $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")
fi

# Run tests and generate coverage for the target branch
./vendor/bin/phpunit -d memory_limit=512M --coverage-clover=coverage-compare.xml

# Compare code coverage
echo "Coverage comparison started at $(date)"

# Ensure the coverage files exist
if [ ! -f coverage.xml ]; then
  echo "Error: 'coverage.xml' file is missing."
  exit 1
fi

if [ ! -f coverage-compare.xml ]; then
  echo "Error: 'coverage-compare.xml' file is missing."
  exit 1
fi

# Extract total and covered statements for the branch
BRANCH_TOTAL_STATEMENTS=$(awk -F'"' '/<metrics/ {total+=$12} END {print total}' coverage.xml)
BRANCH_COVERED_STATEMENTS=$(awk -F'"' '/<metrics/ {covered+=$14} END {print covered}' coverage.xml)

# Extract total and covered statements for the compare branch
COMPARE_TOTAL_STATEMENTS=$(awk -F'"' '/<metrics/ {total+=$12} END {print total}' coverage-compare.xml)
COMPARE_COVERED_STATEMENTS=$(awk -F'"' '/<metrics/ {covered+=$14} END {print covered}' coverage-compare.xml)

if [ "$BRANCH_TOTAL_STATEMENTS" -eq 0 ] || [ "$COMPARE_TOTAL_STATEMENTS" -eq 0 ]; then
  echo "Error: One or more total statement counts are zero, cannot calculate coverage."
  exit 1
fi

# Calculate overall coverage percentages
BRANCH_COVERAGE=$(echo "scale=2; ($BRANCH_COVERED_STATEMENTS/$BRANCH_TOTAL_STATEMENTS)*100" | bc -l)
COMPARE_COVERAGE=$(echo "scale=2; ($COMPARE_COVERED_STATEMENTS/$COMPARE_TOTAL_STATEMENTS)*100" | bc -l)

if [ -z "$BRANCH_COVERAGE" ]; then
  echo "Error: Failed to calculate branch coverage."
  exit 1
fi

if [ -z "$COMPARE_COVERAGE" ]; then
  echo "Error: Failed to calculate compare branch coverage."
  exit 1
fi

# Output the results
echo "Branch Coverage: ${BRANCH_COVERAGE:-Not Found}%"
echo "Compare Branch Coverage: ${COMPARE_COVERAGE:-Not Found}%"

# Compare the coverage values
if (( $(echo "$BRANCH_COVERAGE < $COMPARE_COVERAGE" | bc -l) )); then
  echo "Coverage decreased compared to compare branch!"
  exit 1
else
  echo "Coverage is OK or improved!"
fi
