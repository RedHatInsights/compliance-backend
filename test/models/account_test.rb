# frozen_string_literal: true

require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  should have_many :users
  should have_many :hosts
  should have_many :profiles
  should have_many :policies
  should have_many(:business_objectives).through(:policies)
  should validate_presence_of :org_id

  context '.from_identity_header' do
    should 'find an existing account' do
      acc = FactoryBot.create(:account, account_number: nil)
      ih = IdentityHeader.new(Base64.encode64({
        'identity' => {
          'org_id' => acc.org_id
        }
      }.to_json))

      assert_difference('Account.count' => 0) do
        assert_equal Account.from_identity_header(ih).id, acc.id
      end
    end

    should 'create an account if new' do
      ih = IdentityHeader.new(Base64.encode64({
        'identity' => {
          'org_id' => '123456'
        }
      }.to_json))

      assert_difference('Account.count' => 1) do
        Account.from_identity_header(ih)
      end
    end

    should 'update the is_internal field if set' do
      ih = IdentityHeader.new(Base64.encode64({
        'identity' => {
          'org_id' => '123456',
          'user' => {
            'is_internal' => true
          }
        }
      }.to_json))

      acc = Account.from_identity_header(ih)

      assert acc.is_internal
    end

    should 'update the org_id field if set' do
      ih = IdentityHeader.new(Base64.encode64({
        'identity' => {
          'org_id' => '654321'
        }
      }.to_json))

      acc = Account.from_identity_header(ih)
      assert_equal acc.org_id, '654321'
    end

    should 'update the account_number field if set for an existing account' do
      acc = FactoryBot.create(:account, account_number: nil)
      ih = IdentityHeader.new(Base64.encode64({
        'identity' => {
          'org_id' => acc.org_id,
          'account_number' => '654321'
        }
      }.to_json))

      Account.from_identity_header(ih)
      assert_equal acc.reload.account_number, '654321'
    end
  end
end
