#
# TestRail API binding for Ruby (API v2, available since TestRail 3.0)
#
# Learn more:
#
# http://docs.gurock.com/testrail-api2/start
# http://docs.gurock.com/testrail-api2/accessing
#
# Copyright Gurock Software GmbH. See license.md for details.
#

# slightly modified by mkubik

require 'net/http'
require 'net/https'
require 'uri'
require 'json'

module Testrail

  AUTOMATED_DESCRIPTION = 'created by automated test suite'

  STATUS = {
      passed: 1,
      failed: 5,
      skipped: 7,
      pending: 6
  }

  class Client

    def initialize(args)
      @projects = nil
      @sections = Hash.new
      @suite   = Hash.new
      @suites   = Hash.new

      @client = APIClient.new args[:url]
      %w(user password project).each do |key|
        raise Exception.new("TestRail configuration key :#{key} not set. Cannot continue without it.") if args[key.intern].nil?
        @client.send "#{key}=", args[key.intern] if %w(user password).include? key
      end
    end

    # ---------------------------------------------------> projects ----------------------------------------------------
    def get_projects
      @projects ||= @client.send_get('get_projects')
    end

    def add_project(project_name)
      @projects = nil # invalidate cached stuff
      @client.send_post('add_project', {name: project_name,
                                        announcement: AUTOMATED_DESCRIPTION,
                                        show_anouncement: true})
    end

    def get_project(project_id)
      self.get_projects.find { |project| project['id'] == project_id }
    end

    # ----------------------------------------------------> suites <----------------------------------------------------
    def get_suite(suite_id)
      @suite[suite_id] ||= @client.send_get("get_suite/#{suite_id}")
    end

    def get_suites(project_id)
      @suites[project_id] ||= @client.send_get("get_suites/#{project_id}")
    end

    def find_suite_by_name(name, project_id)
      suites = self.get_suites(project_id).select do |suite|
        suite['name'] == name
      end
      puts "TestRail Exporter [WARN] #{suites.size} suites found with name: #{name}. Using first one." if suites.size > 1
      suites.first
    end

    def create_suite(name, project_id)
      @suites.delete(project_id) # invalidate cached stuff
      puts "TestRail Exporter [INFO] Creating suite: #{name} under project: #{ self.get_project(project_id)['name'] }"
      @client.send_post("add_suite/#{project_id}", { name: name, description: AUTOMATED_DESCRIPTION })
    end

    def find_or_create_suite(name, project_id)
      self.find_suite_by_name(name, project_id) || self.create_suite(name, project_id)
    end

    # ---------------------------------------------------> sections <---------------------------------------------------
    def get_sections(suite)
      @sections[suite['id']] ||= @client.send_get("get_sections/#{suite['project_id']}&suite_id=#{suite['id']}")
    end

    def section_ids_at_depth(suite, depth)
      self.get_sections(suite).select{ |s| s['depth'] == depth }.map{ |s| s['id'] }
    end

    def find_section(name, suite, parent_id)
      get_sections(suite).select{ |s| s['parent_id'] == parent_id }.find{ |s| s['name'] == name.strip }
    end

    def find_or_create_section(name, suite, parent, depth)
      parent_id = (depth == 0) ? nil : parent['id']
      self.find_section(name, suite, parent_id) || self.create_section(name, suite, parent_id)
    end

    def create_section(name, suite, parent_id)
      @sections.delete(suite['id']) # invalidate cached values
      # TODO: check if JSON created have null for nil parent_id
      @client.send_post("add_section/#{suite['project_id']}", { name: name,
                                                                suite_id: suite['id'],
                                                                description: AUTOMATED_DESCRIPTION,
                                                                parent_id: parent_id })
    end

    # ----------------------------------------------------> cases <-----------------------------------------------------
    def find_or_create_case(title, section, depth)
      self.find_case(title, section, depth) || self.create_case(title, section['id'])
    end

    def find_case(title, section, depth)
      suite = self.get_suite(section['suite_id'])
      test_cases = @client.send_get("get_cases/#{suite['project_id']}&suite_id=#{suite['id']}")
      test_cases.find do |test_case|
        test_case['title'] == title && test_case['section_id'] == section['id']
      end
    end

    def create_case(title, section_id)
      @client.send_post("add_case/#{section_id}", { title: title })
    end

    # ----------------------------------------------------> runs <------------------------------------------------------
    def create_run(suite)
      @client.send_post("add_run/#{suite['project_id']}", { suite_id: suite['id'], name: "#{nice_time_now} - #{suite['name']}", description: 'describe it somehow'})
    end

    def add_results_for_cases(run_id, results)
      @client.send_post("add_results_for_cases/#{run_id}", { results: results })
    end

    private

    def nice_time_now
      Time.now.strftime('%d %b %Y %R:%S %Z')
    end

  end

  class APIClient
    @url = ''
    @user = ''
    @password = ''

    attr_accessor :user
    attr_accessor :password

    def initialize(base_url)
      if !base_url.match(/\/$/)
        base_url += '/'
      end
      @url = base_url + 'index.php?/api/v2/'
    end

    #
    # Send Get
    #
    # Issues a GET request (read) against the API and returns the result
    # (as Ruby hash).
    #
    # Arguments:
    #
    # uri                 The API method to call including parameters
    #                     (e.g. get_case/1)
    #
    def send_get(uri)
      _send_request('GET', uri, nil)
    end

    #
    # Send POST
    #
    # Issues a POST request (write) against the API and returns the result
    # (as Ruby hash).
    #
    # Arguments:
    #
    # uri                 The API method to call including parameters
    #                     (e.g. add_case/1)
    # data                The data to submit as part of the request (as
    #                     Ruby hash, strings must be UTF-8 encoded)
    #
    def send_post(uri, data)
      _send_request('POST', uri, data)
    end

    private
    def _send_request(method, uri, data)
      url = URI.parse(@url + uri)
      if method == 'POST'
        request = Net::HTTP::Post.new(url.path + '?' + url.query)
        request.body = JSON.dump(data)
      else
        request = Net::HTTP::Get.new(url.path + '?' + url.query)
      end
      request.basic_auth(@user, @password)
      request.add_field('Content-Type', 'application/json')

      conn = Net::HTTP.new(url.host, url.port)
      if url.scheme == 'https'
        conn.use_ssl = true
        conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response = conn.request(request)

      if response.body && !response.body.empty?
        begin
          result = JSON.parse(response.body)
        rescue JSON::ParserError => e
          raise APIError.new "TestRail API request (#{request.method} #{url}) failed\n#{e.class}: #{e.message}"
        end
      else
        result = {}
      end

      if response.code != '200'
        if result && result.key?('error')
          error = '"' + result['error'] + '"'
        else
          error = 'No additional error message received'
        end
        raise APIError.new "TestRail API returned HTTP #{response.code} (#{error})"
      end

      result
    end
  end

  class APIError < StandardError
  end
end
