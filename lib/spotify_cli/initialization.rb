# Initialization of the CLI, this handles the configuration and authentication
# of the spotify integration and initializes the interface.
module SpotifyCli
  module Initialization
    def initialize_cli!
      ::SpotifyCli::Setup.create_keystore_if_necessary!
      ::SpotifyCli::Authentication.authenticate_user_if_necessary!
    end
  end
end
