# frozen_string_literal: true

require 'swagger_helper'

describe 'RuleResults API' do
  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/rule_results" do
    get 'List all rule_results' do
      fixtures :rules, :hosts, :rule_results
      tags 'rule_result'
      description 'Lists all rule_results requested'
      operationId 'ListRuleResults'

      content_types
      auth_header
      pagination_params
      search_params

      response '200', 'lists all rule_results requested' do
        let(:'X-RH-IDENTITY') do
          Account.create(
            account_number: x_rh_identity[:identity][:account_number]
          )
          user = User.from_x_rh_identity(x_rh_identity[:identity])
          user.save
          hosts(:one).update(account: user.account)
          rule_results(:one).update(host: hosts(:one), rule: rules(:one))
          encoded_header
        end
        schema type: :object,
               properties: {
                 meta: { '$ref' => '#/components/schemas/metadata' },
                 links: { '$ref' => '#/components/schemas/links' },
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: { type: :string, format: :uuid },
                       attributes: {
                         '$ref' => '#/components/schemas/rule_result'
                       }
                     }
                   }
                 }
               }
        examples 'application/vnd.api+json' => {
          meta: { filter: 'result=notselected' },
          data: [
            {
              type: 'Rule Result',
              id: 'd9654ad0-7cb5-4f61-b57c-0d22e3341dcc',
              attributes: {
                result: 'notselected'
              },
              relationships: {
                host: {
                  data: {
                    id: '6b97bc3a-3614-411f-9a9d-4a8a5b041687',
                    type: 'host'
                  }
                },
                rule: {
                  data: {
                    id: '9bi7bc3a-2314-4929-9a9d-4a8a5b041687',
                    type: 'rule'
                  }
                }
              }
            }
          ]
        }
        run_test!
      end
    end
  end
end
