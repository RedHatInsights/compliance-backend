# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  should validate_uniqueness_of(:username).scoped_to(:account_id)
  should validate_presence_of :username
  should belong_to :account

  test 'can be created from a X-RH-IDENTITY JSON' do
    FactoryBot.create(:account, account_number: '1333331')

    user = User.from_x_rh_identity(
      JSON.parse(
        <<~X_RH_IDENTITY
          {
            "account_number":"1333331",
            "type": "User",
            "user":  {
              "username":"foobar@redhat.com",
              "email":"foobar@redhat.com",
              "first_name":"Foo",
              "last_name":"Bar",
              "locale":"en_US"
            },
            "internal": {
              "org_id": "29329"
            }
          }
        X_RH_IDENTITY
      )
    )
    assert user.valid?
  end
end
