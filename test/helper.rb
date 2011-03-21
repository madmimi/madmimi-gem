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

def madmimi_url(url, https = false)
  if https
    url =~ /^https/ ? url : "https://api.madmimi.com#{url}"
  else
    url =~ /^http/ ? url : "http://api.madmimi.com#{url}"
  end
end

def stub_get(url, options = {})
  https = options.delete(:https)
  
  filename = options.delete(:filename)
  options = { :body => fixture_file(filename) } if filename
  
  FakeWeb.register_uri(:get, madmimi_url(url, https), options)
end

def stub_post(url, options)
  https = options.delete(:https)
  
  filename = options.delete(:filename)
  options = { :body => fixture_file(filename) } if filename
  
  FakeWeb.register_uri(:post, madmimi_url(url, https), options)
end