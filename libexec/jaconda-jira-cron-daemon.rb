# Generated cron daemon
require 'yaml'
require 'active_support/time'
require 'memcache'

# Do your post daemonization configuration here
# At minimum you need just the first line (without the block), or a lot
# of strange things might start happening...
DaemonKit::Application.running! do |config|
  # Trap signals with blocks or procs
  config.trap('INT') do
    # DaemonKit.logger.debug "INT caught completed at #{Time.now}"
  end
  config.trap('TERM') do
    # DaemonKit.logger.debug "TERM caught at #{Time.now}"
  end
end

DaemonKit::Cron.scheduler.every('180s') do
  today = Time.now.in_time_zone('US/Pacific')
  the_past = today - 15.minutes
  prompt = ''

  mc = MemCache.new('localhost:11211')

  DaemonKit.logger.debug "Scheduled task completed at #{today}"

  # all messages from Jaconda
  messages = Jaconda::API::Message.find(:all, :params => {:room_id => 'aei', :per_page => 50, :page => 1})
  messages.each do |msg|
    msg = msg.attributes
    # skip if api
    next unless msg['kind'] == 'chat'

    msg_date = Time.parse(msg['updated_at']).in_time_zone('US/Pacific')

    # skip if too old ( 15 minutes )
    next unless msg_date > the_past

    # in chat ingore all
    if msg['sender_name'] == 'Casey Manion'
      prompt = ''
      break
    end

    msg_key = "jaconda-jira-cron-#{msg['id']}"

    # skip if already reported
    next if mc.get(msg_key)

    # messages to me
    if msg['text'].match(/^[@]*(casey|cm)/i) || msg['text'].match(/\b(casey|cm)\b/i)
      mc.set(msg_key, true, 900)
      prompt += msg['sender_name'] + ' says: ' + msg['text'] + "\n";
    end
  end

  unless prompt.empty?
    file_name = "/tmp/prompt.#{today.strftime('%Y-%m-%d.%H-%M-%S')}.txt"
    File.open(file_name, 'w') do |file|
      file.puts prompt
    end
    system("cat #{file_name} | wall");
  end

end

# Run our 'cron' dameon, suspending the current thread
DaemonKit::Cron.run
