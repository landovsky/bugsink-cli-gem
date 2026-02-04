# BugSink CLI

A command-line interface for the BugSink error tracking service. Provides full API access for teams, projects, issues, events, and releases.

## Installation

Install the gem:

```bash
gem install bugsink-cli
```

Or add to your Gemfile:

```ruby
gem 'bugsink-cli', '~> 0.1.0'
```

## Configuration

### Environment Variables

**Required:**
- `BUGSINK_API_KEY` - Your BugSink API authentication token

**Optional:**
- `BUGSINK_HOST` - API host (default: `https://bugs.kopernici.cz`)
- `BUGSINK_PROJECT_ID` - Default project ID (takes precedence over `.bugsink` file)

### Project Configuration

The CLI supports two ways to set a default project ID:

1. **Environment Variable (recommended for CI/CD):**
   ```bash
   export BUGSINK_PROJECT_ID=8
   ```

2. **Local `.bugsink` file (recommended for development):**
   ```bash
   bugsink config set-project 8
   # This creates .bugsink file with: PROJECT_ID=8
   ```

**Note:** The environment variable takes precedence over the `.bugsink` file. When `BUGSINK_PROJECT_ID` is set, the `config set-project` command will not create a `.bugsink` file.

## Quick Start

```bash
# Set your API key
export BUGSINK_API_KEY="your-token-here"

# Test connection
bugsink config test

# Set default project (option 1: environment variable)
export BUGSINK_PROJECT_ID=8

# Or set default project (option 2: local file)
bugsink config set-project 8

# List latest issues
bugsink issues list --project=8 --sort=last_seen --order=desc

# Get formatted stacktrace
bugsink events stacktrace <event-uuid>
```

## Usage

### General Syntax

```bash
bugsink <resource> <action> [arguments] [options]
```

### Global Options

- `--json` - Output as JSON (machine-readable)
- `--quiet` - Minimal output (IDs only)

### Resources

#### Config

```bash
bugsink config show              # Show current configuration
bugsink config set-project <id>  # Set default project ID
bugsink config test              # Test API connectivity
```

#### Teams

```bash
# List all teams
bugsink teams list [--json|--quiet]

# Get team details
bugsink teams get <uuid> [--json]

# Create team
bugsink teams create '{"name":"Team Name","visibility":"hidden"}'

# Update team
bugsink teams update <uuid> '{"name":"New Name"}'
```

#### Projects

```bash
# List all projects (optionally filter by team)
bugsink projects list [--team=<uuid>] [--json|--quiet]

# Get project details
bugsink projects get <id> [--json]

# Create project
bugsink projects create '{
  "team":"<team-uuid>",
  "name":"Project Name",
  "visibility":"team_members",
  "alert_on_new_issue":true
}'

# Update project
bugsink projects update <id> '{"name":"New Name","alert_on_new_issue":false}'
```

#### Issues (Read-Only)

```bash
# List issues for a project
bugsink issues list --project=<id> \
  [--sort=last_seen|digest_order] \
  [--order=asc|desc] \
  [--json|--quiet]

# Get issue details
bugsink issues get <uuid> [--json]
```

**Note:** Issues are **read-only** via the API. You cannot update status, resolve, or add comments through the CLI.

#### Events (Read-Only)

```bash
# List events for an issue
bugsink events list --issue=<uuid> [--order=asc|desc] [--json|--quiet]

# Get event details
bugsink events get <uuid> [--json]

# Get formatted stacktrace (Markdown)
bugsink events stacktrace <uuid>
```

**Note:** Events are **read-only** and created automatically via Sentry SDK. No manual creation/updates available.

#### Releases

```bash
# List releases for a project
bugsink releases list --project=<id> [--json|--quiet]

# Get release details
bugsink releases get <uuid> [--json]

# Create release
bugsink releases create '{
  "project":8,
  "version":"v1.2.3",
  "timestamp":"2026-02-03T12:00:00Z"
}'
```

**Note:** Releases can be created but not updated or deleted.

### Help System

```bash
# General help
bugsink help

# Resource-specific help
bugsink help teams
bugsink help projects
bugsink help issues
bugsink help events
bugsink help releases
```

## Examples

### Daily Development Workflow

```bash
# Set up once
export BUGSINK_API_KEY="..."
cd /path/to/project
bugsink config set-project 8

# Check latest errors
bugsink issues list --project=8 --sort=last_seen --order=desc --json | jq '.[:5]'

# Get detailed stacktrace for an issue
ISSUE_UUID=$(bugsink issues list --project=8 --quiet | head -1)
EVENT_UUID=$(bugsink events list --issue=$ISSUE_UUID --quiet | head -1)
bugsink events stacktrace $EVENT_UUID
```

### Creating a Release

```bash
# After deployment
VERSION="v$(date +%Y%m%d-%H%M%S)"
bugsink releases create "{\"project\":8,\"version\":\"$VERSION\"}"
```

### Filtering and Searching

```bash
# Get all projects for a specific team
TEAM_UUID="ee4f4572-0957-4346-b433-3c605acbfa2a"
bugsink projects list --team=$TEAM_UUID --json | jq '.[].name'

# Get IDs of all teams
bugsink teams list --quiet
```

## Output Formats

### Table (Default)

Human-readable table format with tab-separated columns:

```
id	name	visibility
ee4f4572...	Team Name	team_members
```

### JSON

Machine-readable JSON format (use `--json`):

```json
[
  {
    "id": "ee4f4572-0957-4346-b433-3c605acbfa2a",
    "name": "Team Name",
    "visibility": "team_members"
  }
]
```

### Quiet

Minimal output with just IDs (use `--quiet`):

```
ee4f4572-0957-4346-b433-3c605acbfa2a
```

## API Capabilities & Limitations

### Supported Write Operations

- **Teams:** Create, Update
- **Projects:** Create, Update
- **Releases:** Create

### Read-Only Resources

- **Issues:** Cannot update status, resolve, or add comments
- **Events:** Created automatically via Sentry SDK ingestion only

### Not Supported

- **DELETE operations:** No resource can be deleted via API
- **Bulk operations:** Must process items one at a time
- **Filtering on list endpoints:** Limited filter support

## Library Usage

You can also use bugsink-cli as a Ruby library:

```ruby
require 'bugsink'

# Initialize client
config = Bugsink::Config.new
client = Bugsink::Client.new(config)

# List teams
response = client.teams_list
teams = response.data

# Get project
project = client.project_get(8)

# Create release
release = client.release_create(
  project_id: 8,
  version: 'v1.0.0'
)
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

### Running Tests

```bash
# Run all tests
BUGSINK_API_KEY="your-key" bundle exec rspec

# Run specific test
BUGSINK_API_KEY="your-key" bundle exec rspec spec/bugsink/config_spec.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/koperniki/bugsink-cli.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
