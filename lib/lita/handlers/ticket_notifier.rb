module Lita
  module Handlers
    class TicketNotifier < Handler
      http.post "/ticket_notification", :ticket_notification

      def ticket_notification(request, response)
        "i got notified!"
      end
    end

    Lita.register_handler(TicketNotifier)
  end
end
