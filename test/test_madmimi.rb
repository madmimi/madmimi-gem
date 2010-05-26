require 'helper'

class TestMadmimi < Test::Unit::TestCase
  context "A API call" do
    setup do
      @mimi = MadMimi.new('email@example.com', 'testapikey')
      # Stub here?
    end
    should "retrieve a list of promotions" do
      stub_get("/promotions.xml", "promotions.xml")
    end
  end
end
