module Multitest::Tasks
  desc "Test all your code in parallel"
  task :multitest => ['multitest:units', 'multitest:functionals', 'multitest:integration']
  
  namespace :multitest do
    desc "Multi-core test:units"
    task :units => [:environment] do
      pattern = 'test/unit/**/*_test.rb'
      files = Dir.glob(pattern)
      $stderr.write "Running multitest:units\n"
      Multitest.new(files).run
      $stderr.write "Completed multitest:units\n\n"
    end
    desc "Multi-core test:functionals"
    task :functionals => [:environment] do
      pattern = 'test/functional/**/*_test.rb'
      files = Dir.glob(pattern)
      $stderr.write "Running multitest:functionals\n"
      Multitest.new(files).run
      $stderr.write "Completed multitest:functionals\n\n"
    end
    desc "Multi-core test:integration"
    task :integration => [:environment] do
      pattern = 'test/integration/**/*_test.rb'
      files = Dir.glob(pattern)
      $stderr.write "Running multitest:integration\n"
      Multitest.new(files).run
      $stderr.write "Completed multitest:integration\n\n"
    end
    
    desc "db:setup databases for each core"
    task :setup => [:environment] do
      base_config = ActiveRecord::Base.configurations[RAILS_ENV]
      root_db_name = base_config["database"]
      (1..Multitest.cores).to_a.each do |i|
        base_config["database"] = "#{root_db_name}#{i}"
        ActiveRecord::Base.establish_connection(base_config)
        Rake::Task['db:setup'].invoke
        reenable_recursively('db:setup')
      end
    end
  end
end

# Current Problems/Hacks
#   1) For some reason 6 databases are created even though I've set cores to 2
#   2) Hard-coding a check to db: namespace below
def reenable_recursively(task_name)
  Rake::Task[task_name].send(:instance_variable_get, "@prerequisites").each { |prereq| 
    if Rake.application.lookup(prereq)
      reenable_recursively(prereq)
    else
      reenable_recursively("db:#{prereq}")
    end
  }
  Rake::Task[task_name].reenable    
end
