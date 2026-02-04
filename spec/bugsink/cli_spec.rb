# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bugsink::CLI do
  let(:config) { instance_double(Bugsink::Config, api_key: 'test-key', host: 'https://test.example.com', project_id: 8) }
  let(:client) { instance_double(Bugsink::Client) }

  before do
    allow(Bugsink::Config).to receive(:new).and_return(config)
    allow(Bugsink::Client).to receive(:new).and_return(client)
  end

  describe '#initialize' do
    it 'creates config and client instances' do
      cli = described_class.new([])
      expect(cli.config).to eq(config)
      expect(cli.client).to eq(client)
    end

    it 'initializes default options' do
      cli = described_class.new([])
      expect(cli.options[:format]).to eq('table')
      expect(cli.options[:project_id]).to be_nil
    end
  end

  describe '#show_version' do
    it 'displays version number' do
      cli = described_class.new(['--version'])
      expect { cli.run }.to output(/BugSink CLI v#{Bugsink::VERSION}/).to_stdout
    end
  end

  describe 'config commands' do
    it 'shows configuration' do
      cli = described_class.new(['config', 'show'])
      allow(config).to receive(:to_s).and_return('Config output')
      expect { cli.run }.to output(/Config output/).to_stdout
    end

    it 'tests connection' do
      cli = described_class.new(['config', 'test'])
      allow(client).to receive(:test_connection).and_return(true)
      expect { cli.run }.to output(/API connection successful/).to_stdout
    end
  end

  describe 'error handling' do
    it 'handles ClientError gracefully' do
      cli = described_class.new(['teams', 'list'])
      allow(client).to receive(:teams_list).and_raise(Bugsink::Client::ClientError.new('API error'))

      expect { cli.run }.to output(/API error/).to_stderr.and raise_error(SystemExit)
    end

    it 'handles ArgumentError gracefully' do
      cli = described_class.new(['projects', 'update', '123', '{}'])
      allow(client).to receive(:project_update).and_raise(ArgumentError, 'At least one field must be provided for update')

      expect { cli.run }.to output(/Argument error/).to_stderr.and raise_error(SystemExit)
    end
  end
end
