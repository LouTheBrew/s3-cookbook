require 'aws-sdk'
namespace :repository do
  cookbook_path = ENV['RAKE_COOKBOOK_PATH']
  cookbook_name = ::File.read('NAME').strip
  task :tags do
    system 'git tag'
  end
  task :git_commit_and_push do
    commit = <<-EOH
    git add -f *
    git commit -a -m "commit for version #{::File.read('VERSION').strip}"
    git tag -a #{::File.read('VERSION').strip} -m "version release #{::File.read('VERSION').strip}"
    git push origin #{`git rev-parse --abbrev-ref HEAD`}
    git push origin #{::File.read('VERSION').strip}
    git commit -a -m "commit for version #{::File.read('VERSION').strip}"
    EOH
    system "#{commit}"
  end
  task :up_minor_version do
    stripped = ::File.read('VERSION').strip
    new_minor = stripped.split('.')[-1].to_i
    new_minor += 1
    new_minor_string = new_minor.to_s
    new_minor = new_minor_string.to_s
    new_version = stripped.split('.')[0..-2]
    new_version << new_minor_string
    version = new_version.join('.')
    match = stripped
    replace = version
    file = 'VERSION'
    system 'rm -rf VERSION'
    system 'rm -rf .kitchen.yml'
    ::File.write('VERSION', version.strip)
  end
  task :sync_berkshelf do
    system 'rm -rf Berksfile.lock && berks install && berks update'
  end
  task :supermarket do
    system <<-EOH
    knife cookbook site share #{cookbook_name} "Other" -o #{cookbook_path}
    EOH
  end
  task :kitchen_yml_workaround => 'kitchen:kitchen_yml_workaround'
  task :publish => [:kitchen_yml_workaround, :up_minor_version, :sync_berkshelf, :git_commit_and_push, :supermarket, :kitchen_yml_workaround]
  task :commit => [:kitchen_yml_workaround, :sync_berkshelf, :git_commit_and_push, :kitchen_yml_workaround]
  task :revert, [:arg1] do |t, args|
    system "git reset --hard \"#{args[:arg1]}\""
  end
end
namespace :kitchen do
  task :berks => 'repository:sync_berkshelf'
  task :sync_berkshelf => 'repository:sync_berkshelf'
  task :destroy do
    Rake::Task['special:wipe'].invoke
    system 'kitchen destroy'
    Rake::Task['special:wipe'].invoke
  end
  task :test do
    Rake::Task['kitchen:destroy'].invoke
    system 'kitchen test'
  end
  task :converge do
    system 'kitchen converge'
  end
  task :kitchen_yml_workaround do
# Because environment variables and a .kitchen.yml don't mix
    content = <<-YAML
---
driver:
  name: ec2
  aws_ssh_key_id: <%= ENV['KITCHEN_AWS_KEY'] %>
  security_group_ids: [<%= ENV['KITCHEN_SECURITY_GROUP'] %>]
  region: <%= ENV['KITCHEN_AWS_REGION'] %>
  availability_zone: <%= ENV['KITCHEN_AWS_AVAILABILITY_ZONE'] %>
  require_chef_omnibus: <%= ENV['KITCHEN_OMNIBUS_BOOL'] %>
  subnet_id: <%= ENV['KITCHEN_SUBNET'] %>
  iam_profile_name: <%= ENV['KITCHEN_IAM'] %>
  instance_type: <%= ENV['KITCHEN_SIZE'] %>
  associate_public_ips: <%= ENV['KITCHEN_PUBLIC_IP_BOOL'] %>
  interface: <%= ENV['KITCHEN_NETWORK_INTERFACE'] %>
  tags:
    Name: <%= ENV['KITCHEN_INSTANCE_NAME_TAG'] %>
    Cookbook: #{::File.read('NAME').strip}
    Cookbook_Version: #{::File.read('VERSION').strip}
    Developer: #{`whoami`}

provisioner:
  name: <%= ENV['KITCHEN_PROVISIONER'] %>

transport:
  username: <%= ENV['KITCHEN_USERNAME'] %>
  ssh_key: <%= ENV['KITCHEN_PRIVATE_KEY_PATH'] %>

platforms:
  - name: <%= ENV['KITCHEN_EC2_PLATFORM'] %>
    driver:
      image_id: <%= ENV['KITCHEN_EC2_AMI'] %>

suites:
  - name: default
    run_list:
      - recipe[#{::File.read('NAME').strip}::default]
    attributes:
  YAML
    unless ::File.exists?('.kitchen.yml')
      ::File.write('.kitchen.yml', content)
    end
  end
  task :reconverge => [:kitchen_yml_workaround, :sync_berkshelf, :destroy, :converge]
end
namespace :notifications do
  task :status do
    puts "Cookbook Name: #{::File.read('NAME')}"
    puts "Cookbook Version: #{::File.read('VERSION')}"
    puts "Resources Defined:"
    `ls libraries`.split.each do |resource|
      puts "  #{resource}"
    end
    puts "Templates Defined:"
    `ls templates/default`.split.each do |template|
      puts "  #{template}"
    end
    puts "Files Defined:"
    `ls files/default`.split.each do |template|
      puts "  #{template}"
    end
    puts "Libraries Defined:"
    `ls libraries`.split.each do |lib|
      puts "  #{lib}"
    end
    puts "Relevant cookbook environment variables:"
    not_defined = 0
    [
      {:name => 'RAKE_COOKBOOK_PATH'},
      {:name => 'KITCHEN_AWS_KEY'},
      {:name => 'KITCHEN_SECURITY_GROUP'},
      {:name => 'KITCHEN_AWS_REGION'},
      {:name => 'KITCHEN_AWS_AVAILABILITY_ZONE'},
      {:name => 'KITCHEN_OMNIBUS_BOOL'},
      {:name => 'KITCHEN_SUBNET'},
      {:name => 'KITCHEN_IAM'},
      {:name => 'KITCHEN_SIZE'},
      {:name => 'KITCHEN_PUBLIC_IP_BOOL'},
      {:name => 'KITCHEN_NETWORK_INTERFACE'},
      {:name => 'KITCHEN_INSTANCE_NAME_TAG'},
      {:name => 'KITCHEN_PROVISIONER'},
      {:name => 'KITCHEN_USERNAME'},
      {:name => 'KITCHEN_PRIVATE_KEY_PATH'},
      {:name => 'KITCHEN_EC2_PLATFORM'},
      {:name => 'KITCHEN_EC2_AMI'},
      {:name => 'AWS_REGION'},
      {:name => 'CODE_GENERATOR_PATH'},
    ].each do |evar|
      if ENV[evar[:name]]
        puts "  #{evar[:name]} --> #{ENV[evar[:name]]}"
      else
        puts "  #{evar[:name]} not defined, please define it."
        not_defined += 1
      end
    end
    if not_defined < 1
      puts ""
      puts "All checked values were defined.  This is a good thing."
    else
      puts "#{not_defined} variables not defined, some things related to kitchen and cookbooks may break"
    end
  end
end
namespace :special do
  task :relink do
    if ENV['CODE_GENERATOR_PATH']
      system "rm -rf Rakefile && ln -s #{::File.join(ENV['CODE_GENERATOR_PATH'], 'files', 'default', 'Rakefile')} Rakefile"
    else
      puts "You should have CODE_GENERATOR_PATH defined to do this, aborting..."
    end
  end
  # Sometimes kitchen doesn't clean up after itself, this task can be added anywhere you want an extra cleanup check
  task :wipe do
    resource = Aws::EC2::Resource.new
    destroyed = 0
    resource.instances({:filters => [{name: 'tag:Cookbook', values: [::File.read('NAME').strip]}]}).each do |instance|
      response = instance.terminate(dry_run: false)
      if response.successful?
        destroyed += 1
      end
    end
    if destroyed > 0
      puts "Ran a check for extra instances related to cookbook #{::File.read('NAME').strip} and #{destroyed} were sent a terminate signal, these may have been previously terminated"
    end
  end
end

############################################## main task interface
task :default => 'notifications:status'
task :status => 'notifications:status'
task :commit => 'repository:commit'
task :converge => 'kitchen:reconverge'
task :reconverge => 'kitchen:reconverge'
task :destroy => 'kitchen:destroy'
task :test => 'kitchen:test'
task :publish => 'repository:publish'
task :relinkage => 'special:relink'
task :revert, [:arg1] => 'repository:revert'
task :tags => 'repository:tags'
task :wipe => 'special:wipe'
task :berks => 'kitchen:berks'
task :example, :response do |t, args|
  response = args[:response] || 'default_value'
  puts response
end
