file '/tmp/testfile' do
  content 'testing'
end
s3 'upload_a_test' do
  action :upload
  path '/tmp/testfile'
  key 'testfile'
  bucket 'anaplan-devops'
end
s3 'download_a_test' do
  action :download
  path '/tmp/testfileisback'
  key 'testfile'
  bucket 'anaplan-devops'
end
package 'httpd'
#s3 'delete_the_test' do
#  action :delete
#  key 'testfile'
#  bucket 'anaplan-devops'
#end
