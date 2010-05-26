require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'fakeweb'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'madmimi'

class Test::Unit::TestCase
end

def fixture_file(filename)
  return '' if filename == ''
  file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/' + filename)
  File.read(file_path)
end

def madmimi_url(url)
  url =~ /^http/ ? url : "http://api.madmimi.com#{url}"
end

def stub_get(url, filename, status = nil)
  options = { :body => fixture_file(filename) }
  options.merge!({ :status => status }) unless status.nil?
  FakeWeb.register_uri(:get, madmimi_url(url), options)
end