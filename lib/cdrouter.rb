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

# -- additional CDRouter modules files
require 'cdrouter/version'
require 'cdrouter/session'
require 'cdrouter/package'
require 'cdrouter/config'
require 'cdrouter/result'
require 'cdrouter/history'
require 'cdrouter/user'
require 'cdrouter/device'

module CDRouter
  def version
    VERSION
  end
end

