require 'mina/git'
# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

case ENV['to']
  when 'production'
    set :domain, 'www.foo.bar'
    set :deploy_to, '/home/foo'
    set :repository, '/home/git/repositories/foo.git'
    set :branch, 'deploy'
  else
    set :domain, '5.135.191.121'
    set :deploy_to, '/var/www/Mina'
    set :repository, 'git@github.com:degetel-jlavialle/test.git'
    set :branch, 'master'
end

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['sites/default/settings.php', 'cache', 'sites/default/files']

# Optional settings:
set :user, 'root'    # Username in the server to SSH to.
#set :port, '22'     # SSH port number.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/sites/default/files"]
  queue! %[chmod g+rwx,u+rwx "#{deploy_to}/shared/sites/default/files"]

  queue! %[mkdir -p "#{deploy_to}/shared/sites/default/files_private"]
  queue! %[chmod g+rwx,u+rwx "#{deploy_to}/shared/sites/default/files_private"]

  queue! %[mkdir -p "#{deploy_to}/shared/sites/default/tmp"]
  queue! %[chmod g+rwx,u+rwx "#{deploy_to}/shared/sites/default/tmp"]

  queue! %[mkdir -p "#{deploy_to}/shared/sites/default/sql_dumps"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/sites/default/sql_dumps"]

  queue! %[touch "#{deploy_to}/shared/sites/default/settings.php"]
  queue  %[echo "Be sure to edit."]
end

desc "Deploys the current version to the server for the first deployment."
task :first_deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
  end
end

desc "Deploys the current version to the server, and backup database."
task :deploy => :environment do
  deploy do
    # Breek: Specific Drupal tasks
    invoke :'site_offline'
    invoke :'backup_database'

    # Common Mina tasks
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'

    # Breek: Specific Drupal tasks
    invoke :'backup_database'
    invoke :'database_updates'
    invoke :'pull_master'
    invoke :'run_cron'
    invoke :'clear_caches'
    invoke :'clear_advagg'

    to :launch do
      invoke :'site_online'
    end
  end
end

desc "Site is put in maintenance mode"
task :site_offline do
  queue %[echo "-----> Site is put in maintenance mode."]
  queue %[drush --root=#{deploy_to}/test --uri=http://#{domain} variable-set --yes --pipe --always-set maintenance_mode 1]
end

desc "Site is put in live"
task :site_online do
  queue %[echo "-----> Site is put in live."]
  queue %[drush --root=#{deploy_to}/test --uri=http://#{domain} variable-set --yes --pipe --always-set maintenance_mode 0]
end

desc "Clearing Drupal caches"
task :clear_caches do
  queue %[echo "-----> Clearing Drupal caches."]
  queue %[drush --root=#{deploy_to}/test --uri=http://#{domain} --yes --pipe cache-clear all]
end

desc "Clear advagg directories"
task :clear_advagg do
  queue %[echo "-----> Clearing AdvAgg directories."]
  queue %[rm -Rf #{deploy_to}/shared/sites/default/files/advagg_css/*]
  queue %[rm -Rf #{deploy_to}/shared/sites/default/files/advagg_js/*]
end

desc "Backuping up database using Drush"
task :backup_database do
  queue %[echo "-----> Backuping up database using Drush."]
  t = Time.now.strftime("%Y-%m-%dT%H-%M-%S")
  queue %[drush --root=#{deploy_to}/test --uri=http://#{domain} --yes --pipe sql-dump --gzip --result-file=#{deploy_to}/shared/sites/default/sql_dumps/#{domain}-#{t}.sql]
  queue %[echo "-----> #{deploy_to}/shared/sites/default/sql_dumps/#{domain}-#{t}.sql"]
end

desc "Executing database updates"
task :database_updates do
  queue %[echo "-----> Executing database updates."]
  queue %[drush --root=#{deploy_to}/test --uri=http://#{domain} --yes --pipe updatedb]
end

desc "Running cron"
task :run_cron do
  queue %[echo "-----> Running cron."]
  queue %[drush --root=#{deploy_to}/test --uri=http://#{domain} --yes --pipe cron]
end

desc "Pull Master"
task :pull_master do
  queue %[echo "-----> Pull Master."]
  queue %[cd /var/www/Mina/test;git pull origin master]
end

desc "Reverte Features test_admin"
task :pull_master do
  queue %[echo "-----> Reverte feature admin."]
  queue %[drush --root=#{deploy_to}/test --uri=http://#{domain} --yes --pipe fr test_admin]
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers

