# frozen_string_literal: true

require 'httparty'
require 'json'
require_relative 'config'

module Bugsink
  # HTTP client for BugSink API
  class Client
    include HTTParty

    class ClientError < StandardError
      attr_reader :code, :response

      def initialize(message, code: nil, response: nil)
        super(message)
        @code = code
        @response = response
      end
    end

    class Response
      attr_reader :data, :next_cursor

      def initialize(response_body)
        @data = response_body.is_a?(Hash) ? [response_body] : (response_body || [])
        @next_cursor = extract_next_cursor(@data)
      end

      def initialize_from_list(response_body)
        @data = response_body['results'] || []
        @next_cursor = response_body['next']
      end

      def success?
        true
      end

      def add_data(new_data)
        @data.concat(new_data)
      end

      def has_more?
        !@next_cursor.nil?
      end

      private

      def extract_next_cursor(data)
        return nil unless data.is_a?(Hash)
        data['next']
      end
    end

    attr_reader :config

    def initialize(config = nil)
      @config = config || Config.new
      @config.validate!

      self.class.base_uri @config.host
      self.class.headers @config.authorization_header
      self.class.headers 'Content-Type' => 'application/json'
      self.class.headers 'Accept' => 'application/json'
    end

    # Teams
    def teams_list
      response = self.class.get('/api/canonical/0/teams/')
      check_response(response)
      parse_list_response(response)
    end

    def team_get(uuid)
      response = self.class.get("/api/canonical/0/teams/#{uuid}/")
      check_response(response)
      response.parsed_response
    end

    def team_create(name:, visibility: nil)
      body = { name: name }
      body[:visibility] = visibility if visibility

      response = self.class.post('/api/canonical/0/teams/', body: body.to_json)
      check_response(response)
      response.parsed_response
    end

    def team_update(uuid, name: nil, visibility: nil)
      body = {}
      body[:name] = name if name
      body[:visibility] = visibility if visibility

      raise ArgumentError, 'At least one field must be provided for update' if body.empty?

      response = self.class.patch("/api/canonical/0/teams/#{uuid}/", body: body.to_json)
      check_response(response)
      response.parsed_response
    end

    # Projects
    def projects_list(team_uuid: nil)
      query = {}
      query[:team] = team_uuid if team_uuid

      response = self.class.get('/api/canonical/0/projects/', query: query)
      check_response(response)
      parse_list_response(response)
    end

    def project_get(id)
      response = self.class.get("/api/canonical/0/projects/#{id}/")
      check_response(response)
      response.parsed_response
    end

    def project_create(team_uuid:, name:, visibility: nil, alert_on_new_issue: nil, alert_on_regression: nil, alert_on_unmute: nil)
      body = {
        team: team_uuid,
        name: name
      }
      body[:visibility] = visibility if visibility
      body[:alert_on_new_issue] = alert_on_new_issue unless alert_on_new_issue.nil?
      body[:alert_on_regression] = alert_on_regression unless alert_on_regression.nil?
      body[:alert_on_unmute] = alert_on_unmute unless alert_on_unmute.nil?

      response = self.class.post('/api/canonical/0/projects/', body: body.to_json)
      check_response(response)
      response.parsed_response
    end

    def project_update(id, name: nil, visibility: nil, alert_on_new_issue: nil, alert_on_regression: nil, alert_on_unmute: nil)
      body = {}
      body[:name] = name if name
      body[:visibility] = visibility if visibility
      body[:alert_on_new_issue] = alert_on_new_issue unless alert_on_new_issue.nil?
      body[:alert_on_regression] = alert_on_regression unless alert_on_regression.nil?
      body[:alert_on_unmute] = alert_on_unmute unless alert_on_unmute.nil?

      raise ArgumentError, 'At least one field must be provided for update' if body.empty?

      response = self.class.patch("/api/canonical/0/projects/#{id}/", body: body.to_json)
      check_response(response)
      response.parsed_response
    end

    # Issues
    def issues_list(project_id:, sort: 'last_seen', order: 'desc', limit: 250, cursor: nil)
      query = {
        project: project_id,
        sort: sort,
        order: order,
        limit: limit
      }
      query[:cursor] = cursor if cursor

      response = self.class.get('/api/canonical/0/issues/', query: query)
      check_response(response)
      parse_list_response(response)
    end

    def issue_get(uuid)
      response = self.class.get("/api/canonical/0/issues/#{uuid}/")
      check_response(response)
      response.parsed_response
    end

    # Events
    def events_list(issue_uuid:, order: 'desc', limit: 250, cursor: nil)
      query = {
        issue: issue_uuid,
        order: order,
        limit: limit
      }
      query[:cursor] = cursor if cursor

      response = self.class.get('/api/canonical/0/events/', query: query)
      check_response(response)
      parse_list_response(response)
    end

    def event_get(uuid)
      response = self.class.get("/api/canonical/0/events/#{uuid}/")
      check_response(response)
      response.parsed_response
    end

    def event_stacktrace(uuid)
      response = self.class.get("/api/canonical/0/events/#{uuid}/stacktrace/")
      check_response(response)
      response.body
    end

    # Releases
    def releases_list(project_id:)
      query = { project: project_id }

      response = self.class.get('/api/canonical/0/releases/', query: query)
      check_response(response)
      parse_list_response(response)
    end

    def release_get(uuid)
      response = self.class.get("/api/canonical/0/releases/#{uuid}/")
      check_response(response)
      response.parsed_response
    end

    def release_create(project_id:, version:, timestamp: nil)
      body = {
        project: project_id,
        version: version
      }
      body[:timestamp] = timestamp if timestamp

      response = self.class.post('/api/canonical/0/releases/', body: body.to_json)
      check_response(response)
      response.parsed_response
    end

    # Test connectivity
    def test_connection
      response = self.class.get('/api/canonical/0/teams/')
      check_response(response)
      true
    rescue ClientError => e
      raise ClientError.new("Connection test failed: #{e.message}", code: e.code, response: e.response)
    end

    private

    def check_response(response)
      return response if response.code >= 200 && response.code < 300

      error_message = "HTTP #{response.code}"
      begin
        error_body = response.parsed_response
        error_message += ": #{error_body}" if error_body
      rescue JSON::ParserError
        error_message += ": #{response.body}"
      end

      raise ClientError.new(error_message, code: response.code, response: response.body)
    end

    def parse_list_response(response)
      body = response.parsed_response

      # Handle paginated list responses
      if body.is_a?(Hash) && body.key?('results')
        resp = Response.new(nil)
        resp.initialize_from_list(body)
        resp
      else
        # Handle simple array responses (like teams)
        Response.new(body)
      end
    end
  end
end
