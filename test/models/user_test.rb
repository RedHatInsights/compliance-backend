# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  should validate_uniqueness_of :redhat_id
  should validate_uniqueness_of :username
  should validate_presence_of :redhat_id
  should validate_presence_of :username
  should belong_to :account

  test 'can be created from a X-RH-IDENTITY JSON' do
    Account.create(account_number: '1333331')
    user = User.from_x_rh_identity(
      JSON.parse(
        <<~X_RH_IDENTITY
          {
            "user_id":"7222222",
            "id":"7222222",
            "username":"foobar@redhat.com",
            "account_id":"9000432",
            "account_number":"1333331",
            "email":"foobar@redhat.com",
            "firstName":"Foo",
            "lastName":"Bar",
            "lang":"en_US",
            "region":"US",
            "login":"foobar@redhat.com",
            "internal":true
          }
        X_RH_IDENTITY
      )
    )
    assert user.valid?
  end
end
