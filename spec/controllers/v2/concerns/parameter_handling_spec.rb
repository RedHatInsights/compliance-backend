# frozen_string_literal: true

require 'rails_helper'

describe V2::ParameterHandling do
  let(:subject) do
    Struct.new(:action_name, :params, :resource) do
      include V2::ParameterHandling
    end.new
  end

  describe '#permitted_params' do
    before do
      subject.action_name = action
      subject.params = ActionController::Parameters.new(params)
      subject.resource = double
      allow(subject.resource).to receive(:reflect_on_association).and_return(reflection)
    end

    let(:reflection) { OpenStruct.new(foreign_key: :security_guide_id) }

    shared_examples 'stronger parameter handling' do
      context 'params is empty' do
        let(:params) { {} }

        it 'returns with params' do
          expect(subject.permitted_params).to match(hash_including(params))
        end
      end

      context 'params[:parents] coming from a request' do
        let(:params) { { parents: ['foobar'] } }

        it 'raises an exception' do
          expect { subject.permitted_params }.to raise_error(StrongerParameters::InvalidParameter)
        end
      end

      context 'params[:parents] coming from a route' do
        let(:params) { { parents: [:foobar] } }

        it 'returns with params' do
          expect(subject.permitted_params).to match(hash_including(params))
        end
      end

      context 'params[:parents] with an invalid reflection' do
        let(:params) { { parents: [:security_guide], security_guide_id: '123456' } }
        let(:reflection) { nil }

        it 'raises an exception' do
          expect { subject.permitted_params }.to raise_error(ActionController::UnpermittedParameters)
        end
      end

      context 'non-UUID parent ID passed with params[:parents]' do
        let(:params) { { parents: [:security_guide], security_guide_id: '123456' } }

        it 'raises an exception' do
          expect { subject.permitted_params }.to raise_error(StrongerParameters::InvalidParameter)
        end
      end

      context 'valid parent ID passed with params[:parents]' do
        let(:params) { { parents: [:security_guide], security_guide_id: Faker::Internet.uuid } }

        it 'raises an exception' do
          expect(subject.permitted_params).to match(hash_including(params))
        end
      end
    end

    context 'index' do
      let(:action) { :index }

      context 'valid params[:id]' do
        let(:params) { { id: Faker::Internet.uuid } }

        it 'raises an exception' do
          expect { subject.permitted_params }.to raise_error(ActionController::UnpermittedParameters)
        end
      end

      include_examples 'stronger parameter handling'
    end

    context 'show' do
      let(:action) { :show }

      context 'valid params[:id]' do
        let(:params) { { id: Faker::Internet.uuid } }

        it 'returns with params' do
          expect(subject.permitted_params).to match(hash_including(params))
        end
      end

      include_examples 'stronger parameter handling'
    end
  end
end
