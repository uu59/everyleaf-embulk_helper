require "gem_release_helper/tasks/common"
require "open3"

module GemReleaseHelper
  module Tasks
    module Generator
      class Changelog
        include Tasks::Common

        DEFAULT_CHANGELOG_TEMPLATE = "changelog.erb".freeze

        def install_tasks
          namespace :generate do
            desc "Generate chengelog then bump version"
            task :prepare_release => [:changelog, :bump_version]

            desc "Generate CHANGELOG.md from previous release"
            task :changelog do
              changelog
            end

            desc "Bump version. UP=major to do major version up, UP=minor, UP=patch(default) so on."
            task :bump_version do
              bump_version
              update_gemfile_lock
            end
          end
        end

        def changelog
          content = new_changelog
          File.open(changelog_path, "w") do |f|
            f.write content
          end
        end

        def bump_version
          logger.info "Bump version from '#{current_version}' to '#{next_version}'"
          case where_written_version
          when :gemspec
            write_new_version_to_gemspec
          when :version_file
            write_new_version_to_version_file
          end
        end

        private

        def write_new_version_to_gemspec
          old_content = gemspec_path.read
          new_content = old_content.gsub(/(spec\.version += *)".*?"/, %Q!\\1"#{next_version}"!)
          File.open(gemspec_path, "w") do |f|
            f.write new_content
          end
        end

        def write_new_version_to_version_file
          version_file = version_files.first
          new_content = File.read(version_file).gsub(current_version.to_s, next_version.to_s)
          File.open(version_file, "w") {|f| f.write new_content }
        end

        def where_written_version
          if gemspec_path.read.include?(current_version.to_s)
            :gemspec
          else
            version_file = version_files.first
            if version_file && File.read(version_file).include?(current_version.to_s)
              return :version_file
            end
            raise "Couldn't find where is version written"
          end
        end

        def version_files
          Dir["#{gemspec_path.dirname}/**/version**"]
        end

        def required_options
          %w(github_name)
        end

        def current_version
          return ENV["CURRENT_VER"] if ENV["CURRENT_VER"]
          ver = gemspec_path.read[/spec\.version += *"([0-9]+\.[0-9]+\.[0-9]+)"/, 1] ||
            begin
              # from rake
              # https://github.com/ruby/rake/blob/1b27eb2f8234190bba0e973194d38bcf09443ec0/lib/rake/file_utils.rb
              ruby = File.join(
                RbConfig::CONFIG['bindir'],
                RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT']
              ).sub(/.*\s.*/m, '"\&"')
              script = %Q!print eval(File.read('#{gemspec_path}')).version.to_s!
              o, _, _ = Open3.capture3(ruby, "-e", script)
              o.strip
            end
          Gem::Version.new(ver)
        end

        def next_version
          return ENV["NEXT_VER"] if ENV["NEXT_VER"]
          major, minor, patch = current_version.segments
          ver = case version_target
          when "patch"
            [major, minor, patch + 1].join(".")
          when "minor"
            [major, minor + 1, 0].join(".")
          when "major"
            [major + 1, 0, 0].join(".")
          end

          Gem::Version.new(ver)
        end

        def version_target
          ENV["UP"] || options[:version_target] || "patch"
        end

        def update_gemfile_lock
          system("bundle install")
        end

        def github_name
          options[:github_name]
        end

        def pull_request_numbers
          sync_git_repo
          `git log v#{current_version}..origin/master --oneline`.scan(/#[0-9]+/).map do |num_with_hash|
            num_with_hash[/[0-9]+/]
          end
        end

        def pull_request_info(number)
          header =
            if github_oauth_token
              {
                "Authentication" => "token #{ENV["GITHUB_OAUTH_TOKEN"]}"
              }
            else
              {
                http_basic_authentication: [github_user_name, github_personal_token]
              }
            end

          body = open("https://api.github.com/repos/#{github_name}/issues/#{number}", header).read
          JSON.parse(body)
        end

        def changes
          pull_request_numbers.map do |number|
            payload = pull_request_info(number)
            "* [] #{payload["title"]} [##{number}](https://github.com/#{github_name}/pull/#{number})"
          end
        end

        def new_changelog
          <<-HEADER
## #{next_version} - #{Time.now.strftime("%Y-%m-%d")}
#{changes.join("\n")}

#{changelog_path.read.chomp}
          HEADER
        end

        def sync_git_repo
          system('git fetch --all')
        end

        def changelog_path
          root_dir.join("CHANGELOG.md")
        end

        def github_user_name
          ENV["GITHUB_USER_NAME"] || `git config github.user`.strip
        end

        def github_personal_token
          ENV["GITHUB_TOKEN"] || `git config github.token`.strip
        end

        def github_oauth_token
          ENV["GITHUB_OAUTH_TOKEN"]
        end
      end
    end
  end
end
