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
