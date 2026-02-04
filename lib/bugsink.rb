# frozen_string_literal: true

require_relative 'bugsink/version'
require_relative 'bugsink/config'
require_relative 'bugsink/client'
require_relative 'bugsink/cli'

module Bugsink
  class Error < StandardError; end
end
