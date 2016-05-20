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
      contents = arg[:contents] || ""
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
      name        = arg[:name] || ""
      description = arg[:description] || ""
      contents    = arg[:contents] || ""
      tags        = arg[:tags] || ""

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
      name        = arg[:name] || ""
      description = arg[:description] || ""
      contents    = arg[:contents] || ""
      tags        = arg[:tags] || ""

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
      contents = arg[:contents] || ""
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
      if arg[:tagged_with]
        result = @session.get_json("/api/v1/configs/?filter=tags@>{#{arg[:tagged_with]}}&limit=none")
      elsif arg[:filter]
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
      
      if arg[:name]
        @config_id = @session.config_name_to_id(arg[:name])
      elsif arg[:id]
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
      config_check = arg[:contents] || @contents
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
      config_data = arg[:contents] || @contents
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

    def save_to_file ( path = @name )
      config = @session.configs.load_text(@config_id)
      c = File.open( path, 'w')
      c.write(config.body)
      c.close
      path
    end
  end
end

