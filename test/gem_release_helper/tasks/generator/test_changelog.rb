module GemReleaseHelper
  module Tasks
    module Generator
      class TestChangelog < Test::Unit::TestCase
        def setup
          FileUtils.touch(gemspec_path)

          @task = Changelog.new(options)
          mute_logger(@task)

          File.open(gemspec_path, "w") do |f|
            f.write <<-SPEC
spec.version       = "0.1.2"
SPEC
          end
        end

        def test_task_installed
          GemReleaseHelper::Tasks.install(options)
          tasks = Rake::Task.tasks.find_all do |task|
            %w(generate:prepare_release generate:changelog generate:bump_version).include?(task.name)
          end
          assert_equal(3, tasks.length)
        ensure
          Rake::Task.clear
        end

        class TestChangelog < self
          def setup
            super
            stub(@task).sync_git_repo {}
            File.open(changelog_path, "w") do |f|
              f.write old_content
            end
          end

          def test_changelog_content
            stub(@task).changes { [
              "foo",
              "bar",
            ]}
            @task.changelog

            new_content = changelog_path.read
            assert new_content.include?(old_content)
            assert new_content.include?("foo")
            assert new_content.include?("bar")
          end

          def test_task_installed
            any_instance_of(Changelog) do |klass|
              mock(klass).changelog
            end
            Tasks.install(options)
            task = Rake::Task.tasks.find {|task| task.name == "generate:changelog"}
            task.execute
          ensure
            Rake::Task.clear
          end

          private

          def changelog_path
            @task.root_dir.join("CHANGELOG.md")
          end

          def old_content
            <<-TXT
## 0.0.1 - 1999-12-25
Merry Xmas!
            TXT
          end
        end

        class TestBumpVersion < self
          class TestVersionDynamic < self
            def setup
              @version = "1.0.0"
              @dir = Pathname.new(Dir.tmpdir).join(Time.now.to_f.to_s)
              @dir.mkdir
              @version_file = @dir.join("lib/foo/version.rb")
              FileUtils.mkdir_p @version_file.dirname
              @version_file.write <<RUBY
class Foo
  VERSION = "#{@version}"
end
RUBY
              @dir.join("foo.gemspec").write <<-SPEC
# coding: utf-8
require '#{@dir.join("lib/foo/version.rb").to_s}'

Gem::Specification.new do |spec|
  spec.name          = "foo"
  spec.version       = Foo::VERSION
end
SPEC
            end

            def teardown
              FileUtils.rm_rf @dir
            end

            def test_bump_version_on_file
              @task = Changelog.new(options)
              mute_logger(@task)

              @task.bump_version
              assert @version_file.read.include?("1.0.1")
              assert_equal "1.0.1", @task.send(:current_version).to_s
            end

            private

            def options
              {
                gemspec: @dir.join("foo.gemspec").to_s,
                github_name: "foo/foo",
              }
            end
          end

          class TestVersionStatic < self
            def test_bump_version_task
              any_instance_of(Changelog) do |klass|
                mock(klass).bump_version
                mock(klass).update_gemfile_lock
              end
              Tasks.install(options)
              task = Rake::Task.tasks.find {|t| t.name == "generate:bump_version"}
              task.execute
            ensure
              Rake::Task.clear
            end

            def test_without_option
              @task = Changelog.new(options)
              mute_logger(@task)

              @task.bump_version

              assert_equal(<<-SPEC, gemspec_path.read)
spec.version       = "0.1.3"
              SPEC
            end

            def test_with_patch
              @task = Changelog.new(options.merge(version_target: "patch"))
              mute_logger(@task)

              @task.bump_version

              assert_equal(<<-SPEC, gemspec_path.read)
spec.version       = "0.1.3"
              SPEC
            end

            def test_with_minor
              @task = Changelog.new(options.merge(version_target: "minor"))
              mute_logger(@task)

              @task.bump_version

              assert_equal(<<-SPEC, gemspec_path.read)
spec.version       = "0.2.0"
              SPEC
            end

            def test_with_major
              @task = Changelog.new(options.merge(version_target: "major"))
              mute_logger(@task)

              @task.bump_version

              assert_equal(<<-SPEC, gemspec_path.read)
spec.version       = "1.0.0"
              SPEC
            end
          end

        end

        private

        def gemspec_path
          Pathname.new("/tmp/changelog.gemspec")
        end

        def options
          {
            gemspec: gemspec_path.to_s,
            github_name: "uu59/gem_release_helper",
          }
        end

        def mute_logger(task)
          stub(task).logger { ::Logger.new(File::NULL) }
        end
      end
    end
  end
end
