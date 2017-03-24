require "bundler/cli"
require "bundler/cli/outdated"
require "libyear_bundler/report"
require "libyear_bundler/query"

module LibyearBundler
  class CLI
    OPTIONS = %w(
      --grand-total
    ).freeze

    E_BUNDLE_OUTDATED_FAILED = 1
    E_NO_GEMFILE = 2

    def initialize(argv)
      @argv = argv
      @gemfile_path = load_gemfile_path
      validate_arguments
    end

    def run
      if @argv.include?("--grand-total")
        grand_total
      else
        print Report.new(query).to_s
      end
    end

    private

    def first_arg_is_gemfile?
      !@argv.first.nil? && ::File.exist?(@argv.first)
    end

    def fallback_gemfile_exists?
      # The envvar is set or
      (!ENV["BUNDLE_GEMFILE"].nil? && ::File.exist?(ENV["BUNDLE_GEMFILE"])) ||
        # Default to local Gemfile
        ::File.exist?("Gemfile")
    end

    def load_gemfile_path
      if first_arg_is_gemfile?
        @argv.first
      elsif fallback_gemfile_exists?
        '' # `bundle outdated` will default to local Gemfile
      else
        $stderr.puts "Gemfile not found"
        exit
      end
    end

    def query
      Query.new(@gemfile_path).execute
    end

    def unexpected_options
      @_unexpected_options ||= begin
        options = @argv.select { |arg| arg.start_with?("--") }
        options.each_with_object([]) do |arg, memo|
          memo << arg unless OPTIONS.include?(arg)
        end
      end
    end

    def validate_arguments
      unless unexpected_options.empty?
        puts "Unexpected args: #{unexpected_options.join(", ")}"
        puts "Allowed args: #{OPTIONS.join(", ")}"
        exit E_NO_GEMFILE
      end
    end

    def grand_total
      sum_years = query.map { |gem| gem[:libyears] }.inject(0.0, :+)
      puts sum_years.truncate(1)
    end
  end
end