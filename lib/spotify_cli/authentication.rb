require_relative 'token_accessor'
require 'socket'
require 'httparty'

# Authenticating with Spotify's API and storing the user's
# access token in the keystore file: `~/.spotify_cli_keystore`.
module SpotifyCli
  class Authentication < SpotifyCli::TokenAccessor
    # Authenticate with Spotify if the keystore does
    # not contain an access token already.
    def self.authenticate_user_if_necessary!
      return unless spotify_access_token.nil?

      direct_user_to_authorization_url
      await_response_from_spotify_and_request_access_token
      ensure_that_a_token_was_stored_successfully
    end

    # Refresh the user's access token using the refresh token from
    # the local keystore (if it exists), and update the keystore accordingly.
    def self.refresh_the_access_token!
      return if spotify_refresh_token.nil?

      request_refreshed_access_token_and_store_results
      ensure_that_a_token_was_stored_successfully
    end

    # Process a request to Spotify for refreshing a user's access token. It
    # might be worth refactoring this convention of making requests with
    # HTTParty, since it is becoming repetitive.
    def self.request_refreshed_access_token_and_store_results
     request_body = {
        grant_type: 'refresh_token',
        refresh_token: spotify_refresh_token,
        client_id: ENV['SPOTIFY_CLI_CLIENT_ID'],
        client_secret: ENV['SPOTIFY_CLI_CLIENT_SECRET']
      }

      request_headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
      }

      request_response = HTTParty.post(
        'https://accounts.spotify.com/api/token',
        body: request_body,
        headers: request_headers
      )

      handle_the_resulting_tokens(
        access_token: request_response['access_token'],
        refresh_token: spotify_refresh_token
      )
    end

    # Note that this will currently only work for MacOS, because linux requires
    # other, more specific steps to be taken in order to open browsers.
    def self.direct_user_to_authorization_url
      `open "#{authorization_url}"`
    end

    # Recursively retrieve the full response from Spotify.
    def self.retrieve_full_response_from_client(client, response = '')
      # Grab the next line from the response body, excluding newline characters.
      line_to_add = client.gets.chomp

      # If the remaining lines are empty then return the captured response,
      # otherwise give the response body another pass.
      if line_to_add.empty?
        response
      else
        response += line_to_add
        retrieve_full_response_from_client(client, response)
      end
    end

    # Create a server and listen for a call to port 8888; once Spotify provides
    # a `code` value it can be exchanged for an access token via a POST request.
    def self.await_response_from_spotify_and_request_access_token
      # Listen out for a response on port 8888. 
      server = TCPServer.new 8888 

      # Create a string to store the full response from Spotify.
      full_response = ''

      # Iterate through each line of the request from spotify, and
      # store it in the full response variable until there are none left.
      until !full_response.empty? do
        client        = server.accept
        full_response = retrieve_full_response_from_client(client)
      end

      # Respond to the request, and close the server.
      client.print "HTTP/1.1 200\r\n" \
                   "Content-Type: text/html\r\n\r\n" \
                   'Authentication complete, you may close this window.'
      
      client.close
      server.close

      # Extract the `code` parameter from the request body.
      response_code = full_response.split(' ')[1].split('code=')[1]

      # Use the resulting code to request a Spotify access token.
      request_an_access_token_with response_code
    end

    # Exchange a response-code for an access token.
    def self.request_an_access_token_with(code)
      request_body = {
        grant_type: 'authorization_code',
        client_id: ENV['SPOTIFY_CLI_CLIENT_ID'],
        client_secret: ENV['SPOTIFY_CLI_CLIENT_SECRET'],
        code: code,
        redirect_uri: 'http://localhost:8888/spotify-cli'
      }

      request_headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
      }

      request_response = HTTParty.post(
        'https://accounts.spotify.com/api/token',
        body: request_body,
        headers: request_headers
      )

      handle_the_resulting_tokens(
        access_token: request_response['access_token'],
        refresh_token: request_response['refresh_token']
      )
    end

    # Store the given access token in the keystore, or
    # raise an error if no access token was provided.
    def self.handle_the_resulting_tokens(token_hash)
      if token_hash[:access_token].nil? || token_hash[:refresh_token].nil?
        raise 'Authentication failed! No token was provided.'
      else
        # Empty the contents of the keystore.
        `> ~/.spotify_cli_keystore`

        # Write the hash of tokens to the keystore.
        `echo '#{token_hash}' >> ~/.spotify_cli_keystore`
      end
    end

    # Raise an error if, at the end of the authentication process, there
    # is still no access token in the local keystore.
    def self.ensure_that_a_token_was_stored_successfully
      return unless spotify_access_token.nil?
      return unless spotify_refresh_token.nil?

      raise 'Authentication failed! ' \
            'No token could be found.'
    end

    # Construct the authorization URL with the given client ID.
    def self.authorization_url
      'https://accounts.spotify.com/authorize?' \
      "client_id=#{ENV['SPOTIFY_CLI_CLIENT_ID']}&" \
      'response_type=code&redirect_uri=http://localhost:8888/spotify-cli&' \
      'scope=user-read-private%20user-read-playback-state%20' \
      'user-modify-playback-state%20user-read-currently-playing%20' \
      'streaming%20app-remote-control%20playlist-read-private%20' \
      'user-library-read%20user-follow-read%20playlist-modify-private'
    end
  end
end
