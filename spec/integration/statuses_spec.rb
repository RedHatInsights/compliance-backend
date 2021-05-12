# frozen_string_literal: true

require 'swagger_helper'

describe 'Status API' do
  path "#{Settings.path_prefix}/#{Settings.app_name}/status" do
    get 'status' do
      tags 'status'
      description 'Display Compliance status'
      operationId 'Status'

      content_types

      response '200', 'successful status' do
        schema type: :object,
               properties: {
                 data: ref_schema('status')
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end

      response '500', 'unsuccessful status' do
        before do
          expect(ActiveRecord::Base).to(receive(:connection)).twice do
            OpenStruct.new(active?: false)
          end
        end

        schema type: :object,
               properties: {
                 data: ref_schema('status')
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end
end
