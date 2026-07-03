# frozen_string_literal: true

# Factory for selecting the right tailoring file format
class TailoringFile
  def self.new(format: :xml, **hsh)
    return super if self != TailoringFile

    case format
    when :json
      JsonTailoringFile.new(**hsh)
    when :toml
      TomlTailoringFile.new(**hsh)
    when :xml
      XccdfTailoringFile.new(**hsh)
    end
  end

  def filename
    "#{@tailoring.security_guide.ref_id}__#{@tailoring.profile.ref_id}__tailoring.#{extension}"
  end
end
