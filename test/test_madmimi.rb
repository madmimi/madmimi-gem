require 'helper'

class TestMadmimi < Test::Unit::TestCase
  context "A API call" do
    setup do
      @mimi = MadMimi.new('email@example.com', 'testapikey')
    end
    
    should "retrieve a hash of promotions" do
      stub_get('/promotions.xml', 'promotions.xml')
      response = @mimi.promotions
      flunk unless response.kind_of?(Hash)
    end
    
    should "retrieve a hash of lists" do
      stub_get('/audience_lists/lists.xml', 'lists.xml')
      response = @mimi.lists
      flunk "Doesn't return any lists." unless response.kind_of?(Hash)
    end
    
    should "retrieve a hash of users found with the search term nicholas" do
      stub_get('/audience_members/search.xml?query=nicholas', 'search.xml')
      response = @mimi.audience_search('nicholas')
      flunk "No users found" unless response.kind_of?(Hash)
    end
  end
end
