# frozen_string_literal: true

require 'deep_merge'

# A class representing a TOML Tailoring File
class TomlTailoringFile < TailoringFile
  def initialize(profile:, **_hsh)
    @tailoring = profile
  end

  def mime
    'application/toml'
  end

  def extension
    'toml'
  end

  def output
    TOML::Generator.new(build_profile).body
  end

  def empty?
    false
  end

  private

  def build_profile
    {
      'name' => @tailoring.profile.title,
      'description' => @tailoring.profile.description,
      'version' => @tailoring.profile.security_guide.version
    }.merge(build_fixes)
  end

  def build_fixes
    Fix.where(rule: @tailoring.rules, system: Fix::BLUEPRINT).reduce({}) do |obj, fix|
      obj.deep_merge(TOML.load(fix.text))
    end
  end
end
