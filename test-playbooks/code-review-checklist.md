# Code Review Checklist

Use this playbook when reviewing pull requests to ensure consistent and thorough reviews.

## Pre-Review

- [ ] PR has a clear title and description
- [ ] All CI checks are passing
- [ ] No merge conflicts exist
- [ ] PR is not a draft

## Code Quality

- [ ] Code follows project style guidelines
- [ ] No unnecessary commented-out code
- [ ] No debug statements or console.logs
- [ ] Functions and variables have clear names
- [ ] Complex logic has explanatory comments
- [ ] No hardcoded values that should be constants

## Functionality

- [ ] Code does what the PR description says
- [ ] Edge cases are handled
- [ ] Error handling is appropriate
- [ ] No obvious bugs or logic errors
- [ ] Performance considerations addressed

## Testing

- [ ] New features have tests
- [ ] Tests cover edge cases
- [ ] All tests pass locally and in CI
- [ ] Test names clearly describe what they test

## Documentation

- [ ] README updated if needed
- [ ] API documentation updated
- [ ] Inline comments for complex logic
- [ ] Breaking changes documented

## Security

- [ ] No sensitive data in code
- [ ] Input validation present
- [ ] Authentication/authorization correct
- [ ] Dependencies are up to date

## Final Steps

- [ ] Leave constructive feedback
- [ ] Approve or request changes
- [ ] Follow up on previous review comments
