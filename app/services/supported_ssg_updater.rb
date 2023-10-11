# frozen_string_literal: true

# This class updates supported SSGs yaml
class SupportedSsgUpdater
  require 'yaml'

  KEYS_TO_REMOVE = %w[upstream_version brew_url].freeze

  def self.run!
    SsgConfigDownloader.update_ssg_ds # Populate the datastream file if nonexistent
    supported_ssg = YAML.safe_load_file(SsgConfigDownloader::DS_FILE_PATH)

    remove_keys(supported_ssg)

    File.open(SsgConfigDownloader::DS_FALLBACK_PATH, 'w') { |file| file.write(YAML.dump(supported_ssg)) }
  end

  def self.search_through(object, &block)
    if object.instance_of?(Hash)
      object.each do |key, value|
        block.call(key, value, object)
        search_through(value, &block)
      end
    elsif object.instance_of?(Array)
      object.each { |el| search_through(el, &block) }
    end
  end

  def self.remove_keys(hash)
    # remove undesired keys
    search_through(hash) do |key, value, current_hash|
      if key == 'profiles'
        value.each do |name, profile|
          value[name] = nil unless profile.instance_of?(Hash) && profile.key?('old_names')
        end
      end
      current_hash.except!(key) if KEYS_TO_REMOVE.include?(key)
    end
  end
end
