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


module CDRouter

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
      @test_count      = p['data']['test_count'].to_i
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
end

