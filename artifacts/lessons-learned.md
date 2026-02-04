# Lessons Learned

This file captures learnings from completed work to improve future planning and implementation.

## 2026-02-04 - bugsink-cli-dkw - BUGSINK_PROJECT_ID Environment Variable Support

### What worked well
- The plan provided excellent implementation details with specific code snippets for each change
- Following the existing pattern from `BUGSINK_API_KEY` and `BUGSINK_HOST` made the implementation consistent
- The plan correctly identified all edge cases (empty string, zero, negative, non-numeric) upfront
- Adding source display to `Config#to_s` (showing "from env" or "from file") is useful for debugging

### What to avoid
- When adding ENV-based configuration, always validate the value type and range, not just presence
- `"".to_i` returns 0 in Ruby, which can be confused with "not set" - always check for positive integers when IDs are expected

### Process improvements
- For configuration features that have multiple sources (env var vs file), the plan should specify:
  1. Precedence order
  2. Behavior when the primary source has invalid data (fall back to secondary or return nil?)
  3. User feedback mechanism (how does user know which source is being used?)
- The optional "show source" feature in `to_s` proved valuable - consider making this a standard pattern for all multi-source configuration

## 2026-02-04 - bugsink-cli-i17 - Fix NoMethodError in Error Handling

### What worked well
- The plan's root cause analysis was thorough and accurate, identifying both contributing factors:
  1. The broken `error() && exit(1)` pattern (warn returns nil, so exit never runs)
  2. Ruby's array slicing edge case where `[][1..]` returns `nil` not `[]`
- Using defensive programming with multiple layers of protection (fixed control flow AND nil guards AND `|| []` fallback) ensures robustness
- TDD approach worked well - tests were written first, then implementation fixed to pass them
- The plan correctly identified which error patterns to fix (only 5) and warned not to touch the others

### What to avoid
- **Never use `error() && exit(1)` pattern in Ruby**: The `warn` function returns `nil`, so `nil && exit(1)` evaluates to `nil` without executing exit. Use explicit control flow instead:
  ```ruby
  # BAD - exit never runs because warn returns nil
  error('message') && exit(1) unless condition

  # GOOD - explicit and reliable
  unless condition
    error('message')
    exit 1
  end
  ```
- **Ruby array slicing beyond bounds returns nil**: `[][1..]` returns `nil`, not `[]`. Always use `array[n..] || []` when the array might be empty or when slicing from an index that might not exist

### Process improvements
- When auditing for similar bugs, search for the broken pattern across the codebase: `git grep 'error.*&& exit'` would have found all instances
- For CLI argument validation, establish a standard pattern and use it consistently. The explicit `unless` block pattern is clearer than one-liners with boolean operators
- When methods accept arrays from external sources, add nil/empty guards at the top as defensive programming
