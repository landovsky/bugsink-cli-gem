# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bugsink::Config do
  let(:config) { described_class.new }

  describe '#initialize' do
    it 'reads BUGSINK_API_KEY from environment' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return('test-key')
      allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return(nil)
      allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

      config = described_class.new
      expect(config.api_key).to eq('test-key')
    end

    it 'uses default host when BUGSINK_HOST not set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return('test-key')
      allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return(nil)
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

  describe '#read_project_id' do
    let(:dotfile_path) { File.join(Dir.pwd, '.bugsink') }

    before do
      File.delete(dotfile_path) if File.exist?(dotfile_path)
    end

    after do
      File.delete(dotfile_path) if File.exist?(dotfile_path)
    end

    context 'when BUGSINK_PROJECT_ID is set' do
      it 'returns project ID from environment variable' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return('42')
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        config = described_class.new
        expect(config.project_id).to eq(42)
      end

      it 'ignores .bugsink file when env var is set' do
        File.write(dotfile_path, "PROJECT_ID=99\n")

        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return('42')
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        config = described_class.new
        expect(config.project_id).to eq(42)
      end

      it 'returns nil for invalid env var value' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return('invalid')
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        config = described_class.new
        expect(config.project_id).to be_nil
      end

      it 'returns nil for zero value' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return('0')
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        config = described_class.new
        expect(config.project_id).to be_nil
      end

      it 'returns nil for negative value' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return('-5')
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        config = described_class.new
        expect(config.project_id).to be_nil
      end

      it 'returns nil for empty string' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return('')
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        config = described_class.new
        expect(config.project_id).to be_nil
      end
    end

    context 'when BUGSINK_PROJECT_ID is not set' do
      it 'reads from .bugsink file' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        File.write(dotfile_path, "PROJECT_ID=99\n")

        config = described_class.new
        expect(config.project_id).to eq(99)
      end

      it 'returns nil when file does not exist' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        config = described_class.new
        expect(config.project_id).to be_nil
      end
    end
  end

  describe '#set_project_id' do
    let(:dotfile_path) { File.join(Dir.pwd, '.bugsink') }

    before do
      File.delete(dotfile_path) if File.exist?(dotfile_path)
    end

    after do
      File.delete(dotfile_path) if File.exist?(dotfile_path)
    end

    context 'when BUGSINK_PROJECT_ID is set' do
      it 'does not create .bugsink file' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return('42')
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        config = described_class.new

        config.set_project_id(99)
        expect(config.project_id).to eq(99)  # Updates in-memory value
        expect(File.exist?(dotfile_path)).to be false  # File not created
      end
    end

    context 'when BUGSINK_PROJECT_ID is not set' do
      it 'creates .bugsink file as normal' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('BUGSINK_API_KEY').and_return(nil)
        allow(ENV).to receive(:fetch).with('BUGSINK_HOST', anything).and_return('https://bugs.kopernici.cz')

        config = described_class.new

        config.set_project_id(42)
        expect(config.project_id).to eq(42)
        expect(File.exist?(dotfile_path)).to be true
        expect(File.read(dotfile_path)).to eq("PROJECT_ID=42\n")
      end
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
    it 'returns configuration summary with project from file' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return(nil)
      allow(config).to receive(:api_key).and_return('test-key-12345678901234567890')
      allow(config).to receive(:host).and_return('https://test.example.com')
      allow(config).to receive(:project_id).and_return(8)

      output = config.to_s
      expect(output).to include('BugSink Configuration')
      expect(output).to include('https://test.example.com')
      expect(output).to include('test-key-')
      expect(output).to include('Project ID: 8 (from file)')
    end

    it 'returns configuration summary with project from env' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return('42')
      allow(config).to receive(:api_key).and_return('test-key-12345678901234567890')
      allow(config).to receive(:host).and_return('https://test.example.com')
      allow(config).to receive(:project_id).and_return(42)

      output = config.to_s
      expect(output).to include('BugSink Configuration')
      expect(output).to include('https://test.example.com')
      expect(output).to include('test-key-')
      expect(output).to include('Project ID: 42 (from env)')
    end

    it 'returns configuration summary when project not set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('BUGSINK_PROJECT_ID').and_return(nil)
      allow(config).to receive(:api_key).and_return('test-key-12345678901234567890')
      allow(config).to receive(:host).and_return('https://test.example.com')
      allow(config).to receive(:project_id).and_return(nil)

      output = config.to_s
      expect(output).to include('BugSink Configuration')
      expect(output).to include('https://test.example.com')
      expect(output).to include('test-key-')
      expect(output).to include('Project ID: not set')
    end
  end
end
