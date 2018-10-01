require 'open3'

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  config.before(:all) do
    command_string = 'bundle exec puppet facts --modulepath .\spec\fixtures\modules'
    @stdout, stderr, status = Open3.capture3(command_string)
  end
end