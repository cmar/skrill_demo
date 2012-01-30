$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"
require "bundler/capistrano"
load 'deploy/assets'

set :application, "skrill_demo"
set :user, 'spree'
set :group, 'www-data'
set :domain, "skrill.spreeworks.com"

set :rvm_ruby_string, 'ruby-1.9.2-p290'

set :scm, :git

role :web, domain
role :app, domain
role :db,  domain, :primary => true

set :repository,  "git@github.com:cmar/skrill_demo.git"
set :branch,      "master"
set :deploy_to,   "/data/#{application}"
set :deploy_via,  :remote_cache
set :use_sudo,    false

default_run_options[:pty] = true
set :ssh_options, { :forward_agent => true }

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, :roles => :app do
    run "cd #{current_path} && bundle exec foreman export upstart /etc/init -a #{application}  -u spree"
  end

  desc "Start the application services"
  task :start, :roles => :app do
    sudo "start #{application}"
  end

  desc "Stop the application services"
  task :stop, :roles => :app do
    sudo "stop #{application}"
  end

  desc "Restart the application services"
  task :restart, :roles => :app do
    sudo "restart #{application}"
  end
end

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/Procfile #{release_path}/Procfile"

    run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
    run "ln -nfs #{shared_path}/system #{release_path}/public/system"
  end

  desc "Compile assets"
  task :precompile_assets, :roles => :app do
    run "cd #{current_path} && rake assets:precompile"
  end
end

before 'deploy:assets:precompile', 'deploy:symlink_shared'
after 'deploy:update_code', 'deploy:symlink_shared'
after 'deploy:restart', 'foreman:export'
after 'foreman:export', 'foreman:restart'

