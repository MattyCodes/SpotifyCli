# A small class to store the logic for fetching the
# user's token from the keystore.
module SpotifyCli
  class TokenAccessor
    def self.spotify_access_token
      `cat ~/.spotify_cli_keystore`
    end
  end
end
