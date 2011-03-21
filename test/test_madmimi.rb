require "#{File.dirname(__FILE__)}/helper"

class TestMadmimi < Test::Unit::TestCase
  context "An API call" do
    setup do
      @mimi = MadMimi.new('email@example.com', 'testapikey')
    end
    
    should "retrieve a hash of promotions" do
      stub_get('/promotions.xml', { :filename => 'promotions.xml'})
      response = @mimi.promotions
      flunk "I couldn't find any promotions." unless response.kind_of?(Hash) || !response.empty?
    end
    
    should "retrieve a hash of lists" do
      stub_get('/audience_lists/lists.xml', { :filename => 'lists.xml'})
      response = @mimi.lists
      flunk "Doesn't return any lists." unless response.kind_of?(Hash) || !response.empty?
    end
    
    should "retrieve a hash of users found with the search term nicholas" do
      stub_get('/audience_members/search.xml?query=nicholas', { :filename => 'search.xml'})
      response = @mimi.audience_search('nicholas')
      flunk "No users found." unless response.kind_of?(Hash) || !response.empty?
    end
    
    should "save a raw html promotion" do
      response_body = 'Saved test_promotion (1)'
      stub_post('/promotions/save', { :body =>  response_body })
      response = @mimi.save_promotion('test_promotion', '<html><body>Hi there!<br>[[unsubscribe]][[tracking_beacon]]</body></html>')
      assert_equal response_body, response
    end
    
    should "save a text promotion" do
      response_body = 'Saved test_promotion (1)'
      stub_post('/promotions/save', { :body =>  response_body })
      response = @mimi.save_promotion('test_promotion', nil, "Hi there!\n\n[[unsubscribe]]")
      assert_equal response_body, response
    end
    
    should "raise exception on saving a raw html promotion without the required macros" do
      assert_raises MadMimi::MadMimiError do
        @mimi.save_promotion('test_promotion', '<html><body>Hi there!<br>[[tracking_beacon]]</body></html>')
      end
      
      assert_raises MadMimi::MadMimiError do
        @mimi.save_promotion('test_promotion', '<html><body>Hi there!<br>[[unsubscribe]]</body></html>')
      end
    end

    should "raise exception on saving a plain text promotion without the required macro" do
      assert_raises MadMimi::MadMimiError do
        @mimi.save_promotion('test_promotion', 'Hi there')
      end
    end

    should "get a transactional mailing status" do
      stub_get('/mailers/status/1234', { :https => true, :body => "sent" })
      response = @mimi.status(1234)
      assert_equal "sent", response
    end
  end
end
