class MessagesController < ApplicationController
  include ActionController::Live
  skip_before_filter :verify_authenticity_token
  require 'open-uri'
  require 'json'
  
  SERVER = "http://localhost:3000/"

  def index
    @message = Message.new
 	@listen_at = params[:id]
  end

  def has_talked_with
    messages = Message.where(sent_to: 1).all
    added, sent_by = [], []
    puts SERVER
    messages.each do |_m|
      if !added.include? _m.sent_by
        added.push _m.sent_by
      end
    end
    
    added.each do |element|
      template = {username: "", id: ""}
      begin
      	_sent_by =  JSON.parse(open(SERVER + "api/public/u/" + element.to_s).read)
      	template = {username: _sent_by['username'], id: _sent_by['id']}
      rescue
      	template = {username: "unknown", id: element.to_s}
      ensure
      	sent_by.push template
      end
      
    end

    render json: sent_by.to_json
  end

  def history
    response.headers['Access-Control-Allow-Origin'] = "*"
    
    indices, fetched_messages, usernames = [], [], []
    messages = Message.where("(messages.sent_by = ? AND messages.sent_to = ?) OR (messages.sent_by = ? AND messages.sent_to = ?)", params[:me],params[:id],params[:id],params[:me]).take(15)

    messages.each do |_m|
    	template = {username: "", message: ""}
    	
    	if !indices.include? _m.sent_by

    		begin
	    		_sent_by =  JSON.parse(open(SERVER + "api/public/u/" + _m.sent_by.to_s).read)
	    		template[:username] = _sent_by['username']
	    	rescue
	    		template[:username] = "unknown"
	    	ensure
	    		template[:message] = _m.message

	    		indices.push _m.sent_by
	    		usernames.push template[:username]

	    		fetched_messages.push template
	    	end

    	else
    		template[:message] = _m.message
    		template[:username] = usernames[indices.index(_m.sent_by)]
    		fetched_messages.push template
    	end
    end

    render json: fetched_messages
  end


  def live
    response.headers['Access-Control-Allow-Origin'] = "*"
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream)
  id = params[:id]
  puts "id => #{id}"
  me = params[:me]
  puts "me => #{me}"

  begin
    puts "LOAD"
    Message.on_change do |data|
      
      message = Message.find(data)

      if( sent_by_me_to(message, id, me) || sent_to_me_by(message, id, me) )
        message = message.to_json
        puts "sep => id: #{id}  me: #{me}"
        sse.write(message)
        else
        puts "Nop"
        end

    end
  rescue IOError
  ensure
      sse.close
  end
    render nothing: true
  end

  def profile_chat_monitor
    response.headers['Access-Control-Allow-Origin'] = "*"
  response.headers['Content-Type'] = 'text/event-stream'
  id = params[:id]
  sse = SSE.new(response.stream)
  begin
  Message.on_change do |data|
    message = Message.find(data)
    template = {sent_by: "", sent_to: "", message: "", role: "", sent_by_username: "", sent_to_username: ""}
    if( sent_to_me(message, id) )
      _sent_by =  JSON.parse(open(SERVER + "/api/public/u/" + message.sent_by.to_s).read)
    _sent_to =  JSON.parse(open(SERVER + "/api/public/u/" + message.sent_to.to_s).read)
    template[:sent_by] = message.sent_by.to_s
    template[:sent_to] = message.sent_to.to_s
    template[:role] = _sent_by['role']
    template[:message] = message.message
    template[:sent_by_username] = _sent_by['username']
    template[:sent_to_username] = _sent_to['username']
    puts "monitor acceped"
    message = template.to_json
    sse.write(message)
    else
    puts "monitor denied"
    end

  end
  rescue IOError
  ensure
    sse.close
  end
  render nothing: true
  end

  def create
    response.headers['Access-Control-Allow-Origin'] = "*"
    m = Message.new
    m.sent_to = params[:sent_to]
    m.sent_by = params[:sent_by]
    m.message = params[:message]
    if m.save
      render text: "Done"
    else
      render text: "failed"
    end
  end

  def sent_by_me_to (message, ide, me)
    #puts "1 s_by = me? => #{message.sent_by.to_i == me.to_i}"
    #puts "2 s_to = smbd? => #{message.sent_to.to_i == ide.to_i}"
  if (message.sent_by.to_i == me.to_i && message.sent_to.to_i == ide.to_i)
    return true
  else
    return false
  end
  end

  def sent_to_me_by (message, ide, me)
    #puts "1.1 s_by = smbd? => #{message.sent_by.to_i == ide.to_i}"
    #puts "2.2 s_to = me? => #{message.sent_to.to_i == me.to_i}"
  if (message.sent_by.to_i == ide.to_i && message.sent_to.to_i == me.to_i)
    return true
  else
    return false
  end
  end

  def sent_to_me (message, me)
    puts "monitor #{message.sent_to} == #{me} => #{message.sent_to.to_i == me.to_i}"
  if message.sent_to.to_i == me.to_i
    return true
  else
    return false
  end
  end

end