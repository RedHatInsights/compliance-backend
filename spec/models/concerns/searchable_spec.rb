# frozen_string_literal: true

require 'rails_helper'

describe Searchable do
  describe '.validate_search_operators!' do
    it 'allows operators declared for a plain field' do
      expect { Rule.validate_search_operators!('severity = high') }.not_to raise_error
      expect { Rule.validate_search_operators!('severity != high') }.not_to raise_error
    end

    it 'rejects operators not declared for a plain field' do
      expect { Rule.validate_search_operators!('severity > high') }
        .to raise_error(ScopedSearch::QueryNotSupported, /not supported for 'severity'/)
    end

    it 'allows operators declared for an ext_method (block) field' do
      expect { TestResult.validate_search_operators!('failed_rule_severity = low') }.not_to raise_error
      expect { TestResult.validate_search_operators!('failed_rule_severity ^ (high medium)') }.not_to raise_error
    end

    it 'rejects operators not declared for an ext_method (block) field' do
      expect { TestResult.validate_search_operators!('failed_rule_severity != unknown') }
        .to raise_error(ScopedSearch::QueryNotSupported, /not supported for 'failed_rule_severity'/)
      expect { TestResult.validate_search_operators!('failed_rule_severity <> unknown') }
        .to raise_error(ScopedSearch::QueryNotSupported, /not supported for 'failed_rule_severity'/)
    end

    it 'treats the `neq` alias as `ne`' do
      expect { System.validate_search_operators!('display_name != foo') }.not_to raise_error
    end

    it 'validates every field in a compound query' do
      expect { TestResult.validate_search_operators!('(failed_rule_severity = low AND score > 40)') }
        .not_to raise_error
      expect { TestResult.validate_search_operators!('(failed_rule_severity = low AND score ~ 40)') }
        .to raise_error(ScopedSearch::QueryNotSupported, /not supported for 'score'/)
    end

    it 'ignores unknown fields (scoped_search raises its own error later)' do
      expect { Rule.validate_search_operators!('nonexistent = x') }.not_to raise_error
    end

    it 'does nothing for a blank query' do
      expect { Rule.validate_search_operators!(nil) }.not_to raise_error
      expect { Rule.validate_search_operators!('') }.not_to raise_error
    end
  end
end
