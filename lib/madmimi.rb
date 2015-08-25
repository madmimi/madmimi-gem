#   Mad Mimi for Ruby

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

require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'uri'
require 'rubygems'
require 'httparty'
require 'csv'
require 'yaml'
if RUBY_VERSION != '1.8.7' && RUBY_VERSION < '2.2.0'
  YAML::ENGINE.yamler = "syck"
end
require 'crack'

class MadMimi

  MadMimiError = Class.new(StandardError)

  include HTTParty

  base_uri 'api.madmimi.com'

  parser(
    Proc.new do |body, format|
      begin
        case format
        when :json
          Crack::JSON.parse(body)
        when :xml
          Crack::XML.parse(body)
        else
          body
        end
      rescue Crack::ParseError, REXML::ParseException
        body
      end
    end
  )

  def initialize(username, api_key, options = {})
    @api_settings = options.reverse_merge({
      :verify_ssl => true
    }).merge({
      :username   => username,
      :api_key    => api_key
    })
  end

  def username
    @api_settings[:username]
  end

  def api_key
    @api_settings[:api_key]
  end

  def raise_exceptions?
    @api_settings[:raise_exceptions]
  end

  def raise_exceptions=(raise_exceptions)
    @api_settings[:raise_exceptions] = raise_exceptions
  end

  def verify_ssl?
    @api_settings[:verify_ssl]
  end

  def verify_ssl=(verify_ssl)
    @api_settings[:verify_ssl] = verify_ssl
  end

  # Audience and lists
  def lists
    wrap_with_array('lists', 'list') do
      do_request(path(:audience_lists), :get, :format => :xml)
    end
  end

  def memberships(email)
    wrap_with_array('lists', 'list') do
      do_request(path(:memberships, :email => email), :get)
    end
  end

  def new_list(list_name)
    do_request(path(:create_list), :post, :name => list_name)
  end

  def delete_list(list_name)
    do_request(path(:destroy_list, :list => list_name), :delete)
  end

  def csv_import(csv_string)
    do_request(path(:audience_members), :post, :csv_file => csv_string)
  end

  def add_user(hash_or_array)
    csv_import(build_csv(hash_or_array))
  end

  alias :add_users :add_user

  def add_to_list(email, list_name, options={})
    do_request(path(:add_to_list, :list => list_name), :post, options.merge(:email => email))
  end

  def remove_from_list(email, list_name)
    do_request(path(:remove_from_list, :list => list_name), :post, :email => email)
  end

  def remove_from_all_lists(email)
    do_request(path(:remove_from_all_lists), :post, :email => email)
  end

  def update_email(existing_email, new_email)
    do_request(path(:update_user_email, :email => existing_email), :post, :email => existing_email, :new_email => new_email)
  end

  def members
    wrap_with_array('audience', 'member') do
      do_request(path(:get_audience_members), :get)
    end
  end

  def list_members(list_name, page = 1, per_page = 30)
    wrap_with_array('audience', 'member') do
      do_request(path(:audience_list_members, :list => list_name), :get, {
        :page     => page,
        :per_page => per_page
      })
    end
  end

  def list_size(list_name)
      do_request(path(:audience_list_size, :list => list_name), :get)
  end

  def list_size_since(list_name, date)
    do_request(path(:audience_list_size, :list => list_name, :date => date), :get)
  end

  def suppressed_since(timestamp, show_suppression_reason = false)
    do_request(path(:suppressed_since, :timestamp => timestamp), :get, {
      :show_suppression_reason => show_suppression_reason
    })
  end

  def suppress_email(email)
    return '' if suppressed?(email)

    process_json_response do
      do_request(path(:suppress_user), :post, :audience_member_id => email, :format => :json)
    end
  end

  def unsuppress_email(email)
    return '' unless suppressed?(email)

    process_json_response do
      do_request(path(:unsuppress_user, :email => email), :delete, :format => :json)
    end
  end

  def suppressed?(email)
    response = do_request(path(:is_suppressed, :email => email), :get)
    response == 'true'
  end

  def audience_search(query_string, raw = false)
    do_request(path(:search), :get, :raw => raw, :query => query_string)
  end

  def add_users_to_list(list_name, arr)
    add_users(arr.map{ |a| a[:add_list] = list_name; a })
  end

  # Promotions
  def promotions
    wrap_with_array('promotions', 'promotion') do
      do_request(path(:promotions), :get)
    end
  end

  def save_promotion(promotion_name, raw_html, plain_text = nil)
    options = { :promotion_name => promotion_name }

    unless raw_html.nil?
      check_for_tracking_beacon raw_html
      check_for_opt_out raw_html
      options[:raw_html] = raw_html
    end

    unless plain_text.nil?
      check_for_opt_out plain_text
      options[:raw_plain_text] = plain_text
    end

    do_request(path(:promotion_save), :post, options)
  end

  # Stats
  def mailing_stats(promotion_id, mailing_id)
    do_request(path(:mailing_stats, :promotion_id => promotion_id, :mailing_id => mailing_id), :get)
  end

  # Mailer API
  def send_mail(opt, yaml_body)
    options = opt.dup
    options[:body] = yaml_body.to_yaml
    if !options[:list_name].nil? || options[:to_all]
      do_request(path(options[:to_all] ? :mailer_to_all : :mailer_to_list), :post, options, true)
    else
      do_request(path(:mailer), :post, options, true)
    end
  end

  def send_html(opt, html)
    options = opt.dup
    if html.include?('[[tracking_beacon]]') || html.include?('[[peek_image]]')
      options[:raw_html] = html
      if !options[:list_name].nil? || options[:to_all]
        unless html.include?('[[unsubscribe]]') || html.include?('[[opt_out]]')
          raise MadMimiError, "When specifying list_name, include the [[unsubscribe]] or [[opt_out]] macro in your HTML before sending."
        end
        do_request(path(options[:to_all] ? :mailer_to_all : :mailer_to_list), :post, options, true)
      else
        do_request(path(:mailer), :post, options, true)
      end
    else
      raise MadMimiError, "You'll need to include either the [[tracking_beacon]] or [[peek_image]] macro in your HTML before sending."
    end
  end

  def send_plaintext(opt, plaintext)
    options = opt.dup
    options[:raw_plain_text] = plaintext
    if !options[:list_name].nil? || options[:to_all]
      if plaintext.include?('[[unsubscribe]]') || plaintext.include?('[[opt_out]]')
        do_request(path(options[:to_all] ? :mailer_to_all : :mailer_to_list), :post, options, true)
      else
        raise MadMimiError, "You'll need to include either the [[unsubscribe]] or [[opt_out]] macro in your text before sending."
      end
    else
      do_request(path(:mailer), :post, options, true)
    end
  end

  def status(transaction_id)
    do_request(path(:mailer_status, :transaction_id => transaction_id), :get, {}, true)
  end

  private

  # Refactor this method asap
  def do_request(path, method = :get, options = {}, transactional = false)
    options = default_options.deep_merge({
      :format => options.delete(:format) || extract_format(path),
      :body => options
    })

    path = convert_to_secure(path) if transactional

    response = self.class.send(method, path, options)

    response.value if raise_exceptions?
    response.parsed_response
  end

  def build_csv(hash_or_array)
    hashes  = Array.wrap(hash_or_array)
    columns = hashes.map(&:keys).flatten.uniq

    if CSV.respond_to?(:generate_row)   # before Ruby 1.9
      buffer = ''
      CSV.generate_row(columns, columns.size, buffer)
      hashes.each do |hash|
        values = columns.map{ |c| hash[c] }
        CSV.generate_row(values, values.size, buffer)
      end
      buffer
    else                               # Ruby 1.9 and after
      CSV.generate do |csv|
        csv << columns
        hashes.each do |hash|
          csv << columns.map{ |c| hash[c] }
        end
      end
    end
  end

  def check_for_tracking_beacon(content)
    unless content.include?('[[tracking_beacon]]') || content.include?('[[peek_image]]')
      raise MadMimiError, "You'll need to include either the [[tracking_beacon]] or [[peek_image]] macro in your HTML before sending."
    end
    true
  end

  def check_for_opt_out(content)
    unless content.include?('[[opt_out]]') || content.include?('[[unsubscribe]]')
      raise MadMimiError, "When specifying list_name or sending to all, include the [[unsubscribe]] or [[opt_out]] macro in your HTML before sending."
    end
    true
  end

  def process_json_response
    json_response = yield
    begin
      json_response["success"] ? '' : json_response["error"]
    rescue JSON::ParserError
      json_response
    end
  end

  def default_options
    {
      :body => {
        :username => username,
        :api_key  => api_key
      },
      :verify => verify_ssl?
    }
  end

  def extract_format(path)
    File.extname(path)[1..-1].try(:to_sym)
  end

  def convert_to_secure(path)
    "#{ self.class.base_uri.gsub('http://', 'https://') }#{ path }"
  end

  def path(key, arguments={})
    escaped_arguments = arguments.inject({}){ |h, (k, v)| h[k] = URI.escape(v.to_s); h }
    paths[key] % escaped_arguments
  end

  def paths
    @paths ||= YAML.load(File.read(paths_config_file))
  end

  def paths_config_file
    @paths_config_file ||= File.join(File.dirname(File.expand_path(__FILE__)), '../config/paths.yml')
  end

  def wrap_with_array(*args)
    yield.tap do |response|
      obj = args[0..-2].inject(response){ |r, arg| r.try(:[], arg) }

      if obj && obj[args.last] && obj[args.last].is_a?(Hash)
        obj[args.last] = Array.wrap(obj[args.last])
      end
    end
  end
end
