class SafeFork
  def self.fork(child_number)
    begin
      our_config = ActiveRecord::Base.configurations[RAILS_ENV].dup
      root_db_name = our_config["database"]
      # remove our connection so it doesn't get cloned
      ActiveRecord::Base.remove_connection if defined?(ActiveRecord)
      # fork a process
      child = Process.fork do
        begin
          # create a new connection and perform the action
          our_config["database"] = "#{root_db_name}#{child_number}"
          ActiveRecord::Base.establish_connection(our_config) if defined?(ActiveRecord)
          yield
        ensure
          # make sure we remove the connection before we're done
          ActiveRecord::Base.remove_connection if defined?(ActiveRecord)
        end      
      end
    ensure
      # make sure we re-establish the connection before returning to the main instance
      ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
    end
    return child
  end
end

