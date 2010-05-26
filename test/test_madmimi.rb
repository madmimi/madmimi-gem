require 'helper'

class TestMadmimi < Test::Unit::TestCase
  context "A API call" do
    setup do
      @mimi = MadMimi.new('test-user-email', 'test-api-key')
    end
    should "return nothing when creating a new list" do
      assert_equal "", @mimi.new_list('New Test List')
    end
  end
end
