## -------------------------------------------------------------------
##
## CDRouter Ruby Gem
## Copyright (c) 2016 QA Cafe http://www.qacafe.com/
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
## THE SOFTWARE.
##
## -------------------------------------------------------------------

# -- Require Patron for HTTP client
gem "patron", ">= 0.6.1"
require 'patron'

# -- Require for JSON handling
require 'json'

module CDRouter
  class Session < Patron::Session

    attr_accessor :debug
    attr_accessor :poll_interval
    attr_reader   :packages
    attr_reader   :configs
    attr_reader   :results
    
    def api_token=(str)
      @api_token = str
      @headers['Authorization'] = "Bearer #{str}"
    end

    def api_token
      @api_token
    end
    
    def initialize
      super
      
      @headers['User-Agent'] = 'CDRouter API Agent/1.0'
      @timeout = 30
      @poll_interval = 15

      # don't perform SSL cert validation
      @insecure = true

      # managers for packages, configs and results
      @packages = CDRouter::PackageManager.new(self)
      @configs  = CDRouter::ConfigManager.new(self)
      @results  = CDRouter::ResultManager.new(self)
    end

    def get( url )
      if @debug == true
        puts "GET #{url}"
      end
      super(url)
    end

    def post( url , body )
      if @debug == true
        puts "POST #{url}"
        puts body
      end
      super(url, body)
    end

    def patch ( url, body )
      if @debug == true
        puts "PATCH #{url}"
        puts body
      end
      super( url, body)
    end

    def delete( url )
      if @debug == true
        puts "DELETE #{url}"
      end
      super(url)
    end
        
    def get_json( url )
      resp = get(url)
      raise "failed #{resp.status} #{resp.body}" if resp.status != 200
      result = JSON.parse(resp.body)
      debug_json result
      result
    end
    
    def version
      resp = get("/api/v1/testsuites/1/")

      if resp.status == 404
        puts "Received 404 response checking CDRouter version"
        if resp.body.include? "BuddyWeb"
           raise "This is a pre CDRouter 10.0 and does not support the API"
        else
           raise "This system does not appear to be CDRouter system"
        end
        
      elsif resp.status < 400

        # try to parse the result
        result = JSON.parse(resp.body)
        debug_json result
        result['data']['release']
      else
        raise "failed #{resp.status} #{resp.body}"
      end
    end

    def package_name_to_id(name)
      result = get_json("/api/v1/packages/?limit=none")
      package = result['data'].find { |p| p['name'] == name}
      raise "Can not find package with the name #{name}" unless package
      package['id']
    end

    def package_id_to_name(id)
      result = get_json("/api/v1/packages/#{id}/")
      result['data']['name']
    end

    def config_name_to_id(name)
      result = get_json("/api/v1/configs/?limit=none")
      config = result['data'].find { |c| c['name'] == name}
      raise "Can not find config with the name #{name}" unless config
      config['id']
    end

    def config_id_to_name(id)
      result = get_json("/api/v1/configs/#{id}/")
      result['data']['name']
    end
    
    def debug_json(result)
      if @debug == true
        puts JSON.pretty_generate(result)
      end
    end
  end

  class PackageManager
    def initialize(sess)
      @session = sess
    end

    def get(name)
      CDRouter::Package.new(@session, name: name)
    end
    
    def get(id)
      CDRouter::Package.new(@session, id: id)
    end
       
    def list(arg = {})

      if arg.key?(:tagged_with)
        result = @session.get_json("/api/v1/packages/?filter=tags@>{#{arg[:tagged_with]}}&limit=none")
      elsif arg.key?(:filter)
        result = @session.get_json("/api/v1/packages/?filter=#{arg[:filter]}&limit=none")
      else
        result = @session.get_json("/api/v1/packages/?limit=none")
      end
         
      package_list = []
      result['data'].each { |p|          
        package_list.push( CDRouter::Package.new(@session, id: p['id']) )
      }
      
      package_list
    end

    def launch( package_id, arg = {} )

      extra = arg.key?(:extra_cli_args) ? arg[:extra_cli_args] : ""
      tags = arg.key?(:tags) ? arg[:tags] : ""
      tag_list = tags.kind_of?(Array) ? tags : tags.split(",")
      
      # build POST body
      jb = { options: { tags: tag_list, extra_cli_args: extra }, package_id: package_id }
      
      name = @session.package_id_to_name( package_id )
      resp = @session.post("/api/v1/jobs/", jb.to_json )
      result = JSON.parse(resp.body)
      @session.debug_json result
      
      if resp.status < 400
        job_id = result['data']['id']
        puts "Started CDRouter package #{name} with job id #{job_id}"
      else
        puts "Received HTTP response code #{resp.status} - error: #{result['error']}"
        raise "Could not launch CDRouter package #{name}"
      end

      # -- Wait for job to finish
      status = "init"
      begin

        sleep @session.poll_interval
        result = @session.get_json("/api/v1/jobs/#{job_id}/")
        status = result['data']['status']
        puts "Checking status of CDRouter job id #{job_id}: #{status}"

      end while status != "completed"

      result_id = result['data']['result_id']
      CDRouter::Result.new(@session, result_id)
      
    end

    def load(package_id)
      result = @session.get_json("/api/v1/packages/#{package_id}/")
    end
    
  end

  class ConfigManager

    def initialize(sess)
      @session = sess
    end

    def get(name)
      CDRouter::Config.new(@session, name: name)
    end

    def get_by_id(id)
      CDRouter::Config.new(@session, id: id)
    end
    
    def load(config_id)
      result = @session.get_json("/api/v1/configs/#{config_id}/")
    end
    
    def load_text(config_id)
      resp = @session.get("/api/v1/configs/#{config_id}/?format=text")
      raise "failed #{resp.status} #{resp.body}" if resp.status != 200
      resp
    end

    def check(arg = {})
      contents = arg.key?(:contents) ? arg[:contents] : ""
      cb = { contents: contents}
      resp = @session.post("/api/v1/configs/?process=check", cb.to_json )
      result = JSON.parse(resp.body)
      @session.debug_json result
      
      if resp.status < 400
        result
      else
        raise "Received HTTP response code #{resp.status} - error: #{result['error']}"
      end
    end

    def create(arg = {})
      name = arg.key?(:name) ? arg[:name] : ""
      description = arg.key?(:description) ? arg[:description] : ""
      contents = arg.key?(:contents) ? arg[:contents] : ""
      tags = arg.key?(:tags) ? arg[:tags] : ""

      # -- handle tag array or "," list
      tag_list = tags.kind_of?(Array) ? tags : tags.split(",")
        
      cb = { name: name, description: description, contents: contents, tags: tag_list}

      resp = @session.post("/api/v1/configs/", cb.to_json )
      result = JSON.parse(resp.body)
      @session.debug_json result
      
      if resp.status < 400
        CDRouter::Config.new(@session, id: result['data']['id'])
      else
        raise "Received HTTP response code #{resp.status} - error: #{result['error']}"
      end             
    end

    def delete(name)
      begin
        config_id = @session.config_name_to_id(name)
        resp = @session.delete("/api/v1/configs/#{config_id}/")
        raise "failed #{resp.status} #{resp.body}" if resp.status != 204  
      rescue
        raise "Can not find configuration file #{name}"
      end
    end
    
    def edit(config_id, arg = {})
      name = arg.key?(:name) ? arg[:name] : ""
      description = arg.key?(:description) ? arg[:description] : ""
      contents = arg.key?(:contents) ? arg[:contents] : ""
      tags = arg.key?(:tags) ? arg[:tags] : ""

      # -- handle tag array or "," list
      tag_list = tags.kind_of?(Array) ? tags : tags.split(",")
        
      cb = { name: name, description: description, contents: contents, tags: tag_list}

      resp = @session.patch("/api/v1/configs/#{config_id}/", cb.to_json )
      result = JSON.parse(resp.body)
      @session.debug_json result
      
      if resp.status < 400
        puts "Modified CDRouter config with id #{config_id}"
      else
        puts "Received HTTP response code #{resp.status} - error: #{result['error']}"
        raise "Could not modify CDRouter config #{config_id}"
      end             
    end

    def exists?(name)
      begin
        @session.config_name_to_id(name)
        true
      rescue
        false
      end      
    end
    
    def upgrade(arg = {})
      contents = arg.key?(:contents) ? arg[:contents] : ""
      cb = { contents: contents}
      resp = @session.post("/api/v1/configs/?process=upgrade", cb.to_json )
      result = JSON.parse(resp.body)
      @session.debug_json result
      
      if resp.status < 400
        result
      else
        raise "Received HTTP response code #{resp.status} - error: #{result['error']}"
      end
    end

    def list(arg = {})
      if arg.key?(:tagged_with)
        result = @session.get_json("/api/v1/configs/?filter=tags@>{#{arg[:tagged_with]}}&limit=none")
      elsif arg.key?(:filter)
        result = @session.get_json("/api/v1/configs/?filter=#{arg[:filter]}&limit=none")
      else
        result = @session.get_json("/api/v1/configs/?limit=none")
      end
         
      config_list = []
      result['data'].each { |c|          
        config_list.push( CDRouter::Config.new(@session, id: c['id']) )
      }
      
      config_list
    end
  end
  
  class ResultManager

    def initialize(sess)
      @session = sess
    end

    def list(arg = {})
      if arg.key?(:result_id)
        result = @session.get_json("/api/v1/results/#{arg[:result_id]}/")
      elsif arg.key?(:filter)
        result = @session.get_json("/api/v1/results/?filter=#{arg[:filter]}&limit=none")
      else
        result = @session.get_json("/api/v1/results/?limit=none")
      end

      result_list = []

      if result['data'].kind_of?(Array)
        result['data'].each do |r|
           result_list.push( CDRouter::Result.new(@session, r['id']) )
        end
      else
        result_list.push( CDRouter::Result.new(@session, result['data']['id']) )
      end
      
      result_list
    end

    def get(result_id)
      result = @session.get_json("/api/v1/results/#{result_id}/")
      CDRouter::Result.new(@session, result['data']['id'])
    end

    def load(result_id)
      result = @session.get_json("/api/v1/results/#{result_id}/")
    end

    def load_seq(result_id, seq)
      result = @session.get_json("/api/v1/results/#{result_id}/tests/#{seq}/")
    end
    
    def export(result_id)
      resp = @session.get("/api/v1/results/#{result_id}/?format=gz")
      raise "failed #{resp.status} #{resp.body}" if resp.status != 200
      resp
    end

    def csv(result_id)
      resp = @session.get("/api/v1/results/#{result_id}/tests/?format=csv&limit=none")
      raise "failed #{resp.status} #{resp.body}" if resp.status != 200
      resp
    end

    def logdir(result_id)
      resp = @session.get("/api/v1/results/#{result_id}/logdir/?format=tgz")
      raise "failed #{resp.status} #{resp.body}" if resp.status != 200
      resp
    end
  end
  
  class Package
    attr_accessor :session
    attr_accessor :package_id

    attr_accessor :id
    attr_accessor :name
    attr_accessor :description
    attr_reader   :created
    attr_reader   :updated
    attr_accessor :test_count
    attr_accessor :testist
    attr_accessor :extra_cli_args
    attr_reader   :user_id
    attr_reader   :config_id
    attr_accessor :options
    attr_accessor :tags
    
    def initialize(sess, arg = {})

      @session = sess

      if arg.key?(:name)
        @package_id = @session.package_name_to_id(arg[:name])
        @name = name
      elsif arg.key?(:id)
        @package_id = arg[:id]
      else
        raise "Package must specify id: or name:"
      end
      
      refresh
    end

    def refresh
      p = @session.packages.load(@package_id)

      @id              = p['data']['id']
      @name            = p['data']['name']
      @description     = p['data']['description']
      @created         = p['data']['created']
      @updated         = p['data']['updated']
      @test_count      = p['data']['test_count']
      @testlist        = p['data']['testlist']
      @extra_cli_args  = p['data']['extra_cli_args']
      @user_id         = p['data']['user_id']
      @config_id       = p['data']['config_id']
      @options         = p['data']['options']
      @tags            = p['data']['tags']
    end
        
    def launch(arg = {})
      @session.packages.launch( @package_id, arg)
    end
  end

  class Config
    attr_accessor :session
    attr_accessor :config_id

    attr_accessor :id
    attr_accessor :name
    attr_accessor :description
    attr_reader   :created
    attr_reader   :updated
    attr_accessor :contents
    attr_reader   :user_id
    attr_accessor :tags

    attr_reader   :errors
    
    def initialize(sess, arg = {})

      # -- remeber the session
      @session = sess
      
      if arg.key?(:name)
        @config_id = @session.config_name_to_id(arg[:name])
      elsif arg.key?(:id)
        @config_id = arg[:id]
      else
        raise "Configuration must specify id: or name:"
      end
      
      refresh

    end

    def refresh
      config = @session.configs.load(@config_id)

      @id          = config['data']['id']
      @name        = config['data']['name']
      @description = config['data']['description']
      @created     = config['data']['created']
      @updated     = config['data']['updated']
      @contents    = config['data']['contents']
      @user_id     = config['data']['user_id']
      @tags        = config['data']['tags']      
    end

    def check?( arg = {} )
      config_check = arg.key?(:contents) ? arg[:contents] : @contents
      result = @session.configs.check( contents: config_check)
      @errors = result['data']['errors']

      result['data']['errors'].empty?
    end
    
    def display
      config = @session.configs.load_text(@config_id)
      puts "#{config.body}"
    end
        
    def edit
      @session.configs.edit( @config_id,
                             name: @name,
                             description: @description,
                             contents: @contents,
                             tags: @tags)
    end

    def upgrade( arg = {} )
      config_data = arg.key?(:contents) ? arg[:contents] : @contents
      result = @session.configs.upgrade( contents: config_data)
      if result['data']['success'] == true
        @contents = result['data']['output']
      else
        raise "Unable to upgrade config file #{@name}"
      end
    end

    def save
        # -- for save, we just call edit using current values
        edit
    end
  end
  
  class Result
    attr_accessor :session
    attr_accessor :result_id

    def initialize( sess, id )
      @session = sess
      @result_id = id
    end

    def name
      result_id
    end
    
    def display
      result = @session.results.load(@result_id)
      puts ""
      puts "Test result:"
      puts ""
      puts "    Summary: #{result['data']['result']}"
      puts "      Start: #{result['data']['created']}"
      puts "   Duration: #{result['data']['duration']} seconds"
      puts "    Package: #{result['data']['package_name']}"
      puts "     Config: #{result['data']['config_name']}"
      puts "       Tags: " + result['data']['tags'].join(',')
      puts "      Tests: #{result['data']['tests']}"
      puts "       Pass: #{result['data']['pass']}"
      puts "       Fail: #{result['data']['fail']}"
      puts ""
      puts " Report URL: #{session.base_url}/results/#{result_id}"
      puts "  Print URL: #{session.base_url}/results/#{result_id}/print/"
      puts ""
    end

    def export_to_file( path = @result_id + ".gz" )
      resp = @session.results.export(@result_id)
      gz = File.open( path, 'w')
      gz.write( resp.body)
      gz.close        
    end

    def to_csv
      resp = @session.results.csv(@result_id)
      resp.body      
    end

    def logdir_to_tgz( path = "logs_" + @result_id + ".tgz" )
      resp = @session.results.logdir(@result_id)
      logs = File.open( path, 'w')
      logs.write( resp.body)
      logs.close        
    end
     

    def to_junit()
      result = @session.results.load(@result_id)
      max = result['data']['tests']
      
      junit = ""
      junit.concat("<testsuite name=\"CDRouter\" package=\"#{result['data']['package_name']}\" failures=\"#{result['data']['fail']}\" tests=\"#{result['data']['tests']}\">\n")
      
      for seq in 1..max
        result = @session.results.load_seq( result_id, seq )
        test  = "#{result['data']['name']}"
        status = "#{result['data']['result']}"
          
        junit.concat("<testcase name=\"#{test}\">\n")
        
        if status == "fail" || status == "fatal"
          junit.concat("<failure message=\"test failure\">\n")
          junit.concat("View the full CDRouter test log #{session.base_url}/results/#{result_id}/tests/#{seq}\n")
          junit.concat("</failure>\n")
        elsif status == "pending" || status == "skipped"          
          junit.concat("<skipped/>\n")
        end

        junit.concat("</testcase>\n")
        
      end
      
      junit.concat("</testsuite>\n")
      
    end

    def to_jenkins
      # -- convert to junit (the jenkins format)
      to_junit
    end
  end
end

