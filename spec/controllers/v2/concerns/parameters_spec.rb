# frozen_string_literal: true

require 'rails_helper'

describe V2::ParameterHandling do
  let(:subject) do
    Struct.new(:action_name, :params) do |cls|
      cls::SEARCH = :search # FIXME: delete this after V1 is retired
      include V2::ParameterHandling
    end.new
  end

  describe '#permitted_params' do
    before do
      subject.action_name = action
      subject.params = ActionController::Parameters.new(params)
    end

    shared_examples 'stronger parameter handling' do
      context 'params is empty' do
        let(:params) { {} }

        it 'returns with params' do
          expect(subject.permitted_params).to match(hash_including(params))
        end
      end

      context 'params[:parents] coming from a request' do
        let(:params) { { parents: ['FooBar'] } }

        it 'raises an exception' do
          expect { subject.permitted_params }.to raise_error(StrongerParameters::InvalidParameter)
        end
      end

      context 'params[:parents] coming from a route' do
        let(:params) { { parents: [V2::SecurityGuide] } }

        it 'returns with params' do
          expect(subject.permitted_params).to match(hash_including(params))
        end
      end

      context 'non-UUID parent ID passed with params[:parents]' do
        let(:params) { { parents: [V2::SecurityGuide], security_guide_id: '123456' } }

        it 'raises an exception' do
          expect { subject.permitted_params }.to raise_error(StrongerParameters::InvalidParameter)
        end
      end

      context 'valid parent ID passed with params[:parents]' do
        let(:params) { { parents: [V2::SecurityGuide], security_guide_id: Faker::Internet.uuid } }

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
