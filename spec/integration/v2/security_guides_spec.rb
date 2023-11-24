# frozen_string_literal: true

require 'swagger_helper'

describe 'Security Guides', swagger_doc: 'v2/openapi.json' do
  let(:identity_header) do
    OpenStruct.new(
      cert_based?: false,
      valid?: true,
      org_id: '1234',
      identity: { org_id: '1234' },
      raw: nil
    )
  end
  let!(:security_guides) do
    SupportedSsg.all.map(&:os_major_version).uniq.map do |os_version|
      FactoryBot.create(
        :v2_security_guide,
        title: 'Guide to the Secure Configuration of Red Hat Enterprise ' \
               "Linux #{os_version}",
        description: 'This guide presents a catalog of security-relevant ' \
                     "configuration settings for Red Hat Enterprise Linux #{os_version}.",
        os_major_version: os_version
      )
    end
  end
  let(:sg_id) { security_guides.first.id }

  before do
    allow(Insights::Api::Common::IdentityHeader).to receive(:new).and_return(identity_header)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  path '/security_guides' do
    get 'List all Security Guides' do
      tags 'security_guide'
      description 'Lists all Security guides'
      operationId 'ListSecurityGuides'
      content_types
      pagination_params_v2
      sort_params_v2(V2::SecurityGuide)
      search_params_v2(V2::SecurityGuide)

      response '200', 'Lists all Security Guides requested' do
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Security Guides') }

        run_test!
      end

      response '200', 'Lists all Security Guides requested' do
        let(:sort_by) { ['os_major_version'] }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Security Guides sorted by "os_major_verision:asc"') }

        run_test!
      end

      response '200', 'Lists all Security Guides requested' do
        let(:filter) { '(os_major_version=8)' }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Security Guides filtered by "(os_major_version=8)"') }

        run_test!
      end

      response '422', 'Returns error if wrong parameters are used' do
        let(:sort_by) { ['description'] }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when sorting by incorrect parameter') }

        run_test!
      end

      response '422', 'Returns error if wrong parameters are used' do
        let(:limit) { 103 }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when requesting higher limit than supported') }

        run_test!
      end
    end
  end

  path '/security_guides/{sg_id}' do
    get 'Returns requested Security Guide' do
      tags 'security_guide'
      description 'Returns requested Security Guide'
      operationId 'ShowSecurityGuide'
      content_types
      parameter name: :sg_id, in: :path, type: :string, required: true

      response '200', 'Returns requested Security Guide' do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('id'),
                     attributes: ref_schema('security_guide')
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Security Guide') }

        run_test!
      end

      response '404', 'Security Guide not found' do
        let(:sg_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Security Guide is not found')
        end

        run_test!
      end
    end
  end

  let!(:profiles) do
    FactoryBot.create_list(
      :v2_profile,
      4,
      security_guide: security_guides.first
    )
  end
  # Need to differenciate between the profile_id that's used in factories and the one that's in the path,
  # so the factory does not throw an error when requesting invalid ID's.
  let(:valid_prof_id) { profiles.first.id }
  let(:prof_id) { valid_prof_id }

  path '/security_guides/{sg_id}/profiles' do
    get 'List all Profiles' do
      tags 'security_guide'
      description 'Lists all Profiles nested under a parent Security Guide'
      operationId 'ListProfiles'
      content_types
      parameter name: :sg_id, in: :path, type: :string, required: true
      pagination_params_v2
      sort_params_v2(V2::Profile)
      search_params_v2(V2::Profile)

      response '200', 'Lists all requested Profiles under a Security Guide' do
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('profiles')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Profiles under a Security Guide') }

        run_test!
      end

      response '200', 'Lists all requested Profiles under a Security Guide' do
        let(:sort_by) { ['title'] }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('profiles')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Profiles under a Security Guide sorted by "title:asc"') }

        run_test!
      end

      response '200', 'Lists all requested Profiles under a Security Guide' do
        let(:filter) { '(ref_id=xccdf_org.ssgproject.content_profile_rht-ccp)' }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('profiles')
                     }
                   }
                 }
               }

        after do |e|
          autogenerate_examples(e, 'List of Profiles under a Security Guide filtered by ' \
                                  '"(ref_id=xccdf_org.ssgproject.content_profile_rht-ccp)"')
        end

        run_test!
      end

      response '422', 'Returns error if wrong parameters are used' do
        let(:sort_by) { ['description'] }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('profiles')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when sorting by incorrect parameter') }

        run_test!
      end

      response '422', 'Returns error if wrong parameters are used' do
        let(:limit) { 103 }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('profiles')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when requesting higher limit than supported') }

        run_test!
      end

      response '404', 'Profile not found' do
        let(:sg_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Profiles are ' \
                                    'under a different or nonexistent Security Guide')
        end

        run_test!
      end
    end
  end

  path '/security_guides/{sg_id}/profiles/{prof_id}' do
    get 'Returns requested Profile' do
      tags 'security_guide'
      description 'Returns requested Profile nested under a parent Security Guide'
      operationId 'ShowProfile'
      content_types
      parameter name: :sg_id, in: :path, type: :string, required: true
      parameter name: :prof_id, in: :path, type: :string, required: true

      response '200', 'Returns requested Profile' do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('id'),
                     attributes: ref_schema('profile')
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Profile') }

        run_test!
      end

      response '404', 'Profile not found' do
        let(:sg_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Profile is ' \
                                    'under a different or nonexistent Security Guide')
        end

        run_test!
      end

      response '404', 'Profile not found' do
        let(:prof_id) { Faker::Internet.uuid }

        after { |e| autogenerate_examples(e, 'Description of an error when the requested Profile is not found') }

        run_test!
      end
    end
  end

  let!(:rules) do
    FactoryBot.create_list(
      :v2_rule,
      3,
      security_guide: security_guides.first,
      profile_id: valid_prof_id
    )
  end
  let(:rule_id) { rules.first.id }

  path '/security_guides/{sg_id}/profiles/{prof_id}/rules' do
    get 'List all Rules' do
      tags 'security_guide'
      description 'Lists all Rules nested under a parent Profile of a Security Guide'
      operationId 'ListRules'
      content_types
      parameter name: :sg_id, in: :path, type: :string, required: true
      parameter name: :prof_id, in: :path, type: :string, required: true
      pagination_params_v2
      sort_params_v2(V2::Rule)
      search_params_v2(V2::Rule)

      response '200', 'Lists all requested Rules under a Profile of a Security Guide' do
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('rules')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Rules under a Profile of a Security Guide') }

        run_test!
      end

      response '200', 'Lists all requested Rules under a Profile of a Security Guide' do
        let(:sort_by) { ['severity'] }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('rules')
                     }
                   }
                 }
               }

        after do |e|
          autogenerate_examples(e, 'List of Rules under a Profile of a Security Guide sorted by "title:asc"')
        end

        run_test!
      end

      response '200', 'Lists all requested Rules under a Profile of a Security Guide' do
        let(:filter) { '(severity=high)' }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('rules')
                     }
                   }
                 }
               }

        after do |e|
          autogenerate_examples(e, 'List of Rules under a Profile of a Security Guide filtered by ' \
                                  '"(severity=high)"')
        end

        run_test!
      end

      response '422', 'Returns error if wrong parameters are used' do
        let(:sort_by) { ['rationale'] }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('rules')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when sorting by incorrect parameter') }

        run_test!
      end

      response '422', 'Returns error if wrong parameters are used' do
        let(:limit) { 103 }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('rules')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when requesting higher limit than supported') }

        run_test!
      end

      response '404', 'Rules not found' do
        let(:sg_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Rules of a Profile are ' \
                                    'under a different or nonexistent Security Guide')
        end

        run_test!
      end

      response '404', 'Rules not found' do
        let(:prof_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Rules are ' \
                                    'under a different or nonexistent Profile')
        end

        run_test!
      end
    end
  end

  path '/security_guides/{sg_id}/profiles/{prof_id}/rules/{rule_id}' do
    get 'Returns requested Rule' do
      tags 'security_guide'
      description 'Returns requested Rule nested under a parent Profile of a Security Guide'
      operationId 'ShowRule'
      content_types
      parameter name: :sg_id, in: :path, type: :string, required: true
      parameter name: :prof_id, in: :path, type: :string, required: true
      parameter name: :rule_id, in: :path, type: :string, required: true

      response '200', 'Returns requested Rule' do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('id'),
                     attributes: ref_schema('rules')
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Rule') }

        run_test!
      end

      response '404', 'Rule not found' do
        let(:sg_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Rule is ' \
                                    'under a different or nonexistent Security Guide')
        end

        run_test!
      end

      response '404', 'Rule not found' do
        let(:prof_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Rule is ' \
                                    'under a different or nonexistent Profile')
        end

        run_test!
      end

      response '404', 'Rule not found' do
        let(:rule_id) { Faker::Internet.uuid }

        after { |e| autogenerate_examples(e, 'Description of an error when the requested Rule is not found') }

        run_test!
      end
    end
  end

  path '/security_guides/{sg_id}/profiles/{prof_id}/rules/{slug}' do
    get 'Returns requested Rule' do
      let(:slug) { rules.first.ref_id.gsub('.', '-') }
      tags 'security_guide'
      description 'Returns requested Rule nested under a parent Profile of a Security Guide by utilizing the slug ' \
                  'format of the ref_id attribute'
      operationId 'ShowRuleBySlug'
      content_types
      parameter name: :sg_id, in: :path, type: :string, required: true
      parameter name: :prof_id, in: :path, type: :string, required: true
      parameter name: :slug, in: :path, type: :string, required: true, description: 'This parameter can be generated ' \
      'from the given rule\'s ref_id attribute by replacing all dots \'.\' with dashes \'-\'.'

      response '200', 'Returns requested Rule' do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('id'),
                     attributes: ref_schema('rules')
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Rule') }

        run_test!
      end

      response '404', 'Rule not found' do
        let(:sg_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Rule is ' \
  'under a different or nonexistent Security Guide')
        end

        run_test!
      end

      response '404', 'Rule not found' do
        let(:prof_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Rule is ' \
                                    'under a different or nonexistent Profile')
        end

        run_test!
      end

      response '404', 'Rule not found' do
        let(:slug) { 'xccdf_org-ssgproject-fake_slug' }

        after { |e| autogenerate_examples(e, 'Description of an error when the requested Rule is not found') }

        run_test!
      end

      response '404', 'Rule not found' do
        let(:slug) { 'xccdf_org-ssgproject-content_rule_file_groupowner_etc_passwd' }

        after { |e| autogenerate_examples(e, 'Description of an error when the slug is in a wrong format') }

        run_test!
      end
    end
  end
end
