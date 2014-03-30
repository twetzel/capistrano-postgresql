require 'capistrano/postgresql/helper_methods'

include Capistrano::Postgresql::HelperMethods

namespace :load do
  task :defaults do
    set :postgresql_database,   -> { "#{fetch(:application)}_#{fetch(:stage)}" }
    set :postgresql_user,       -> { fetch(:postgresql_database) }
    set :postgresql_password,   -> { ask_for_or_generate_password }
    set :postgresql_ask_for_password, false
    # template only settings (used in postgresql.yml.erb)
    set :postgresql_templates_path,   'config/deploy/templates'
    set :postgresql_pool,     5
    set :postgresql_encoding, 'unicode'
    set :postgresql_host,     'localhost'

    set :linked_files, fetch(:linked_files, []).push('config/database.yml')
  end
end

namespace :postgresql do

  desc 'Create DB user'
  task :create_db_user do
    on roles :db do
      ensure_db_user_created fetch(:postgresql_user), fetch(:postgresql_password)
    end
  end

  desc 'Create database'
  task :create_database do
    on roles :db do
      ensure_database_created fetch(:postgresql_database), fetch(:postgresql_user)
    end
  end

  desc 'Generate database.yml'
  task :generate_database_yml do
    on roles :app do
      database_yml_path = shared_path.join('config/database.yml')
      next if remote_file_exists?(database_yml_path)
      execute :mkdir, '-p', shared_path.join('config')
      database_yml_template 'postgresql.yml.erb', database_yml_path
    end
  end

  after 'deploy:started', 'postgresql:create_db_user'
  after 'deploy:started', 'postgresql:create_database'
  after 'deploy:started', 'postgresql:generate_database_yml'

end
