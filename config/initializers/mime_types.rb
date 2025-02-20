# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

unless Mime::Type.lookup_by_extension(:json)&.to_s == "application/vnd.api+json"
    Mime::Type.unregister(:json) if Mime::Type.lookup_by_extension(:json)
    Mime::Type.register "application/vnd.api+json", :json
end