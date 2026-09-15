import Config

# Ash 3.33+ requires an explicit choice of how string length is counted.
# See https://hexdocs.pm/ash/backwards-compatibility-config.html#default_string_length_count
config :ash, default_string_length_count: :codepoints
