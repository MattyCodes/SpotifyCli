# A small class to store the logic for fetching the
# user's tokens from the keystore.
module SpotifyCli
  class TokenAccessor
    # Read and evaluate the contents of the keystore as a hash.
    def self.spotify_token_hash
      eval(`cat ~/.spotify_cli_keystore`) || {}
    end

    # Retrieve the user's access token from the keystore.
    def self.spotify_access_token
      spotify_token_hash[:access_token]
    end

    # Retrieve the user's refresh token from the keystore.
    def self.spotify_refresh_token
      spotify_token_hash[:refresh_token]
    end
  end
end
