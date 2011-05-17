require "erb"
require "json"
require "fog"
require "fog/aws/cloud_formation"

namespace :aws do
  AWS_DIR = "#{File.dirname(__FILE__)}/aws"
  BOOTSTRAP_FILE = "bootstrap.tar.gz"
  STACK_NAME = "company-news"

  directory BUILD_DIR

  desc "creates the project's infrastructure in the Amazon cloud"
  task :provision => :upload_bootstrap_files do
    template_body = contents("#{AWS_DIR}/cloud_formation_template.erb")
    boot_script = ERB.new(contents("#{AWS_DIR}/bootstrap.erb")).result(binding)

    puts "creating aws stack, this might take a while... ".white
    cloud = cloud_formation
    cloud.create_stack(STACK_NAME,
                       "TemplateBody" => ERB.new(template_body).result(binding),
                       "Parameters" => { "KeyName" => SETTINGS["aws_ssh_key_name"],
                                         "Password" => "hotbubbles",
                                         "PSK" => "W3lcom3%1"})
    stack = nil
    until stack
      sleep 1
      stack = find_stack(cloud)
    end
    puts "your servers have been provisioned successfully".white
  end

  {"admin_server" => "ManagementConsole", "test_server" => "TestServer"}.each do |file_name, key_name|
    file "#{BUILD_DIR}/#{file_name}" => [:settings, BUILD_DIR] do
      cloud = cloud_formation
      stack = find_stack(cloud)
      puts "discovering #{file_name} address...".white
      address = stack["Outputs"].find { |output| output["OutputKey"] == key_name }["OutputValue"]
      puts "#{file_name} address: #{address}".green
      File.open("#{BUILD_DIR}/#{file_name}", "w") do |file|
        file.write address
      end
    end
  end

  desc "stops all instances and releases all Amazon resources"
  task :shutdown => :settings do
    cloud_formation.delete_stack STACK_NAME
    puts "shutdown command successful".green
  end

  task :upload_bootstrap_files => [:settings, :package] do
    storage = s3
    directory = nil
    if not storage.directories.get(BUCKET_NAME)
      puts "creating S3 bucket".cyan
      directory = storage.directories.create(:key => BUCKET_NAME, :public => true, :location => "ap-southeast-1")
    else
      directory = storage.directories.get(BUCKET_NAME)
    end
    puts "uploading bootstrap package...".cyan
    directory.files.create(:key => BOOTSTRAP_FILE,
                           :body => File.open("#{BUILD_DIR}/#{BOOTSTRAP_FILE}"),
                           :public => true,
                           :location => "ap-southeast-1")
  end

  task :package => [:clean, BUILD_DIR] do
    mkdir_p "#{BUILD_DIR}/package"
    cp_r "#{AWS_DIR}/repos", "#{BUILD_DIR}/package/repos"
    cp_r "puppet", "#{BUILD_DIR}/package/puppet"
    puts "packaging boostrap files in #{BOOTSTRAP_FILE}"
    %x[cd #{BUILD_DIR}/package; tar -zcf ../#{BOOTSTRAP_FILE} *]
  end

  task :settings do
    SETTINGS = YAML::parse(open("conf/settings.yaml")).transform
    BUCKET_NAME = "#{STACK_NAME}-#{SETTINGS['aws_ssh_key_name']}"
  end

  def s3
    Fog::Storage.new(:provider => "AWS",
                     :aws_access_key_id => SETTINGS["aws_access_key"],
                     :aws_secret_access_key => SETTINGS["aws_secret_access_key"],
                     :region => "ap-southeast-1")
  end

  def cloud_formation
    Fog::AWS::CloudFormation.new(:aws_access_key_id => SETTINGS["aws_access_key"],
                                 :aws_secret_access_key => SETTINGS["aws_secret_access_key"],
                                 :region => "ap-southeast-1")
  end

  def find_stack(cloud)
    cloud.describe_stacks.body["Stacks"].find do |stack|
      stack["StackName"] == STACK_NAME && stack["StackStatus"] == "CREATE_COMPLETE"
    end
  end

  def contents(file)
    contents = ""
    File.open(file) { |f| contents << f.read }
    contents
  end
end
