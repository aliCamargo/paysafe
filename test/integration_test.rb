require 'test_helper'

class IntegrationTest < Minitest::Test

  def setup
    skip if ENV['SKIP_INTEGRATION_TESTS'] == 'true'

    turn_off_vcr!

    @profile = authenticated_client.create_profile(merchantCustomerId: Time.now.to_f.to_s, locale: 'en_US', firstName: 'test', lastName: 'test', email: 'test@test.com')
    @profile_id = @profile[:id]
  end

  def teardown
    skip if ENV['SKIP_INTEGRATION_TESTS'] == 'true'

    authenticated_client.delete_profile(id: @profile_id)

    @profile_id = nil
    @profile = nil

    turn_on_vcr!
  end

  def test_invalid_credentials
    client = OptimalPayments::REST::Client.new
    assert_raises(OptimalPayments::Error::Unauthorized) {
      client.get_profile(id: @profile_id)
    }
  end

  def test_creating_profile_with_card_and_address
    id = Time.now.to_f.to_s

    profile = authenticated_client.create_profile(
      merchantCustomerId: id,
      locale: 'en_US',
      firstName: 'test',
      lastName: 'test',
      email: 'test@test.com',
      card: {
        cardNum: '4111111111111111',
        cardExpiry: {
          month: 12,
          year: 2019
        },
        billingAddress: {
          country: 'US', zip: '10014'
        }
      }
    )

    assert_kind_of Hash, profile
    assert_equal id, profile[:merchantCustomerId]
    assert_equal 'en_US', profile[:locale]
    assert_equal 'test', profile[:firstName]
    assert_equal 'test', profile[:lastName]
    assert_equal 'test@test.com', profile[:email]
    assert_equal 'ACTIVE', profile[:status]
    refute_predicate profile[:paymentToken], :empty?

    address = profile[:addresses][0]
    assert_kind_of Hash, address
    refute_predicate address[:id], :empty?
    assert_equal 'US', address[:country]
    assert_equal '10014', address[:zip]
    assert_equal 'ACTIVE', address[:status]

    card = profile[:cards][0]
    assert_kind_of Hash, card
    refute_predicate card[:id], :empty?
    assert_equal 12, card[:cardExpiry][:month]
    assert_equal 2019, card[:cardExpiry][:year]
    assert_equal 'ACTIVE', card[:status]
    refute_predicate card[:billingAddressId], :empty?

    authenticated_client.delete_profile(id: profile[:id])
  end

  def test_deleting_a_card
    # 1 - Create Address and attach to Profile
    address = authenticated_client.create_address(profile_id: @profile_id, country: 'US', zip: '10014')

    # 2 - Create Card and attach to Profile
    card = authenticated_client.create_card(profile_id: @profile_id, number: '4111111111111111', month: 12, year: 2019, billingAddressId: address[:id])

    # 3 - Delete Card
    assert authenticated_client.delete_card(profile_id: @profile_id, id: card[:id])

    # 4 - Deleting an already deleted card fails
    assert_raises(OptimalPayments::Error::NotFound) {
      authenticated_client.delete_card(profile_id: @profile_id, id: card[:id])
    }
  end

  def test_invalid_card_number
    assert_raises(OptimalPayments::Error::BadRequest) {
      authenticated_client.create_card(profile_id: @profile_id, number: '4111111111', month: 12, year: 2017)
    }
  end

  def test_updating_a_card
    # 1 - Create Address and attach to Profile
    address = authenticated_client.create_address(profile_id: @profile_id, country: 'US', zip: '10014')
    address_id = address[:id]

    # 2 - Create Card and attach to Profile
    card = authenticated_client.create_card(profile_id: @profile_id, number: '4111111111111111', month: 12, year: 2017, billingAddressId: address_id, holderName: 'John Smith')

    # 3 - Update Card
    card = authenticated_client.update_card(profile_id: @profile_id, id: card[:id], month: 6, year: 2019, billingAddressId: address_id, holderName: 'Johnny Smith')

    assert_kind_of Hash, card
    assert_equal 6, card[:cardExpiry][:month]
    assert_equal 2019, card[:cardExpiry][:year]
    assert_equal address_id, card[:billingAddressId]
    assert_equal 'Johnny Smith', card[:holderName]
    assert_equal 'ACTIVE', card[:status]
  end

  def test_creating_an_address
    # 1 - Create Address and attach to Profile
    address = authenticated_client.create_address(profile_id: @profile_id, country: 'US', zip: '10014')
    first_address_id = address[:id]

    # 2 - Create duplicate Address and attach to Profile
    address = authenticated_client.create_address(profile_id: @profile_id, country: 'US', zip: '10014')
    second_address_id = address[:id]

    refute_equal first_address_id, second_address_id
  end

  def test_full_purchase_flow
    # 1 - Create Address and attach to Profile
    address = authenticated_client.create_address(profile_id: @profile_id, country: 'US', zip: '10014')
    address_id = address[:id]

    # 2 - Create Card and attach to Profile
    card = authenticated_client.create_card(profile_id: @profile_id, number: '4111111111111111', month: 12, year: 2019, billingAddressId: address_id)

    assert_kind_of Hash, card
    refute_predicate card[:id], :empty?
    assert_equal '411111', card[:cardBin]
    assert_equal '1111', card[:lastDigits]
    assert_equal 12, card[:cardExpiry][:month]
    assert_equal 2019, card[:cardExpiry][:year]
    assert_equal 'VI', card[:cardType]
    assert_equal 'ACTIVE', card[:status]
    refute_predicate card[:paymentToken], :empty?

    # 3 - Make a Purchase with Card
    id = Time.now.to_i.to_s
    result = authenticated_client.purchase(amount: 400, token: card[:paymentToken], merchantRefNum: id)

    assert_kind_of Hash, result
    refute_predicate result[:id], :empty?
    assert_equal 400, result[:amount]
    assert_equal true, result[:settleWithAuth]
    assert_equal id, result[:merchantRefNum]
    refute_predicate result[:txnTime], :empty?
    assert_equal 'COMPLETED', result[:status]
    assert_equal 'USD', result[:currencyCode]
    assert_equal 'NOT_PROCESSED', result[:avsResponse]
    refute_predicate result[:card], :empty?
    refute_predicate result[:profile], :empty?
    refute_predicate result[:billingDetails], :empty?
    refute_predicate result[:authCode], :empty?

    # 4 - Delete Card
    card = authenticated_client.delete_card(profile_id: @profile_id, id: card[:id])
  end

end