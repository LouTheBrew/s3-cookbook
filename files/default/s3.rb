##!<%=@context[:interpreter]%>
require 'aws-sdk'

#module S3
#  def connect(region='us-west-2')
#    #Aws::S3.new(region: region)
#    Aws::S3.new
#  end
#  def send(type)
#    #s3 = connect
#    nil
#  end
#  def take(type)
#    nil
#  end
#  def list()
#    s3 = connect
#    #s3.objects.limit(limit).each do |obj|
#    #  puts "#{obj.key} => #{obj.etag}"
#    #end
#    #puts 'away'
#  end
#end
#include S3
#puts list
#class Controller
#  include S3
#end


s3 = Aws::S3::Client.new
