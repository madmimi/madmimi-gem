#   Mad Mimi - v.0.0.1 the incredibly basic, and barely usable version, in my opinion. (too many stinkin' dependencies!)

#   License

#   Copyright (c) 2010 Mad Mimi (nicholas@madmimi.com)

#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:

#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.

#   Except as contained in this notice, the name(s) of the above copyright holder(s) 
#   shall not be used in advertising or otherwise to promote the sale, use or other
#   dealings in this Software without prior written authorization.

#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#   THE SOFTWARE.

require 'rubygems' # So I can actually have other gems...
require 'rest_client' # Stupid easy HTTP transactions, but I'd rather do them myself.
require 'active_support' # I want to find a way to get away from this, yet I love the Hash.from_xml method!

class MadMimi
  
  BASE_URL = "madmimi.com"
  NEW_LISTS_URL = "/audience_lists"
	AUDIENCE_MEMBERS_URL = "/audience_members"
	AUDIENCE_LISTS_PATH = "/audience_lists/lists.xml?username=%username%&api_key=%api_key%";
	MEMBERSHIPS_URL = "/audience_members/%email%/lists.xml?username=%username%&api_key=%api_key%";
  
  @@api_settings = {}

  def initialize(username, api_key)
    @@api_settings[:username] = username
    @@api_settings[:api_key]  = api_key
  end
  
  def username
    @@api_settings[:username]
  end
  
  def api_key
    @@api_settings[:api_key]
  end

  def prepare_url(url, email = nil)
    url.gsub!('%username%', username)
    url.gsub!('%api_key%', api_key)
    if email != nil
      url.gsub!('%email%', email)
    end
    url
  end
  
  def do_request(path, req_type = :get, options = {})
    resp = href = "";
    case req_type
    when :get
      begin
        http = Net::HTTP.new(BASE_URL, 80)
        http.start do |http|
          req = Net::HTTP::Get.new(path)
          response = http.request(req)
          resp = response.body
        end
        resp
      rescue SocketError
        raise "Host unreachable."
      end
    when :post
    end
  end
    
  def lists
    Hash.from_xml(do_request(prepare_url(AUDIENCE_LISTS_PATH)))
  end
  
  def memberships(email)
    Hash.from_xml(RestClient.get(prepare_url(MEMBERSHIPS_URL, email)).body)
  end
  
  def new_list(list_name)
    RestClient.post(NEW_LISTS_URL, { 'username' => username, 'api_key' => api_key, 'name' => list_name })
  end
  
  def delete_list(list_name)
    RestClient.post("#{NEW_LISTS_URL}/#{list_name.gsub(' ', '%20')}", { 'username' => username, 'api_key' => api_key, '_method' => 'delete'})
  end
  
  def add_user
    # Coming very soon.
  end
  
  def remove_user
    # Coming very soon
  end
  
end