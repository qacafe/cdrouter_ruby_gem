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
  
  class HistoryManager

    def initialize(sess)
      @session = sess
    end

    def list(arg = {})

      limit = arg[:limit] || "none"
      
      if arg[:filter]
        result = @session.get_json("/api/v1/history/?filter=#{arg[:filter]}&limit=#{limit}")
      else
        result = @session.get_json("/api/v1/history/?limit=#{limit}")
      end

      history_list = []

      if result['data'].kind_of?(Array)
        result['data'].each do |r|
          history_list.push( CDRouter::HistoryEntry.new(@session,
                                                        r['user_id'],
                                                        r['created'],
                                                        r['resource'],
                                                        r['id'],
                                                        r['name'],
                                                        r['action'],
                                                        r['description']))
        end
      else
        history_list.push( CDRouter::HistoryEntry.new(@session,
                                                      result['data']['user_id'],
                                                      result['data']['created'],
                                                      result['data']['resource'],
                                                      result['data']['id'],
                                                      result['data']['name'],
                                                      result['data']['action'],
                                                      result['data']['description']))
      end
      history_list
    end

    def load(history_id)
      entry = @session.get_json("/api/v1/history/#{history_id}/")
    end

  end
  
  class HistoryEntry
    attr_accessor :session

    attr_reader   :user_id
    attr_reader   :created
    attr_reader   :resource
    attr_reader   :id
    attr_reader   :name
    attr_reader   :action
    attr_reader   :description
    
    def initialize( sess, user_id, created, resource, id, name, action, description )
      @session = sess

      @user_id      = user_id
      @created      = created
      @resource     = resource
      @id           = id
      @name         = name
      @action       = action
      @description  = description

    end

    def display

      puts ""
      puts "History entry:"
      puts ""
      puts "   created: #{@created}"
      puts "   action: #{@action}"
      puts "   description: #{@description}"
      puts "   resource: #{@resource}"
      puts ""
      
    end
    
  end
end

