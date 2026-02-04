# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bugsink::Config do
  let(:config) { described_class.new }

  describe '#initialize' do
    it 'reads BUGSINK_API_KEY from environment' do
      allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return('test-key')
      allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

      config = described_class.new
      expect(config.api_key).to eq('test-key')
    end

    it 'uses default host when BUGSINK_HOST not set' do
      allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return('test-key')
      allow(ENV).to receive(:fetch).with('BUGSINK_HOST', 'https://bugs.kopernici.cz').and_return('https://bugs.kopernici.cz')

      config = described_class.new
      expect(config.host).to eq('https://bugs.kopernici.cz')
    end
  end

  describe '#valid?' do
    it 'returns true when API key is present' do
      allow(config).to receive(:api_key).and_return('test-key')
      expect(config.valid?).to be true
    end

    it 'returns false when API key is nil' do
      allow(config).to receive(:api_key).and_return(nil)
      expect(config.valid?).to be false
    end

    it 'returns false when API key is empty' do
      allow(config).to receive(:api_key).and_return('')
      expect(config.valid?).to be false
    end
  end

  describe '#validate!' do
    it 'raises ConfigError when API key is not valid' do
      allow(config).to receive(:valid?).and_return(false)
      expect { config.validate! }.to raise_error(Bugsink::Config::ConfigError, /BUGSINK_API_KEY/)
    end

    it 'does not raise error when API key is valid' do
      allow(config).to receive(:valid?).and_return(true)
      expect { config.validate! }.not_to raise_error
    end
  end

  describe '#authorization_header' do
    it 'returns Bearer token header' do
      allow(config).to receive(:api_key).and_return('test-key-123')
      expect(config.authorization_header).to eq({ 'Authorization' => 'Bearer test-key-123' })
    end
  end

  describe '#set_project_id' do
    it 'writes project ID to dotfile' do
      dotfile_path = File.join(Dir.pwd, '.bugsink')
      File.delete(dotfile_path) if File.exist?(dotfile_path)

      config.set_project_id(42)
      expect(config.project_id).to eq(42)
      expect(File.exist?(dotfile_path)).to be true
      expect(File.read(dotfile_path)).to eq("PROJECT_ID=42\n")

      File.delete(dotfile_path)
    end
  end

  describe '#project_id_present?' do
    it 'returns true when project_id is set' do
      allow(config).to receive(:project_id).and_return(8)
      expect(config.project_id_present?).to be true
    end

    it 'returns false when project_id is nil' do
      allow(config).to receive(:project_id).and_return(nil)
      expect(config.project_id_present?).to be false
    end
  end

  describe '#to_s' do
    it 'returns configuration summary' do
      allow(config).to receive(:api_key).and_return('test-key-12345678901234567890')
      allow(config).to receive(:host).and_return('https://test.example.com')
      allow(config).to receive(:project_id).and_return(8)

      output = config.to_s
      expect(output).to include('BugSink Configuration')
      expect(output).to include('https://test.example.com')
      expect(output).to include('test-key-')
      expect(output).to include('Project ID: 8')
    end
  end
end
