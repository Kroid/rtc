class API::Web::Example < API::Web

  namespace 'example' do
    get '/', jbuilder: 'example/index.json' do
      @resp = {msg: 'GET /api/web/example.json'}
    end
  end
end