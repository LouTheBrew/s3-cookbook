require 'poise'
require 'chef/resource'
require 'chef/provider'
require 'json'

module S3
  class Resource < Chef::Resource
    include Poise
    provides  :s3
    actions   :upload, :download, :delete
    attribute :name, name_attribute: true, kind_of: String
    attribute :local_cookbook_name, kind_of: String, default: 's3'
    attribute :path, kind_of: String, required: true
    attribute :key, kind_of: String, required: true
    attribute :bucket, kind_of: String, required: true
    attribute :env_dir, kind_of: String, default: '/chef/apps/virtualenvs/s3/'
    attribute :python_bin, kind_of: String, default: '/chef/apps/virtualenvs/s3/bin/python'
    attribute :pip_packages, kind_of: Array, default: %w{boto3 docopt}
    attribute :template, kind_of: String, default: 's3.py.erb'
    attribute :logging, kind_of: [TrueClass, FalseClass], default: true
    attribute :log_dir, kind_of: String, default: '/var/log/s3/'
    attribute :log_path, kind_of: String, default: '/var/log/s3/s3.log'
    attribute :module_name, kind_of: String, default: 's3'
    attribute :module_path, kind_of: String, default: '/chef/apps/virtualenvs/s3/bin/s3.py'
    attribute :region, kind_of: String, default: 'us-east-1'
  end
  class Provider < Chef::Provider
    include Poise
    provides :s3
    def given_the_givens
      [new_resource.env_dir, new_resource.log_dir].each do |dir|
        directory dir do
          recursive true
        end
      end
      python_runtime '2'
      python_virtualenv new_resource.env_dir
      new_resource.pip_packages.each do |mod|
        python_package mod do
          virtualenv new_resource.env_dir
        end
      end
      template new_resource.module_path do
        source new_resource.template
        variables :context => {
          :interpreter => new_resource.python_bin
        }
        cookbook new_resource.local_cookbook_name
      end
      yield
    end
    def s3_do(binary, command, bucket, path, key, region, log)
      python_execute "#{binary} #{command} #{bucket} #{path} #{key} #{region} #{log}"
    end
    def s3_delete(binary, command, bucket, key, region, log)
      python_execute "#{binary} #{command} #{bucket} #{key} #{region} #{log}"
    end
    def action_upload
      given_the_givens do
        s3_do(new_resource.module_path, 'upload', new_resource.bucket, new_resource.path, new_resource.key, new_resource.region, new_resource.log_path)
      end
    end
    def action_download
      given_the_givens do
        s3_do(new_resource.module_path, 'download', new_resource.bucket, new_resource.path, new_resource.key, new_resource.region, new_resource.log_path)
      end
    end
    def action_delete
      given_the_givens do
        s3_delete(new_resource.module_path, 'delete', new_resource.bucket, new_resource.key, new_resource.key, new_resource.log_path)
      end
    end
  end
end
