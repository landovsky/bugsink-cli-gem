# frozen_string_literal: true

require 'optparse'
require 'json'
require_relative 'client'
require_relative 'config'

module Bugsink
  # CLI command parser and router for BugSink API
  class CLI
    attr_reader :client, :config, :options

    def initialize(args = ARGV)
      @args = args
      @options = {
        format: 'table',
        project_id: nil
      }
      @config = Config.new
      @client = Client.new(@config)
    rescue Config::ConfigError => e
      error("Configuration error: #{e.message}")
      exit 1
    end

    def run
      return show_help if @args.empty?

      resource = @args[0]
      action = @args[1]

      case resource
      when 'help', '--help', '-h'
        show_help(action)
      when '--version', '-v'
        show_version
      when 'config'
        handle_config(action)
      when 'teams'
        handle_teams(action, @args[2..])
      when 'projects'
        handle_projects(action, @args[2..])
      when 'issues'
        handle_issues(action, @args[2..])
      when 'events'
        handle_events(action, @args[2..])
      when 'releases'
        handle_releases(action, @args[2..])
      else
        error("Unknown resource: #{resource}")
        show_help
        exit 1
      end
    rescue Client::ClientError => e
      error("API error: #{e.message}")
      exit 1
    rescue ArgumentError => e
      error("Argument error: #{e.message}")
      exit 1
    rescue StandardError => e
      error("Unexpected error: #{e.class} - #{e.message}")
      error(e.backtrace.join("\n")) if ENV['DEBUG']
      exit 1
    end

    private

    def handle_config(action)
      case action
      when 'show'
        puts @config.to_s
      when 'set-project'
        project_id = @args[2]
        error('Project ID required') && exit(1) unless project_id
        @config.set_project_id(project_id.to_i)
        success("Project ID set to #{project_id}")
      when 'test'
        @client.test_connection
        success('API connection successful!')
      else
        error("Unknown config action: #{action}")
        exit 1
      end
    end

    def handle_teams(action, args)
      case action
      when 'list'
        parse_format_options!(args)
        response = @client.teams_list
        output_list(response.data, format: @options[:format])
      when 'get'
        uuid = args[0]
        error('Team UUID required') && exit(1) unless uuid
        parse_format_options!(args[1..])
        team = @client.team_get(uuid)
        output_single(team, format: @options[:format])
      when 'create'
        data = parse_json_arg(args[0])
        error('Name required in JSON') && exit(1) unless data['name']
        team = @client.team_create(
          name: data['name'],
          visibility: data['visibility']
        )
        output_single(team, format: 'json')
      when 'update'
        uuid = args[0]
        error('Team UUID required') && exit(1) unless uuid
        data = parse_json_arg(args[1])
        error('Update data required') && exit(1) if data.empty?
        team = @client.team_update(
          uuid,
          name: data['name'],
          visibility: data['visibility']
        )
        output_single(team, format: 'json')
      else
        error("Unknown teams action: #{action}")
        exit 1
      end
    end

    def handle_projects(action, args)
      case action
      when 'list'
        parse_project_options!(args)
        response = @client.projects_list(team_uuid: @options[:team])
        output_list(response.data, format: @options[:format])
      when 'get'
        id = args[0]
        error('Project ID required') && exit(1) unless id
        parse_format_options!(args[1..])
        project = @client.project_get(id.to_i)
        output_single(project, format: @options[:format])
      when 'create'
        data = parse_json_arg(args[0])
        error('Team and name required in JSON') && exit(1) unless data['team'] && data['name']
        project = @client.project_create(
          team_uuid: data['team'],
          name: data['name'],
          visibility: data['visibility'],
          alert_on_new_issue: data['alert_on_new_issue'],
          alert_on_regression: data['alert_on_regression'],
          alert_on_unmute: data['alert_on_unmute']
        )
        output_single(project, format: 'json')
      when 'update'
        id = args[0]
        error('Project ID required') && exit(1) unless id
        data = parse_json_arg(args[1])
        error('Update data required') && exit(1) if data.empty?
        project = @client.project_update(
          id.to_i,
          name: data['name'],
          visibility: data['visibility'],
          alert_on_new_issue: data['alert_on_new_issue'],
          alert_on_regression: data['alert_on_regression'],
          alert_on_unmute: data['alert_on_unmute']
        )
        output_single(project, format: 'json')
      else
        error("Unknown projects action: #{action}")
        exit 1
      end
    end

    def handle_issues(action, args)
      case action
      when 'list'
        parse_issue_options!(args)
        project_id = @options[:project_id] || @config.project_id
        error('Project ID required (use --project or set via config)') && exit(1) unless project_id
        response = @client.issues_list(
          project_id: project_id,
          sort: @options[:sort] || 'last_seen',
          order: @options[:order] || 'desc'
        )
        output_list(response.data, format: @options[:format])
      when 'get'
        uuid = args[0]
        error('Issue UUID required') && exit(1) unless uuid
        parse_format_options!(args[1..])
        issue = @client.issue_get(uuid)
        output_single(issue, format: @options[:format])
      else
        error("Unknown issues action: #{action}")
        info('Note: Issues are read-only. Write operations not available in API.')
        exit 1
      end
    end

    def handle_events(action, args)
      case action
      when 'list'
        parse_event_options!(args)
        error('Issue UUID required (use --issue)') && exit(1) unless @options[:issue]
        response = @client.events_list(
          issue_uuid: @options[:issue],
          order: @options[:order] || 'desc'
        )
        output_list(response.data, format: @options[:format])
      when 'get'
        uuid = args[0]
        error('Event UUID required') && exit(1) unless uuid
        parse_format_options!(args[1..])
        event = @client.event_get(uuid)
        output_single(event, format: @options[:format])
      when 'stacktrace'
        uuid = args[0]
        error('Event UUID required') && exit(1) unless uuid
        stacktrace = @client.event_stacktrace(uuid)
        puts stacktrace
      else
        error("Unknown events action: #{action}")
        exit 1
      end
    end

    def handle_releases(action, args)
      case action
      when 'list'
        parse_release_options!(args)
        project_id = @options[:project_id] || @config.project_id
        error('Project ID required (use --project or set via config)') && exit(1) unless project_id
        response = @client.releases_list(project_id: project_id)
        output_list(response.data, format: @options[:format])
      when 'get'
        uuid = args[0]
        error('Release UUID required') && exit(1) unless uuid
        parse_format_options!(args[1..])
        release = @client.release_get(uuid)
        output_single(release, format: @options[:format])
      when 'create'
        data = parse_json_arg(args[0])
        error('Project and version required in JSON') && exit(1) unless data['project'] && data['version']
        release = @client.release_create(
          project_id: data['project'],
          version: data['version'],
          timestamp: data['timestamp']
        )
        output_single(release, format: 'json')
      else
        error("Unknown releases action: #{action}")
        exit 1
      end
    end

    def parse_format_options!(args)
      OptionParser.new do |opts|
        opts.on('--json', 'Output as JSON') { @options[:format] = 'json' }
        opts.on('--quiet', 'Minimal output') { @options[:format] = 'quiet' }
      end.parse!(args)
    end

    def parse_project_options!(args)
      OptionParser.new do |opts|
        opts.on('--team=UUID', 'Filter by team UUID') { |v| @options[:team] = v }
        opts.on('--json', 'Output as JSON') { @options[:format] = 'json' }
        opts.on('--quiet', 'Minimal output') { @options[:format] = 'quiet' }
      end.parse!(args)
    end

    def parse_issue_options!(args)
      OptionParser.new do |opts|
        opts.on('--project=ID', 'Project ID') { |v| @options[:project_id] = v.to_i }
        opts.on('--sort=FIELD', 'Sort field') { |v| @options[:sort] = v }
        opts.on('--order=ORDER', 'Sort order (asc|desc)') { |v| @options[:order] = v }
        opts.on('--json', 'Output as JSON') { @options[:format] = 'json' }
        opts.on('--quiet', 'Minimal output') { @options[:format] = 'quiet' }
      end.parse!(args)
    end

    def parse_event_options!(args)
      OptionParser.new do |opts|
        opts.on('--issue=UUID', 'Issue UUID (required)') { |v| @options[:issue] = v }
        opts.on('--order=ORDER', 'Sort order (asc|desc)') { |v| @options[:order] = v }
        opts.on('--json', 'Output as JSON') { @options[:format] = 'json' }
        opts.on('--quiet', 'Minimal output') { @options[:format] = 'quiet' }
      end.parse!(args)
    end

    def parse_release_options!(args)
      OptionParser.new do |opts|
        opts.on('--project=ID', 'Project ID') { |v| @options[:project_id] = v.to_i }
        opts.on('--json', 'Output as JSON') { @options[:format] = 'json' }
        opts.on('--quiet', 'Minimal output') { @options[:format] = 'quiet' }
      end.parse!(args)
    end

    def parse_json_arg(json_str)
      return {} unless json_str

      JSON.parse(json_str)
    rescue JSON::ParserError => e
      error("Invalid JSON: #{e.message}")
      exit 1
    end

    def output_list(data, format:)
      case format
      when 'json'
        puts JSON.pretty_generate(data)
      when 'quiet'
        data.each { |item| puts item['id'] || item['uuid'] }
      else
        output_table(data)
      end
    end

    def output_single(data, format:)
      case format
      when 'json'
        puts JSON.pretty_generate(data)
      when 'quiet'
        puts data['id'] || data['uuid']
      else
        puts JSON.pretty_generate(data)
      end
    end

    def output_table(data)
      return puts 'No data' if data.empty?

      # Extract common fields
      keys = data.first.keys
      headers = keys.join("\t")
      puts headers
      puts '-' * 80

      data.each do |item|
        values = keys.map { |k| format_value(item[k]) }
        puts values.join("\t")
      end
    end

    def format_value(value)
      case value
      when Hash, Array
        JSON.generate(value)
      when nil
        ''
      else
        value.to_s
      end
    end

    def show_version
      puts "BugSink CLI v#{Bugsink::VERSION}"
    end

    def show_help(resource = nil)
      if resource
        show_resource_help(resource)
      else
        show_general_help
      end
    end

    def show_general_help
      puts <<~HELP
        BugSink CLI - API wrapper for BugSink error tracking

        Usage: bugsink <resource> <action> [options]

        Resources:
          config      - Configuration management
          teams       - Team operations
          projects    - Project operations
          issues      - Issue operations (read-only)
          events      - Event operations (read-only)
          releases    - Release operations

        Global Options:
          --json      Output as JSON
          --quiet     Minimal output (IDs only)

        Common Commands:
          bugsink config show                          Show current configuration
          bugsink config set-project <id>              Set default project ID
          bugsink config test                          Test API connectivity

          bugsink teams list                           List all teams
          bugsink teams get <uuid>                     Get team details
          bugsink teams create '{"name":"TeamName"}'   Create team

          bugsink projects list [--team=<uuid>]        List projects
          bugsink projects get <id>                    Get project details

          bugsink issues list --project=<id>           List issues for project
          bugsink issues get <uuid>                    Get issue details

          bugsink events list --issue=<uuid>           List events for issue
          bugsink events stacktrace <uuid>             Get formatted stacktrace

          bugsink releases list --project=<id>         List releases
          bugsink releases create '{"project":8,"version":"v1.0"}'

        Environment Variables:
          BUGSINK_API_KEY         API authentication token (required)
          BUGSINK_HOST            API host (default: https://bugs.kopernici.cz)
          BUGSINK_PROJECT_ID      Default project ID (takes precedence over .bugsink file)

        Configuration File:
          .bugsink                Project ID for current directory (ignored if BUGSINK_PROJECT_ID is set)

        For resource-specific help:
          bugsink help <resource>

        Examples:
          # Set up configuration
          export BUGSINK_API_KEY="your-token-here"
          bugsink config set-project 8
          bugsink config test

          # List latest issues
          bugsink issues list --project=8 --sort=last_seen --order=desc --json

          # Get stacktrace for an event
          bugsink events stacktrace <event-uuid>

        Note: Issues and Events are READ-ONLY via the API. Write operations are not supported.
      HELP
    end

    def show_resource_help(resource)
      case resource
      when 'config'
        puts <<~HELP
          bugsink config - Configuration management

          Actions:
            show              Show current configuration
            set-project <id>  Set default project ID in .bugsink file
            test              Test API connectivity

          Examples:
            bugsink config show
            bugsink config set-project 8
            bugsink config test
        HELP
      when 'teams'
        puts <<~HELP
          bugsink teams - Team operations

          Actions:
            list                    List all teams
            get <uuid>              Get team details
            create <json>           Create new team
            update <uuid> <json>    Update team

          JSON Format (create):
            {"name":"Team Name","visibility":"hidden"}
            Visibility options: joinable, discoverable, hidden

          JSON Format (update):
            {"name":"New Name"}  // All fields optional

          Examples:
            bugsink teams list --json
            bugsink teams get ee4f4572-0957-4346-b433-3c605acbfa2a
            bugsink teams create '{"name":"My Team","visibility":"hidden"}'
            bugsink teams update <uuid> '{"name":"Updated Name"}'
        HELP
      when 'projects'
        puts <<~HELP
          bugsink projects - Project operations

          Actions:
            list [--team=<uuid>]    List projects (optionally filtered by team)
            get <id>                Get project details
            create <json>           Create new project
            update <id> <json>      Update project

          JSON Format (create):
            {
              "team":"team-uuid",
              "name":"Project Name",
              "visibility":"team_members",
              "alert_on_new_issue":true,
              "alert_on_regression":true,
              "alert_on_unmute":false
            }
            Visibility options: joinable, discoverable, team_members

          JSON Format (update):
            {"name":"New Name","alert_on_new_issue":false}  // All fields optional

          Examples:
            bugsink projects list --team=<uuid> --json
            bugsink projects get 8
            bugsink projects create '{"team":"<uuid>","name":"Test Project"}'
            bugsink projects update 8 '{"alert_on_new_issue":false}'
        HELP
      when 'issues'
        puts <<~HELP
          bugsink issues - Issue operations (READ-ONLY)

          Actions:
            list --project=<id> [--sort=<field>] [--order=<asc|desc>]
            get <uuid>

          Options:
            --project=<id>    Project ID (required for list)
            --sort=<field>    Sort by: last_seen, digest_order (default: last_seen)
            --order=<order>   Sort order: asc, desc (default: desc)

          Examples:
            bugsink issues list --project=8 --sort=last_seen --order=desc
            bugsink issues get <uuid> --json

          Note: Issues are READ-ONLY. No write operations available in API.
        HELP
      when 'events'
        puts <<~HELP
          bugsink events - Event operations (READ-ONLY)

          Actions:
            list --issue=<uuid> [--order=<asc|desc>]
            get <uuid>
            stacktrace <uuid>

          Options:
            --issue=<uuid>    Issue UUID (required for list)
            --order=<order>   Sort order: asc, desc (default: desc)

          Examples:
            bugsink events list --issue=<uuid>
            bugsink events get <uuid> --json
            bugsink events stacktrace <uuid>

          Note: Events are READ-ONLY. Created via Sentry SDK only.
        HELP
      when 'releases'
        puts <<~HELP
          bugsink releases - Release operations

          Actions:
            list --project=<id>     List releases for project
            get <uuid>              Get release details
            create <json>           Create new release

          JSON Format (create):
            {
              "project":8,
              "version":"v1.2.3",
              "timestamp":"2026-02-03T12:00:00Z"  // Optional
            }

          Examples:
            bugsink releases list --project=8
            bugsink releases get <uuid>
            bugsink releases create '{"project":8,"version":"v1.2.3"}'

          Note: Releases can be created but not updated or deleted.
        HELP
      else
        error("Unknown resource: #{resource}")
        show_general_help
      end
    end

    def success(message)
      puts "✓ #{message}"
    end

    def info(message)
      puts "ℹ #{message}"
    end

    def error(message)
      warn "✗ #{message}"
    end
  end
end
