require "./boxapp"
include Rake::DSL

task :console do
  binding.pry
end

namespace :crushpath do

  desc "Send pitch stats"
  task :send_pitch_stats do
    text = ""
    users = User.all.to_a.sort_by(&:num_pitches)

    Pony.mail :to => 'pitch@crushpath.com',
      :from => ENV['GMAIL_SMTP_USER'],
      :subject => 'Hola! New Pitch File Created',
      :html_body => (haml :daily_summary, :layout => false, :format => :html5, :users => users),
      :via => :smtp,
      :via_options => {
      :address => 'smtp.gmail.com',
      :user_name => ENV['GMAIL_SMTP_USER'],
      :password => ENV['GMAIL_SMTP_PASSWORD']
    }
    # To call this once a day we use a cron task
  end
end
