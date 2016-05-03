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
      @connect_timeout = 10
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

    def import_from_file(path)

      # step 1
      resp = post_multipart("/api/v1/imports/", {}, { :file => path } )
      result = JSON.parse(resp.body)
      raise "failed #{resp.status} #{resp.body}" if resp.status != 200  
      commit_id = result['data']['id']
      
      # step 2
      result2 = get_json("/api/v1/imports/#{commit_id}/request/")
      body = result2['data'].to_json

      # step 3
      resp = post("/api/v1/imports/#{commit_id}/", body)
      result = JSON.parse(resp.body)
      raise "failed #{resp.status} #{resp.body}" if resp.status != 200  
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
end

