class Message < ActiveRecord::Base
	after_create :notify_message_sent
	
	def basic_info_json
	  JSON.generate({sent_by: sent_by, sent_to: sent_to, message: message, timestamp: created_at})
	end

	def notify_message_sent
		Message.connection.execute "NOTIFY messages, '#{self.id}'"
	end

	class << self
	  def on_change
	    Message.connection.execute "LISTEN messages"
	    loop do
	      Message.connection.raw_connection.wait_for_notify do |event, pid, message|
	        yield message
	      end
	    end
	  ensure
	    Message.connection.execute "UNLISTEN messages, '#{self.id}'"
	  end
	end
end
