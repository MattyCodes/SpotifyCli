# Setup of configuration file for the CLI.
module SpotifyCli
  class Setup
    def self.create_keystore_if_necessary!
      # Locate the keystore file if it exists.
      keystore_file= `ls -a ~/ | grep spotify_cli_keystore`

      # Create keystore file if an existing one couldn't be found.
      `touch ~/.spotify_cli_keystore` if keystore_file.empty?
    end
  end
end
