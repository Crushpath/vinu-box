require "./boxapp"
include Rake::DSL

task :console do
  binding.pry
end

namespace :crushpath do

  desc "Send pitch stats"
  task :send_pitch_stats do
    # Here we call a model to send the data to 
    # the email endpoint
    # All the work regarding data it's done by a method in boxapp
    # To call this once a day we use a cron task
  end
end
