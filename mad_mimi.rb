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

require 'rubygems' # So I can actually have other gems... All I need to do is ditch activesupport, and I'm good to ditch this one
require 'uri'
require 'net/http'
require 'net/https'
require 'active_support' # I want to find a way to get away from this, yet I love the Hash.from_xml method!

class MadMimi
  
  BASE_URL = "madmimi.com"
  NEW_LISTS_PATH = "/audience_lists"
  AUDIENCE_MEMBERS_PATH = "/audience_members"
  AUDIENCE_LISTS_PATH = "/audience_lists/lists.xml"
  MEMBERSHIPS_PATH = "/audience_members/%email%/lists.xml"
  SUPPRESSED_SINCE_PATH = "/audience_members/suppressed_since/%timestamp%.txt"
  PROMOTIONS_PATH = "/promotions.xml"
  MAILING_STATS_PATH = "/promotions/%promotion_id%/mailings/%mailing_id%.xml"
  
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
  
  def default_opt
    { 'username' => username, 'api_key' => api_key }
  end
  
  # Refactor this method asap
  def do_request(path, req_type = :get, options = {})
    resp = href = "";
    case req_type
    when :get then
      begin
        http = Net::HTTP.new(BASE_URL, 80)
        http.start do |http|
          req = Net::HTTP::Get.new(path)
          req.set_form_data(options)
          response = http.request(req)
          resp = response.body
        end
        resp
      rescue SocketError
        raise "Host unreachable."
      end
    when :post then
      begin
        http = Net::HTTP.new(BASE_URL, 80)
        http.start do |http|
          req = Net::HTTP::Post.new(path)
          req.set_form_data(options)
          response = http.request(req)
          resp = response.body
        end
      rescue SocketError
        raise "Host unreachable."
      end
    end
  end
    
  def lists
    request = do_request(AUDIENCE_LISTS_PATH, :get, default_opt)
    Hash.from_xml(request)
  end
  
  def memberships(email)
    request = do_request((MEMBERSHIPS_PATH.gsub('%email%', email)), :get, default_opt)
    Hash.from_xml(request)
  end
  
  def new_list(list_name)
    options = { 'name' => list_name }
    do_request(prepare_url(NEW_LISTS_PATH), :post, options.merge(default_opt))
  end
  
  def delete_list(list_name)
    options = { '_method' => 'delete' }
    do_request(prepare_url(NEW_LISTS_PATH + "/" + URI.escape(list_name)), :post, options.merge(default_opt))
  end
  
  def csv_import(csv_string)
    options = { 'csv_file' => csv_string }
    do_request(AUDIENCE_MEMBERS_PATH, :post, options.merge(default_opt))
  end
  
  def add_to_list(email, list_name)
    options = { 'email' => email }
    do_request(prepare_url(NEW_LISTS_PATH + "/" + URI.escape(list_name) + "/add"), :post, options.merge(default_opt))
  end
  
  def remove_from_list(email, list_name)
    options = { 'email' => email }
    do_request(prepare_url(NEW_LISTS_PATH + "/" + URI.escape(list_name) + "/remove"), :post, options.merge(default_opt))
  end
  
  def suppressed_since(timestamp)
    do_request((SUPPRESSED_SINCE_PATH.gsub('%timestamp%', timestamp)), :get, default_opt)
  end
  
  def promotions
    request = do_request(PROMOTIONS_PATH, :get, default_opt)
    Hash.from_xml(request)
  end
  
  def mailing_stats(promotion_id, mailing_id)
    path = (MAILING_STATS_PATH.gsub('%promotion_id%', promotion_id).gsub('%mailing_id%', mailing_id))
    request = do_request(path, :get, default_opt)
    Hash.from_xml(request)
  end
end