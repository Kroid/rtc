class Configurator
  attr_accessor :api, :app_name, :assets, :grape, :postgres, :postgres_db_name

  def postgres_database_yml
    %(
      development:
        adapter: postgresql
        database: #{@postgres_db_name}_development
        username: postgres
        password: postgres"

      test:
        adapter: postgresql
        database: #{@postgres_db_name}_test
        username: postgres
        password: postgres"
    )
  end

  def initialize(api, app_name)
    @api      = api
    @app_name = app_name

    self.questions
    
    self.clear
    
    self.prepare_assets if @assets
    self.prepare_grape  if @grape
    self.prepare_postgres if @postgres
    self.prepare_sqlite unless @postgres
    self.prepare_gems

    @api.after_bundle do
      self.prepare_rspec
      self.prepare_git
    end
  end

  def questions
    @assets   = @api.yes?('Do you want to serve frontend on rails?')
    @grape    = @api.yes?('Do you want to use grape for api?')
    @postgres = @api.yes?('Do you want to use postgres database?')

    @postgres_db_name = @api.ask('Enter the postgres database name') if @postgres
    @postgres_db_name = @app_name unless @postgres_db_name.present?
  end
  
  def clear
    @api.run 'rm README.rdoc'

    @api.run 'rm Gemfile && touch Gemfile'
    @api.add_source 'https://rubygems.org'
  end

  def prepare_assets
    @api.gem 'sass-rails', '~> 5.0'
    @api.gem 'haml-rails'
    @api.gem 'uglifier', '>= 1.3.0'
  end

  def prepare_dir(dir)
    dir = File.join(File.dirname(__FILE__), 'files', dir)
    files = Dir["#{dir}/**/*"].select {|f| File.file? f}

    files.each do |file|
      basename = File.basename file
      dirname  = File.dirname(file)[dir.length+1..-1]
      content  = File.read file

      @api.run "mkdir -p #{dirname}"
      @api.run "echo '#{content}' > #{dirname}/#{basename}"
    end
  end
  
  def prepare_gems
    @api.gem 'rails', '4.2.0'
    @api.gem 'jbuilder', '~> 2.0'
    @api.gem 'bcrypt',   '~> 3.1.7'

    @api.gem 'rspec-rails',        '~> 3.1.0', :group => [:development, :test]
    @api.gem 'factory_girl_rails', '~> 4.5.0', :group => [:development, :test]

    @api.gem 'byebug',                :group => :development
    @api.gem 'web-console', '~> 2.0', :group => :development
    @api.gem 'spring',                :group => :development
  end
  
  def prepare_git
    gitignore = '
      config/database.yml
    '
    @api.run "echo '#{gitignore}' > .gitignore"

    @api.git :init
    @api.git add: "."
    @api.git commit: %Q{ -m 'Initial commit' }
  end

  def prepare_grape
    @api.gem 'grape',          '~> 0.9.0'
    @api.gem 'grape-jbuilder', '~> 0.2.0'

    @api.environment 'config.paths.add "#{Rails.root}/app/api", glob: "**/*.rb"'
    @api.environment 'config.autoload_paths += Dir["#{Rails.root}/app/api/*"]'

    @api.route "mount API::Base => '/api'"

    self.prepare_dir('grape')
  end

  def prepare_postgres
    @api.gem 'pg'
    @api.run "echo '#{self.postgres_database_yml}' > config/database.yml"
  end

  def prepare_rspec
    @api.environment '
      config.generators do |g|
        g.test_framework :rspec,
          fixtures: true,
          view_specs: false,
          helper_specs: false,
          routing_specs: false,
          controller_specs: true,
          request_specs: false
        g.fixture_replacement :factory_girl, dir: "spec/factories"
      end
    '
    @api.run 'bundle binstubs rspec-core'
    @api.generate 'rspec:install'
    # @api.run 'rails g rspec:install'
  end

  def prepare_sqlite
    @api.gem 'sqlite3'
  end

end