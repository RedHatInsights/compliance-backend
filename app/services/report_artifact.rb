# frozen_string_literal: true

# Packs/unpacks a report XML so it can travel as a background-job argument
# instead of being re-downloaded by the job (eliminating the double download).
#
# * gzip  -> XCCDF compresses ~10-20x, keeping the job argument small
# * base64 -> keeps the payload a JSON-safe ASCII string for the job backend
#             (Redis today, PostgreSQL once we move to GoodJob — RHINENG-24397)
module ReportArtifact
  module_function

  def pack(xml)
    Base64.strict_encode64(ActiveSupport::Gzip.compress(xml))
  end

  def unpack(blob)
    ActiveSupport::Gzip.decompress(Base64.strict_decode64(blob))
  end
end
