module FreshBooks
  class TimeEntry < FreshBooks::Base
    define_schema do |s|
      s.fixnum :time_entry_id, :project_id, :task_id
      s.float :hours
      s.date :date
      s.string :notes
    end
    
    actions :list, :get, :create, :update, :delete
  end
end
