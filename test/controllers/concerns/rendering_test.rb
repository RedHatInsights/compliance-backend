# frozen_string_literal: true

require 'test_helper'

# Tests related to REST API rendering
class RenderingTest < ActionDispatch::IntegrationTest
  class DummySerializer; include FastJsonapi::ObjectSerializer; end
  class DummyController < OpenStruct
    include Rendering

    def initialize
      super(action_name: 'show',
            params: ActionController::Parameters.new,
            serializer: DummySerializer)
    end
  end

  context '#render_error' do
    setup do
      @model = OpenStruct.new(
        errors: OpenStruct.new(full_messages: [:foo.to_s, :bar.to_s])
      )
      @controller = DummyController.new
    end

    should 'accept a single model' do
      @controller.expects(:render)
      @controller.render_error(@model)
    end

    should 'accept multiple models' do
      @controller.expects(:render)
      @controller.render_error([@model, @model])
    end
  end
end
