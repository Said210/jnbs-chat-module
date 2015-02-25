class MessagesController < ApplicationController
  include ActionController::Live
  skip_before_filter :verify_authenticity_token
  
  def index
  	@message = Message.new
    @listen_at = params[:id]
  end

  def history
  	response.headers['Access-Control-Allow-Origin'] = "*"
  	render json: Message.where("(messages.sent_by = ? AND messages.sent_to = ?) OR (messages.sent_by = ? AND messages.sent_to = ?)", current_user.id,params[:id],params[:id],current_user.id).take(15)
  end


  def live
  	response.headers['Access-Control-Allow-Origin'] = "*"
  	response.headers['Content-Type'] = 'text/event-stream'
  	sse = SSE.new(response.stream)
    #decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    #decipher.decrypt
    #decipher.key = "huyjgfvcdrjhg314"
    #decipher.iv = "o\xEA\xC0\x999\x0F\x0E!]\xF3 bB}\x9Ec"
    #id = decipher.update(params[:id]) + decipher.final
    id = params[:id]
    puts "id => #{id}"
    me = params[:me]
    puts "me => #{me}"
    #me = decipher.update(params[:me]) + decipher.final

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
    #decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    #decipher.decrypt
    #decipher.key = "huyjgfvcdrjhg314"
    #decipher.iv = params[:iv]
    #id = decipher.update(params[:id]) + decipher.final
    id = params[:id]
    sse = SSE.new(response.stream)
  begin
    Message.on_change do |data|
      message = Message.find(data)
      if( sent_to_me(message, id) )
        puts "monitor acceped"
        message = message.to_json
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