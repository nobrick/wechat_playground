# Provides conveniences for publishing messages via +MessageBus+.
#
# Explicitly set +message_bus_token+ before including this module.
module MessageBusHelper

  extend ActiveSupport::Concern

  def publish(status, params = {})
    payload = {status: status}.merge(params).to_json
    logger.info("[Token]  #{message_bus_token}\n[Payload]  #{payload}")
    MessageBus.publish("/channel", payload, user_ids: [message_bus_token])
  end
end
