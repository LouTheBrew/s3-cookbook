require 'spec_helper'

describe file('/tmp/testfileisback') do
  it { should exist }
end
