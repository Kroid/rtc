require 'grape/jbuilder'

module API
  class Web < API::Base
    prefix 'web'

    format :json
    formatter :json, Grape::Formatter::Jbuilder

    before do
      env['api.tilt.root'] = 'app/views/api/web'
    end

    mount API::Web::Example
  end
end