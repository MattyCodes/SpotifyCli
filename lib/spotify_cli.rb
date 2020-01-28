require "spotify_cli/version"

module SpotifyCli
  # Generic error class definition.
  class Error < StandardError; end

  # Require the necessary classes/modules.
  require 'spotify_cli/setup'
  require 'spotify_cli/authentication'
  require 'spotify_cli/initialization'
end
