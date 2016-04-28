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
  
  class ResultManager

    def initialize(sess)
      @session = sess
    end

    def list(arg = {})
      if arg[:result_id]
        result = @session.get_json("/api/v1/results/#{arg[:result_id]}/")
      elsif arg[:filter]
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

    def load_all_seq(result_id)
      result = @session.get_json("/api/v1/results/#{result_id}/tests/?limit=none")
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
  
  class Result
    attr_accessor :session
    attr_accessor :result_id

    attr_reader   :id
    attr_reader   :created
    attr_reader   :updated
    attr_reader   :result
    attr_reader   :status
    attr_reader   :loops
    attr_reader   :tests
    attr_reader   :pass
    attr_reader   :fail
    attr_reader   :duration
    attr_reader   :size_on_disk
    attr_reader   :starred
    attr_reader   :archived
    attr_reader   :package_name
    attr_reader   :package_id
    attr_reader   :config_id
    attr_reader   :user_id
    attr_reader   :note
    attr_reader   :tags
    attr_reader   :testcases
    attr_reader   :options

    attr_reader   :test_results
    
    def initialize( sess, id )
      @session = sess
      @result_id = id

      refresh
    end

    def refresh
      r = @session.results.load(@result_id)

      @id           = r['data']['id']
      @created      = r['data']['created']
      @updated      = r['data']['updated']
      @result       = r['data']['result']
      @status       = r['data']['status']
      @loops        = r['data']['loops'].to_i
      @tests        = r['data']['tests']
      @pass         = r['data']['pass'].to_i
      @fail         = r['data']['fail'].to_i
      @duration     = r['data']['duration'].to_i
      @size_on_disk = r['data']['size_on_disk'].to_i
      @starred      = r['data']['starred']
      @archived     = r['data']['archived']
      @package_name = r['data']['package_name']
      @config_name  = r['data']['config_name']
      @package_id   = r['data']['package_id']
      @config_id    = r['data']['config_id']
      @user_id      = r['data']['user_id']
      @note         = r['data']['note']
      @tags         = r['data']['tags']
      @testcases    = r['data']['testcases']
      @options      = r['data']['options']

      @test_results = @session.results.load_all_seq(@result_id)

    end
    
    def name
      result_id
    end
    
    def display
      puts ""
      puts "Test result:"
      puts ""
      puts "    Summary: #{@result}"
      puts "      Start: #{@created}"
      puts "   Duration: #{@duration} seconds"
      puts "    Package: #{@package_name}"
      puts "     Config: #{@config_name}"
      puts "       Tags: " + @tags.join(',')
      puts "      Tests: #{@tests}"
      puts "       Pass: #{@pass}"
      puts "       Fail: #{@fail}"
      puts ""
      puts " Report URL: #{session.base_url}/results/#{@result_id}"
      puts "  Print URL: #{session.base_url}/results/#{@result_id}/print/"
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
      junit = ""
      junit.concat("<testsuite name=\"CDRouter\" package=\"#{@package_name}\" failures=\"#{@fail}\" tests=\"#{@tests}\">\n")

      # -- loop over all the results
      @test_results['data'].each { |t|  

        test  = "#{t['name']}"
        status = "#{t['result']}"

        # -- add a testcase tag
        junit.concat("<testcase name=\"#{test}\">\n")
        
        if status == "fail" || status == "fatal"
          junit.concat("<failure message=\"test failure\">\n")
          junit.concat("View the full CDRouter test log #{session.base_url}/results/#{result_id}/tests/#{t['seq']}\n")
          junit.concat("</failure>\n")
        elsif status == "pending" || status == "skipped"          
          junit.concat("<skipped/>\n")
        end

        junit.concat("</testcase>\n")
      }
      junit.concat("</testsuite>\n")
      
    end

    def to_jenkins
      # convert to junit (the jenkins format)
      to_junit
    end
  end
end

