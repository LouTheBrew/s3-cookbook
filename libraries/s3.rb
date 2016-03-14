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
    attribute :path, kind_of: String, required: true
    attribute :bucket, kind_of: String, required: true
    attribute :venv, kind_of: String, default: '/chef/apps/virtualenvs/s3/'
    attribute :pip_packages, kind_of: Array, default: %w{boto3 docopt}
    attribute :template, kind_of: String, default: 's3.py.erb'
    attribute :out, kind_of: String, default: '/tmp/s3.log'
  end
  class Provider < Chef::Provider
    include Poise
    provides :s3
    def access
      notifying_block do
        yield
      end
    end
    def venv
      access do
        return new_resource.venv
      end
    end
    def name
      access do
        return new_resource.name
      end
    end
    def venv
      "#{self.venv}"
    end
    def interpreter
      "#{self.venv}/bin/python"
    end
    def s3pythonbin
      "#{self.venv}s3/bin/s3.py"
    end
    def responses
      "#{self.venv}s3/bin/s3/responses/"
    end
    def given_the_givens
        unless ::File.exists? self.venv
          self.create_custom_python_env self.venv
        end
        template self.s3pythonbin do
          source new_resource.template
          cookbook 's3'
          variables :context => {:interpreter => "#{self.interpreter}"}
          mode 0777
        end
        yield
    end
    def s3(method, args)
      case method
      when :upload
        bash method.to_s do
          code <<-EOH
          #{args[:bin]} #{method.to_s} #{args[:bucket]} #{args[:path]} #{args[:key]} #{args[:out]}
          EOH
        end
      when :download
        bash method.to_s do
          code <<-EOH
          #{args[:bin]} #{method.to_s} #{args[:bucket]} #{args[:path]} #{args[:key]} #{args[:out]}
          EOH
        end
      when :delete
        bash method.to_s do
          code <<-EOH
          #{args[:bin]} #{method.to_s} #{args[:bucket]} #{args[:path]} #{args[:key]} #{args[:out]}
          EOH
        end
      end
    end
    def create_custom_python_env(env)
      notifying_block do
        include_recipe 'python'
        directory env do
          recursive true
        end
        python_virtualenv env
        new_resource.pip_packages.each do |pkg|
          python_pip pkg do
            virtualenv env
          end
        end
      end
    end
    def action_upload
      notifying_block do
        given_the_givens do
          s3 :upload,{
              :bin => self.s3pythonbin,
              :bucket => new_resource.bucket,
              :path => new_resource.path,
              :key => new_resource.name,
              :out => new_resource.out
          }
        end
      end
    end
  end
end
