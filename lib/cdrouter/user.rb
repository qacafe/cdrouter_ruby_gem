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
  
  class UserManager

    def initialize(sess)
      @session = sess
    end

    def list(arg = {})

      limit = arg[:limit] || "none"
      
      if arg[:user_id]
        result = @session.get_json("/api/v1/users/#{arg[:user_id]}/")
      elsif arg[:filter]
        result = @session.get_json("/api/v1/users/?filter=#{arg[:filter]}&limit=#{limit}")
      else
        result = @session.get_json("/api/v1/users/?limit=#{limit}")
      end

      user_list = []

      if result['data'].kind_of?(Array)
        result['data'].each do |r|
           user_list.push( CDRouter::User.new(@session, r['id']) )
        end
      else
        user_list.push( CDRouter::User.new(@session, result['data']['id']) )
      end
      user_list
    end

    def get(user_id)
      result = @session.get_json("/api/v1/users/#{user_id}/")
      CDRouter::User.new(@session, result['data']['id'])
    end

    def load(user_id)
      result = @session.get_json("/api/v1/users/#{user_id}/")
    end
  end
  
  class User
    attr_accessor :session

    attr_reader   :id
    attr_reader   :admin
    attr_reader   :disabled
    attr_reader   :name
    attr_reader   :description
    
    def initialize( sess, id )
      @session = sess
      @id = id

      refresh
    end

    def refresh
      u = @session.users.load(@id)

      @id           = u['data']['id']
      @admin        = u['data']['admin']
      @disabled     = u['data']['disabled']
      @name         = u['data']['name']
      @description  = u['data']['description']

    end
  end
end

