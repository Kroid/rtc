module API
  class Base < Grape::API
    mount API::Web
  end
end