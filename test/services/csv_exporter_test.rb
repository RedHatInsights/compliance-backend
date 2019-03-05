# frozen_string_literal: true

require 'test_helper'

class CsvExporterTest < ActiveSupport::TestCase
  test 'return correct amount of lines' do
    result = CsvExporter.export(Rule, [:id])
    assert_equal "Id\n", result.next
    assert_equal result.count, Rule.count + 1
    assert_difference('CsvExporter.export(Rule, [:id]).count') do
      Rule.create(ref_id: SecureRandom.uuid)
    end
  end

  test 'ignore limit' do
    10.times { Rule.create(ref_id: SecureRandom.uuid) }
    result = CsvExporter.export(Rule.all.limit(5), [:id])
    assert result.count > 5
  end

  test 'handles empty results correctly' do
    result = CsvExporter.export(Rule.where(title: 'no-such-host'), %i[id title])
    assert_equal "Id,Title\n", result.next
    assert_equal 1, result.count
  end

  test 'calls methods on records' do
    id = Rule.first.id
    Rule.any_instance.expects(:test_method).once.returns('success!')
    result = CsvExporter.export(Rule.where(id: id), %i[id test_method])
    assert_equal "Id,Test Method\n", result.next
    assert_equal "#{id},success!\n", result.next
  end

  test 'calls nested methods on records' do
    profile = Profile.first
    profile.update(account: accounts(:test))
    result = CsvExporter.export(Profile, [:ref_id, 'account.account_number'])
    assert_equal "Ref,Account.Account Number\n", result.next
    assert_equal "#{profile.ref_id},#{profile.account.account_number}\n", result.next
  end

  test 'accepts custom column headers' do
    result = CsvExporter.export(Rule, [:id], ['My Lovely Header'])
    assert_equal "My Lovely Header\n", result.next
  end

  test 'ensures correct number of headers' do
    assert_raises ArgumentError do
      CsvExporter.export(Rule, %i[id title], ['Not Enough Headers!'])
    end
  end
end
