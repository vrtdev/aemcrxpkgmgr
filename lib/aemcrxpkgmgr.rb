require 'aemcrxpkgmgr/version'

require 'uri'
require 'yaml'
require 'json'
require 'net/http'
require 'pp'

# AEM CRX Package Manager
class AemCrxPkgMgr
  attr_accessor :includeversions, :keys_to_extract, :output
  def initialize(options = {})
    @host = options[:host] || 'http://localhost:4502'
    @user = options[:user] || 'admin'
    @max_retries = options[:max_retries] || 100
    @retry_timeout = options[:retry_timeout] || 3
    @pass = options[:pass]
    @includeversions = options[:includeversions] || false
    @keys_to_extract = options[:keys_to_extract]
    @output = options[:output] || 'ruby'
    @debug = options[:debug]
  end

  def get(uri)
    retries ||= @max_retries

    request = Net::HTTP::Get.new(uri)
    request.basic_auth(@user, @pass)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
    raise "AemCrxPkgMgr.get Response '#{response.code}' is not a Net::HTTPSuccess" unless response.is_a?(Net::HTTPSuccess)
    response
  rescue Errno::EADDRNOTAVAIL
    raise "AemCrxPkgMgr.get AEM not available"
  rescue RuntimeError => e
    puts "AemCrxPkgMgr.get : #{e.class} : #{e.message}"
    will_retry = (retries -= 1) >= 0
    if will_retry
      sleep @retry_timeout
      retry
    end
    raise
  end

  def pkg_query_uri(query)
    uri = URI.parse(@host + '/crx/packmgr/list.jsp')
    params = { includeVersions: @includeversions }
    unless query.nil?
      params['q'] = query
    end
    uri.query = URI.encode_www_form(params)
    uri
  end

  def delete_crx_zip(list)
    return unless list
    @delete_crx_zip_ok = 0
    @delete_crx_zip_status = []
    list.each do |path|
      delete_crx_zip_single path
    end
    @delete_crx_zip_ok == list.length
  end

  def delete_crx_request(uri)
    req = Net::HTTP::Post.new(uri)
    req.basic_auth(@user, @pass)
    req.set_form_data('cmd' => 'delete')
    req
  end

  def delete_crx_zip_single(path)
    uri = URI(@host + '/crx/packmgr/service/script.html' + path)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(delete_crx_request(uri))
    end
    @delete_crx_zip_status << response
    @delete_crx_zip_ok += 1 if response.is_a? Net::HTTPSuccess
  end

  def pkg_query(query, filtergroup, filtername)
    uri = pkg_query_uri(query)
    response = get uri

    raise "HTTP response code : #{response.code}, message : #{response.message}" unless response.is_a? Net::HTTPSuccess

    @query_data = JSON.parse(response.body)['results']

    unless filtergroup.nil?
      @query_data = @query_data.select { |item| item[:group] == filtergroup }
    end

    unless filtername.nil?
      @query_data = @query_data.select { |item| item[:name] == filtername }
    end

    extract_keys

    format_output @query_data unless @query_data.empty?
  end

  def extract_keys
    return if @keys_to_extract.length.zero?
    @query_data.map! do |element|
      if @keys_to_extract.length == 1
        element[@keys_to_extract.first]
      else
        element.select { |key, _| @keys_to_extract.include? key }
      end
    end
  end

  def format_output(data)
    case @output
    when 'single' then output_single data
    when 'yaml' then data.to_yaml
    when 'json' then data.to_json
    when 'pp' then pp(data, '')
    else
      data
    end
  end

  def output_single(data)
    raise 'Resultset contains more than 1 element and "single" was requested.' if data.length != 1
    data.first
  end
end
