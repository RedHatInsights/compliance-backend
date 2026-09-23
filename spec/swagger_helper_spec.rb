# frozen_string_literal: true

require 'swagger_helper'

describe 'swagger_helper filter documentation' do
  describe '#format_search_operators' do
    it 'maps scoped_search operators to query-language tokens' do
      expect(format_search_operators(%i[eq in])).to eq('`=`, `^`')
    end

    it 'renders comparison and text operators' do
      expect(format_search_operators(%i[eq ne like unlike])).to eq('`=`, `!=`, `~`, `!~`')
    end

    it 'treats `neq` as `ne` and de-duplicates tokens' do
      expect(format_search_operators(%i[neq notin])).to eq('`!=`, `!^`')
    end

    it 'returns nil when there are no operators' do
      expect(format_search_operators([])).to be_nil
      expect(format_search_operators(nil)).to be_nil
    end
  end

  describe '#search_attributes_sentence' do
    it 'renders each attribute with its declared operators sourced from scoped_search' do
      sentence = search_attributes_sentence(TestResult, [])

      expect(sentence).to include('`failed_rule_severity` (`=`, `^`)')
      expect(sentence).to include('`score` (`=`, `>`, `<`, `>=`, `<=`)')
    end
  end
end
