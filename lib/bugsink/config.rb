# frozen_string_literal: true

module Bugsink
  # Configuration management for BugSink API client
  class Config
    class ConfigError < StandardError; end

    attr_reader :api_key, :host, :project_id

    DOTFILE = '.bugsink'.freeze

    def initialize
      @api_key = ENV['BUGSINK_API_KEY']
      @host = ENV.fetch('BUGSINK_HOST', 'https://bugs.kopernici.cz')
      @project_id = read_project_id
    end

    def valid?
      !api_key.nil? && !api_key.empty?
    end

    def validate!
      raise ConfigError, 'BUGSINK_API_KEY environment variable is required' unless valid?
    end

    def authorization_header
      { 'Authorization' => "Bearer #{api_key}" }
    end

    def set_project_id(id)
      File.write(dotfile_path, "PROJECT_ID=#{id}\n")
      @project_id = id
    end

    def project_id_present?
      !project_id.nil?
    end

    def to_s
      <<~CONFIG
        BugSink Configuration:
          Host: #{host}
          API Key: #{api_key ? "#{api_key[0..8]}...#{api_key[-8..]}" : 'not set'}
          Project ID: #{project_id || 'not set'}
      CONFIG
    end

    private

    def read_project_id
      return nil unless File.exist?(dotfile_path)

      content = File.read(dotfile_path).strip
      match = content.match(/^PROJECT_ID=(\d+)$/)
      match ? match[1].to_i : nil
    end

    def dotfile_path
      File.join(Dir.pwd, DOTFILE)
    end
  end
end
