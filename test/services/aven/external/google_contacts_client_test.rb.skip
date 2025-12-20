# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class Aven::External::GoogleContactsClientTest < ActiveSupport::TestCase
  MockResponse = Struct.new(:total_items, :connections, :next_page_token, keyword_init: true)
  MockPerson = Struct.new(:resource_name, :names, :email_addresses, :phone_numbers, :organizations, keyword_init: true)
  MockName = Struct.new(:given_name, :family_name, keyword_init: true)
  MockEmail = Struct.new(:value, keyword_init: true)
  MockPhone = Struct.new(:value, keyword_init: true)
  MockOrg = Struct.new(:name, keyword_init: true)

  setup do
    @access_token = "test_access_token"
    @client = Aven::External::GoogleContactsClient.new(@access_token)
  end

  # Initialization
  test "initializes with access token" do
    assert_instance_of Aven::External::GoogleContactsClient, @client
  end

  # contacts_count
  test "contacts_count returns total items" do
    mock_service = Minitest::Mock.new
    mock_response = MockResponse.new(total_items: 42)

    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, mock_response, ["people/me"], person_fields: "metadata", page_size: 1)

    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)
      assert_equal 42, client.contacts_count
    end

    mock_service.verify
  end

  test "contacts_count returns 0 when nil" do
    mock_service = Minitest::Mock.new
    mock_response = MockResponse.new(total_items: nil)

    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, mock_response, ["people/me"], person_fields: "metadata", page_size: 1)

    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)
      assert_equal 0, client.contacts_count
    end

    mock_service.verify
  end

  test "contacts_count raises Error on API failure" do
    mock_service = Minitest::Mock.new
    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, nil) do
      raise Google::Apis::Error.new("API Error")
    end

    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)
      assert_raises(Aven::External::GoogleContactsClient::Error) do
        client.contacts_count
      end
    end
  end

  # each_contact
  test "each_contact yields normalized contacts" do
    mock_service = Minitest::Mock.new
    mock_person = MockPerson.new(
      resource_name: "people/123",
      names: [MockName.new(given_name: "John", family_name: "Doe")],
      email_addresses: [MockEmail.new(value: "john@example.com")],
      phone_numbers: [MockPhone.new(value: "+1234567890")],
      organizations: [MockOrg.new(name: "Acme Corp")]
    )
    mock_response = MockResponse.new(connections: [mock_person], next_page_token: nil)

    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, mock_response, ["people/me"],
      person_fields: Aven::External::GoogleContactsClient::PERSON_FIELDS,
      page_size: Aven::External::GoogleContactsClient::PAGE_SIZE,
      page_token: nil,
      sort_order: "LAST_MODIFIED_DESCENDING")

    contacts = []
    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)
      client.each_contact { |c| contacts << c }
    end

    assert_equal 1, contacts.size
    assert_equal "people/123", contacts.first["google_resource_name"]
    assert_equal "John", contacts.first["first_name"]
    assert_equal "Doe", contacts.first["last_name"]
    assert_equal "john@example.com", contacts.first["email"]
    assert_equal "+1234567890", contacts.first["phone"]
    assert_equal "Acme Corp", contacts.first["company"]

    mock_service.verify
  end

  test "each_contact handles pagination" do
    mock_service = Minitest::Mock.new
    person1 = MockPerson.new(
      resource_name: "people/1",
      names: [MockName.new(given_name: "First")],
      email_addresses: [MockEmail.new(value: "first@example.com")]
    )
    person2 = MockPerson.new(
      resource_name: "people/2",
      names: [MockName.new(given_name: "Second")],
      email_addresses: [MockEmail.new(value: "second@example.com")]
    )
    response1 = MockResponse.new(connections: [person1], next_page_token: "page2")
    response2 = MockResponse.new(connections: [person2], next_page_token: nil)

    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, response1, ["people/me"],
      person_fields: Aven::External::GoogleContactsClient::PERSON_FIELDS,
      page_size: Aven::External::GoogleContactsClient::PAGE_SIZE,
      page_token: nil,
      sort_order: "LAST_MODIFIED_DESCENDING")
    mock_service.expect(:list_person_connections, response2, ["people/me"],
      person_fields: Aven::External::GoogleContactsClient::PERSON_FIELDS,
      page_size: Aven::External::GoogleContactsClient::PAGE_SIZE,
      page_token: "page2",
      sort_order: "LAST_MODIFIED_DESCENDING")

    contacts = []
    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)
      client.each_contact { |c| contacts << c }
    end

    assert_equal 2, contacts.size
    assert_equal "First", contacts.first["first_name"]
    assert_equal "Second", contacts.last["first_name"]

    mock_service.verify
  end

  test "each_contact handles empty connections" do
    mock_service = Minitest::Mock.new
    mock_response = MockResponse.new(connections: nil, next_page_token: nil)

    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, mock_response, ["people/me"],
      person_fields: Aven::External::GoogleContactsClient::PERSON_FIELDS,
      page_size: Aven::External::GoogleContactsClient::PAGE_SIZE,
      page_token: nil,
      sort_order: "LAST_MODIFIED_DESCENDING")

    contacts = []
    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)
      client.each_contact { |c| contacts << c }
    end

    assert_empty contacts
    mock_service.verify
  end

  # fetch_all
  test "fetch_all returns all contacts as array" do
    mock_service = Minitest::Mock.new
    mock_person = MockPerson.new(
      resource_name: "people/123",
      names: [MockName.new(given_name: "Test")],
      email_addresses: [MockEmail.new(value: "test@example.com")]
    )
    mock_response = MockResponse.new(connections: [mock_person], next_page_token: nil)

    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, mock_response, ["people/me"],
      person_fields: Aven::External::GoogleContactsClient::PERSON_FIELDS,
      page_size: Aven::External::GoogleContactsClient::PAGE_SIZE,
      page_token: nil,
      sort_order: "LAST_MODIFIED_DESCENDING")

    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)
      contacts = client.fetch_all
      assert_equal 1, contacts.size
      assert_equal "Test", contacts.first["first_name"]
    end

    mock_service.verify
  end

  # fetch_into_import
  test "fetch_into_import creates entries for import" do
    import = aven_imports(:pending_google)
    import.entries.destroy_all

    mock_service = Minitest::Mock.new
    mock_person = MockPerson.new(
      resource_name: "people/123",
      names: [MockName.new(given_name: "Test")],
      email_addresses: [MockEmail.new(value: "test@example.com")]
    )
    mock_response = MockResponse.new(connections: [mock_person], next_page_token: nil)

    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, mock_response, ["people/me"],
      person_fields: Aven::External::GoogleContactsClient::PERSON_FIELDS,
      page_size: Aven::External::GoogleContactsClient::PAGE_SIZE,
      page_token: nil,
      sort_order: "LAST_MODIFIED_DESCENDING")

    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)

      assert_difference "import.entries.count", 1 do
        count = client.fetch_into_import(import)
        assert_equal 1, count
      end
    end

    entry = import.entries.first
    assert_equal "Test", entry.data["first_name"]
    assert_equal "test@example.com", entry.data["email"]

    mock_service.verify
  end

  test "fetch_into_import calls progress callback" do
    import = aven_imports(:pending_google)
    import.entries.destroy_all

    mock_service = Minitest::Mock.new
    mock_person = MockPerson.new(
      resource_name: "people/123",
      names: [MockName.new(given_name: "Test")],
      email_addresses: [MockEmail.new(value: "test@example.com")]
    )
    mock_response = MockResponse.new(connections: [mock_person], next_page_token: nil)

    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, mock_response, ["people/me"],
      person_fields: Aven::External::GoogleContactsClient::PERSON_FIELDS,
      page_size: Aven::External::GoogleContactsClient::PAGE_SIZE,
      page_token: nil,
      sort_order: "LAST_MODIFIED_DESCENDING")

    progress_calls = []
    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)
      client.fetch_into_import(import) { |count| progress_calls << count }
    end

    assert_equal [1], progress_calls
    mock_service.verify
  end

  # Normalization edge cases
  test "normalizes contact with missing fields" do
    mock_service = Minitest::Mock.new
    mock_person = MockPerson.new(
      resource_name: "people/123",
      names: nil,
      email_addresses: nil,
      phone_numbers: nil,
      organizations: nil
    )
    mock_response = MockResponse.new(connections: [mock_person], next_page_token: nil)

    mock_service.expect(:authorization=, nil, [@access_token])
    mock_service.expect(:list_person_connections, mock_response, ["people/me"],
      person_fields: Aven::External::GoogleContactsClient::PERSON_FIELDS,
      page_size: Aven::External::GoogleContactsClient::PAGE_SIZE,
      page_token: nil,
      sort_order: "LAST_MODIFIED_DESCENDING")

    contacts = []
    Google::Apis::PeopleV1::PeopleServiceService.stub(:new, mock_service) do
      client = Aven::External::GoogleContactsClient.new(@access_token)
      client.each_contact { |c| contacts << c }
    end

    assert_equal 1, contacts.size
    assert_equal "people/123", contacts.first["google_resource_name"]
    assert_nil contacts.first["first_name"]
    assert_nil contacts.first["email"]

    mock_service.verify
  end
end
