# frozen_string_literal: true

module Xccdf
  # Maps OVAL regex banner value refs to plaintext banner value refs introduced in
  # scap-security-guide 0.1.81 (RHEL-118499). Remediations use *_banner_contents;
  # check-export still references *_banner_text.
  module BannerValueMappings
    BANNER_TEXT_TO_CONTENTS = {
      'xccdf_org.ssgproject.content_value_login_banner_text' =>
        'xccdf_org.ssgproject.content_value_login_banner_contents',
      'xccdf_org.ssgproject.content_value_remote_login_banner_text' =>
        'xccdf_org.ssgproject.content_value_remote_login_banner_contents',
      'xccdf_org.ssgproject.content_value_motd_banner_text' =>
        'xccdf_org.ssgproject.content_value_motd_banner_contents',
      'xccdf_org.ssgproject.content_value_dconf_login_banner_text' =>
        'xccdf_org.ssgproject.content_value_dconf_login_banner_contents'
    }.freeze
  end
end
