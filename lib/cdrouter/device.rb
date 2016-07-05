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

  class DeviceManager
    def initialize(sess)
      @session = sess
    end

    def get(name)
      CDRouter::Device.new(@session, name: name)
    end
    
    def get(id)
      CDRouter::Device.new(@session, id: id)
    end
       
    def list(arg = {})

      if arg[:tagged_with]
        result = @session.get_json("/api/v1/devices/?filter=tags@>{#{arg[:tagged_with]}}&limit=none")
      elsif arg[:filter]
        result = @session.get_json("/api/v1/devices/?filter=#{arg[:filter]}&limit=none")
      else
        result = @session.get_json("/api/v1/devices/?limit=none")
      end
         
      device_list = []
      result['data'].each { |d|          
        device_list.push( CDRouter::Device.new(@session, id: d['id']) )
      }
      
      device_list
    end


    def load(device_id)
      result = @session.get_json("/api/v1/devices/#{device_id}/")
    end
    
  end

  class Device
    attr_accessor :session
    attr_accessor :device_id
    
    attr_accessor :id
    attr_accessor :name
    attr_accessor :description
    attr_reader   :created
    attr_reader   :updated
    attr_accessor :user_id
    attr_accessor :attachments_dir
    attr_accessor :pciture_id
    attr_reader   :tags
    attr_reader   :default_ip
    attr_accessor :default_login
    attr_accessor :default_password
    attr_accessor :location
    attr_accessor :device_category
    attr_accessor :manufacturer
    attr_accessor :manufacturer_oui
    attr_accessor :model_name
    attr_accessor :model_number
    attr_accessor :description
    attr_accessor :product_class
    attr_accessor :serial_number
    attr_accessor :hardware_version
    attr_accessor :software_version
    attr_accessor :provisioning_code
    attr_accessor :note
    
    def initialize(sess, arg = {})

      @session = sess

      if arg[:name]
        @device_id = @session.device_name_to_id(arg[:name])
        @name = name
      elsif arg[:id]
        @device_id = arg[:id]
      else
        raise "Device must specify id: or name:"
      end
      
      refresh
    end

    def refresh
      p = @session.devices.load(@device_id)

      @id                = p['data']['id']
      @name              = p['data']['name']
      @created           = p['data']['created']
      @updated           = p['data']['updated']
      @user_id           = p['data']['user_id']
      @attachments_dir   = p['data']['attachments_dir']
      @picture_id        = p['data']['picture_id']
      @tags              = p['data']['tags']
      @default_ip        = p['data']['default_ip']
      @default_login     = p['data']['default_login']
      @default_password  = p['data']['default_password']
      @location          = p['data']['location']
      @device_category   = p['data']['device_category']
      @manufacturer      = p['data']['manufacturer']
      @manufacturer_oui  = p['data']['manufacturer_oui']
      @model_name        = p['data']['model_name']
      @model_number      = p['data']['model_number']
      @description       = p['data']['description']
      @product_class     = p['data']['product_class']
      @serial_number     = p['data']['serial_number']
      @hardware_version  = p['data']['hardware_version']
      @software_version  = p['data']['software_version']
      @provisioning_code = p['data']['provisioning_code']
      @note              = p['data']['note']

    end

    def results
      @session.results.list( :filter => "device_name=" + @name)
    end
  end
end

