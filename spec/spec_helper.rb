require 'bundler/setup'
Bundler.setup

require 'madmimi'
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/cassettes'
  c.configure_rspec_metadata!
end

RSpec.configure do |c|

end
