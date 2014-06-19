# config valid only for Capistrano 3.1
lock '3.1.0'


#set :rvm_ruby_version, 'ruby-1.9.3-p547'
set :default_env, { rvm_bin_path: '~/.rvm/bin' }
 set :deploy_to, '/home/nyros/anusha/cap_demo'
SSHKit.config.command_map[:rake]  = "#{fetch(:default_env)[:rvm_bin_path]}/rvm ruby-#{fetch(:rvm_ruby_version)} do bundle exec rake"
set :application, 'cap_demo'
set :repo_url, 'https://github.com/anusha-nyros/cap_demo.git'
set :rails_env, "production"
# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app


# Default value for :scm is :git
 set :scm, :git

 set :deploy_via, :remote_cache
# Default value for :format is :pretty
 set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true
set :ssh_options, {:forward_agent => true}
set :default_run_options, {:pty => true}
# Default value for :linked_files is []

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
 set :keep_releases, 5
set :template_dir, '/home/nyros/Anu/ROR_Projects/June/Jun19/democapapp/config/deploy'

namespace :deploy do
desc "Start the Thin processes"
  task :start do
	on roles(:app), in: :sequence do |server|
        within release_path do
          with rails_env: fetch(:rails_env) do
	set :app_port, ask("Port", nil)
	execute :bundle, "exec thin start -p #{fetch(:app_port)} -d -e RAILS_ENV=#{fetch(:rails_env)}"
        #execute :bundle, "exec rails s -p 2003 -d -e RAILS_ENV=#{fetch(:rails_env)}"
          end
        end
      end
  end

  desc "Stop the Thin processes"
  task :stop do
      on roles(:app), in: :sequence do |server|
        within release_path do
          with rails_env: fetch(:rails_env) do
	execute :bundle, "exec thin stop -p #{fetch(:app_port)} -d -e RAILS_ENV=#{fetch(:rails_env)}"
        #execute :bundle, "exec rails s -p 2003 -d -e RAILS_ENV=#{fetch(:rails_env)}"
          end
        end
      end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
	puts "Deployed successfully"
      execute "touch #{release_path}/tmp/restart.txt"
     # execute "touch #{current_path}/tmp/thin.pid"
	#execute :bundle, "exec thin restart -p 2003 -d -e RAILS_ENV=#{fetch(:rails_env)}"
    end
  end
 desc "Linking Database.yml file"
 task :symlink do
    on roles(:app) do
     execute "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/"
    end
 end
desc "Setting Database configuration"
 task :generate_yml do
	on roles(:app), in: :sequence do |server|
		set :db_username, ask("DB Server Username", nil)
		set :db_password, ask("DB Server Password", nil)
		 
		db_config = <<-EOF
development:
  database: #{fetch(:application)}_development
  adapter: mysql2
  encoding: utf8
  reconnect: false
  pool: 5
  username: #{fetch(:db_username)}
  password: #{fetch(:db_password)}		 
test:
  database: #{fetch(:application)}_test
  adapter: mysql2
  encoding: utf8
  reconnect: false
  pool: 5
  username: #{fetch(:db_username)}
  password: #{fetch(:db_password)}   
production:
  database: #{fetch(:application)}_production
  adapter: mysql2
  encoding: utf8
  reconnect: false
  pool: 5
  username: #{fetch(:db_username)}
  password: #{fetch(:db_password)}
EOF
		location = fetch(:template_dir, "config/deploy") + '/database.yml'
		execute "mkdir -p #{shared_path}/config"
		execute "mkdir -p #{shared_path}/config"
		File.open(location,'w+') {|f| f.write db_config }
		upload! "#{location}", "#{shared_path}/config/database.yml"
		#execute "cat #{db_config}">"#{shared_path}/config/database.yml"
		#put db_config, "#{shared_path}/config/database.yml"
	end
end
desc 'Runs rake db:create'
    task :create => [:set_rails_env] do
      on roles(:all) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, "db:create RAILS_ENV=#{fetch(:rails_env)}"
          end
        end
      end
    end

desc 'Runs rake db:migrate'
    task :create => [:set_rails_env] do
      on roles(:all) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, "db:migrate RAILS_ENV=#{fetch(:rails_env)}"
          end
        end
      end
    end

 task :assets do
      on roles(:all) do
        within release_path do
          with rails_env: fetch(:rails_env) do
		puts "assets precompilation"
            execute :rake, 'assets:precompile RAILS_ENV=#{fetch(:rails_env)}'
          end
        end
      end
    end

before "deploy:assets:precompile", :generate_yml
before "deploy:assets:precompile", :symlink 
before "deploy:migrate", :create
  #before "deploy:finishing", :stop
  after :publishing, :restart
 #after :restart, :stop 
 after :restart, :start

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
       #within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
