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
require 'patron'

# -- Require for JSON handling
require 'json'

module CDRouter
  class Session < Patron::Session

    attr_accessor :debug
    attr_accessor :poll_interval
    attr_reader   :packages
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

      # managers for packages and results
      @packages = CDRouter::PackageManager.new(self)
      @results = CDRouter::ResultManager.new(self)      

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
      result = get_json("/api/v1/packages/?limit=none")
      package = result['data'].find { |p| p['id'] == id}
      raise "Can not find package with id #{id}" unless package
      package['name']
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
        package_list.push( CDRouter::Package.new(@session, p['name']) )
      }
      
      package_list

    end


    def launch( package_id, arg = {} )

      if arg.key?(:extra_cli_args)
        extra = arg[:extra_cli_args]
      else
        extra = ""
      end

      if arg.key?(:tags)
        tag_list = arg[:tags].split ","
      else
        tag_list = ""
      end

      # build POST body
      jb = { options: { tags: tag_list, extra_cli_args: extra }, package_id: package_id }
      
      name = @session.package_id_to_name( package_id )
      resp = @session.post("/api/v1/jobs/", jb.to_json )
      result = JSON.parse(resp.body)

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
    attr_accessor :name
    attr_accessor :package_id

    def initialize(sess, name)
      @name = name
      @session = sess
      @package_id = @session.package_name_to_id(name)

    end

    def launch(arg = {})
      @session.packages.launch( @package_id, arg)
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

