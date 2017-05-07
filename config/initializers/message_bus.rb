MessageBus.user_id_lookup do |env|
  req = Rack::Request.new(env)
  req.session['message_bus_token']
end
