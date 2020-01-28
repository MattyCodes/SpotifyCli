require_relative 'token_accessor'

# Authenticating with Spotify's API and storing the user's
# access token in the keystore file: `~/.spotify_cli_keystore`.
module SpotifyCli
  class Authentication < SpotifyCli::TokenAccessor
    def self.authenticate_user_if_necessary!
      puts "Here is the token: #{spotify_access_token}"
    end
  end
end
