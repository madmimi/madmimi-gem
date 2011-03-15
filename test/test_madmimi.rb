require 'helper'

class TestMadmimi < Test::Unit::TestCase
  context "An API call" do
    setup do
      @mimi = MadMimi.new('email@example.com', 'testapikey')
    end
    
    should "retrieve a hash of promotions" do
      stub_get('/promotions.xml', 'promotions.xml')
      response = @mimi.promotions
      flunk "I couldn't find any promotions." unless response.kind_of?(Hash) || !response.empty?
    end
    
    should "retrieve a hash of lists" do
      stub_get('/audience_lists/lists.xml', 'lists.xml')
      response = @mimi.lists
      flunk "Doesn't return any lists." unless response.kind_of?(Hash) || !response.empty?
    end
    
    should "retrieve a hash of users found with the search term nicholas" do
      stub_get('/audience_members/search.xml?query=nicholas', 'search.xml')
      response = @mimi.audience_search('nicholas')
      flunk "No users found." unless response.kind_of?(Hash) || !response.empty?
    end
    
    should "get a transactional mailing status" do
      stub_get('/mailers/status/1234', 'status.txt')
      response = @mimi.status(1234)
      assert_equal "sent", response
    end
  end
end
