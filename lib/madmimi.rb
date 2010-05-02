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

require 'uri'
require 'net/http'
require 'net/https'
require 'active_support' # I want to find a way to get away from this, yet I love the Hash.from_xml method!

class MadMimi
  
  BASE_URL = "api.madmimi.com"
  NEW_LISTS_PATH = "/audience_lists"
  AUDIENCE_MEMBERS_PATH = "/audience_members"
  AUDIENCE_LISTS_PATH = "/audience_lists/lists.xml"
  MEMBERSHIPS_PATH = "/audience_members/%email%/lists.xml"
  SUPPRESSED_SINCE_PATH = "/audience_members/suppressed_since/%timestamp%.txt"
  PROMOTIONS_PATH = "/promotions.xml"
  MAILING_STATS_PATH = "/promotions/%promotion_id%/mailings/%mailing_id%.xml"
  SEARCH_PATH = "/audience_members/search.xml"
  
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
  def do_request(path, req_type = :get, options = {}, transactional = false)
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
        if transactional == true
          http = Net::HTTP.new(BASE_URL, 443)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        else
          http = Net::HTTP.new(BASE_URL, 80)
        end
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
    do_request(NEW_LISTS_PATH, :post, options.merge(default_opt))
  end
  
  def delete_list(list_name)
    options = { '_method' => 'delete' }
    do_request(NEW_LISTS_PATH + "/" + URI.escape(list_name), :post, options.merge(default_opt))
  end
  
  def csv_import(csv_string)
    options = { 'csv_file' => csv_string }
    do_request(AUDIENCE_MEMBERS_PATH, :post, options.merge(default_opt))
  end
  
  def build_csv(hash)
    csv = ""
    hash.keys.each do |key|
      csv << "#{key},"
    end
    # strip out one char at the end
    csv << "\n"
    csv = csv[0..-1]
    hash.values.each do |value|
      csv << "#{value},"
    end
    csv = csv[0..-1]
    csv << "\n"
  end
  
  def add_user(options)
    csv_data = build_csv(options)
    opt = { 'csv_file' => csv_data }
    do_request(AUDIENCE_MEMBERS_PATH, :post, opt.merge(default_opt))
  end
  
  def add_to_list(email, list_name)
    options = { 'email' => email }
    do_request(NEW_LISTS_PATH + "/" + URI.escape(list_name) + "/add", :post, options.merge(default_opt))
  end
  
  def remove_from_list(email, list_name)
    options = { 'email' => email }
    do_request(NEW_LISTS_PATH + "/" + URI.escape(list_name) + "/remove", :post, options.merge(default_opt))
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
  
  def audience_search(query_string, raw = false)
    options = { 'raw' => raw, 'query' => query_string }
    request = do_request(SEARCH_PATH, :get, options.merge(default_opt))
    Hash.from_xml(request)
  end
  
  def send_mail(opt, yaml_body)
    opt['body'] = yaml_body.to_yaml
    do_request('/mailer', :post, opt.merge(default_opt), true)
  end
end