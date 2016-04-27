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

