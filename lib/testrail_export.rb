require 'rspec'
require 'rspec/core/formatters/base_text_formatter'

require 'rubytree'

require "testrail_export/client"

RSpec.configuration.add_setting :testrail_formatter_options, :default => {}

class TestrailExport < RSpec::Core::Formatters::BaseTextFormatter

  RSpec::Core::Formatters.register self, :start, :close, :dump_summary
  #                                  # :example_started, :example_passed,
  #                                  # :example_pending,  :example_failed,
  #                                  :dump_failures, :dump_pending
  #                                  # :start_dump


  # TODO: after exporter is done and working remove unnecessary overriden methods

  def initialize(output)
    @options = {}
    @project = nil
    super(output)
  end

  # To start
  def start(notification)
    @options = RSpec.configuration.testrail_formatter_options
    @client = Testrail::Client.new(@options)
    @client.get_projects.each { |project| @project = project if project['name'] == @options[:project] }
    @run_name = ENV['TEST_RUN_NAME'] || start_timestamp

    puts "TestRail Exporter [INFO] Executing #{notification.count} tests. Loaded in #{notification.load_time}"

    super
  end

  # Once per example group <-----------------------------------------------------------------------------
  # def example_group_started(notification)
  #   groups = []
  #   current_group = notification.group
  #   until current_group.top_level?
  #     groups << current_group
  #     current_group = current_group.parent if current_group.parent_groups.size > 1
  #   end
  #
  #   groups << current_group
  #
  #   unless groups[0].examples.empty?
  #     groups.reverse.each_with_index do |group, idx|
  #       puts (idx == 0 ? "Spec: " : "") + (' ' *2 * idx) + "#{group.description}"
  #     end
  #     puts (' ' *2 * groups.size) + groups[0].examples.map(&:description).join("\n" + (' ' *2 * groups.size))
  #   end
  #
  #   super
  # end

  # Once per example <-----------------------------------------------------------------------------------
  # def example_started(notification)
  #   puts " - case: #{notification.example.description}"
  # end

  # One of these per example <---------------------------------------------------------------------------
  # def example_passed(passed)
  #   puts "\tpass: #{passed.example.description}"
  # end

  # def example_failed(failure)
  #   puts "\tfail: #{failure.example.description}"
  # end
  #
  # def example_pending(pending)
  #   puts "\tpend: #{pending.example.description}"
  # end

  # Optionally at any time <------------------------------------------------------------------------------
  # def message(notification)
  #   puts "msg notification: #{notification.inspect}"
  #   super
  # end

  # At the end of the suite <-----------------------------------------------------------------------------
  # def stop(notification)
  #   puts "stop notification: #{notification.inspect}"
  # end

  # def start_dump(null_notification)
  #   puts "start_dump notification: #{null_notification.inspect}"
  # end
  #
  def dump_pending(notification)
    # puts "dump pend notification: #{notification.inspect}"
    # super
  end

  def dump_failures(notification)
    # puts "dump fail notification: #{notification.inspect}"
    # super
  end

  def dump_summary(notification)
    # Create project if it is not present / could do it setting controlled
    if @project.nil?
      puts "TestRail Exporter [INFO] Creating project: #{@options[:project]}"
      @project = @client.add_project(@options[:project])
    end

    suites = Hash.new do |h,k|
      h[k] = Tree::TreeNode.new(k, @client.find_or_create_suite(k, @project['id']) )
    end


    notification.examples.each do |example|
      build_hierarchy_tree!(suites, example)
    end

    suites.each { |_, suite| update_test_run(suite, @run_name) }

    super
  end

  def close(null_notification)
    # TODO: could close any open connection
    puts "TestRail Exporter [INFO] Closing..."
    super
  end

  private

  def get_path_for(node)
    asc_arr = node.is_a?(RSpec::Core::Example) ? [node.description] : []
    parent = (node.respond_to? :parent) ? node.parent : node.example_group
    asc_arr << parent.description
    asc_arr.push(*get_path_for(parent)) unless parent.top_level?
    node.is_a?(RSpec::Core::Example) ? asc_arr.reverse : asc_arr
  end

  def build_hierarchy_tree!(suites, example)
    path = get_path_for(example)
    path.unshift('Master') if @project['suite_mode'] == 1
    parent_node = suite_node = suites[path.shift]
    path.unshift('Direct cases') unless path.size > 1

    path.each_with_index do |item, idx|
      child_node = (parent_node.children.map(&:name).include? item) ? parent_node[item] : nil
      if child_node and (idx + 1 == path.size)
        puts "TestRail Exporter [INFO] Second case with same path and name detected:\n\t#{suite_node.content['name']} -> #{path.join(' -> ')}"
      end

      unless child_node
        child_node = if idx + 1 == path.size
                       Tree::TreeNode.new(item, { case: @client.find_or_create_case(item, parent_node.content, idx), result: example })
                     else
                       Tree::TreeNode.new(item, @client.find_or_create_section(item, suite_node.content, parent_node.content, idx))
                     end
        parent_node << child_node
      end
      parent_node = child_node
    end

  end

  def update_test_run(suite, run_name)
    run_id = @client.create_run(suite.content, run_name)['id']
    results = suite.each_leaf.map do |test|
      test_result = test.content[:result].execution_result
      run_time_seconds = test_result.run_time.round(0)
      {
          case_id:    test.content[:case]['id'],
          status_id:  Testrail::STATUS[test_result.status],
          elapsed:    (run_time_seconds == 0) ? nil : "#{run_time_seconds}s"
      }
    end
    @client.add_results_for_cases(run_id, results)
  end

  def start_timestamp
    # make it a bit freezed
    Time.at((Time.now.to_i.to_s[0..7] + "00").to_i).strftime('%d %b %Y %R %Z')
  end
end
