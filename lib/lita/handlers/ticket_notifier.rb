module Lita
  module Handlers
    class TicketNotifier < Handler
      attr_accessor :ticket_json, :ticket_object

      def self.default_config(config)
        config.tags_watching = ''
      end

      http.post "/ticket_notification", :ticket_notification

      route(/ticket notify start/i, :add_ticket_notification, command: true,
        help: { "ticket notify start" => "Lita will notify you of Lighthouse tickets." }
      )

      route(/ticket notify stop/i, :remove_ticket_notification, command: true,
        help: { "ticket notify stop" => "Lita will stop notifying you of Lighthouse tickets." }
      )

      def ticket_notification(request, response)
        self.ticket_json ||= JSON.parse(request.body.read)
        user_names.each do |user_name|
          send_message_to_user(user_name, ticket_message) if notify?
        end
      end

      def add_ticket_notification(response)
        response.reply_privately "You're already on the list." and return if user_names.include? response.user.name

        redis.lpush("ticket_users", response.user.name)
        response.reply_privately "You will now get notified of ticket updates."
      end

      def remove_ticket_notification(response)
        response.reply_privately "You weren't on the list." and return unless user_names.include? response.user.name

        redis.lrem("ticket_users", 0, response.user.name)
        response.reply_privately "You will no longer receive ticket update notifications."
      end

    private

      def tags_watching
        Lita.config.handlers.ticket_notifier.tags_watching
      end

      def watching_all_tags?
        tags_watching.empty?
      end

      def watching_tag?
        (ticket.tag.split & tags_watching.split).any?
      end

      def notify?
        watching_all_tags? || watching_tag?
      end

      def send_message_to_user(user_name, message)
        robot.send_message(source_from_name(user_name), message)
      end

      def source_from_name(name)
        Lita::Source.new({ user: Lita::User.find_by_name(name) })
      end

      def user_names
        redis.lrange("ticket_users", 0, -1)
      end

      def ticket
        self.ticket_object ||= OpenStruct.new(hash_attributes)
      end

      def hash_attributes
        # listing this all out to document the attributes
        h = ticket_json['version']
        hash_attributes = {
          assigned_user_id: h['assigned_user_id'],
          assigned_user_name: h['assigned_user_name'],
          attachments_count: h['attachments_count'],
          body: h['body'],
          body_html: h['body_html'],
          closed: h['closed'],
          created_at: h['created_at'],
          creator_id: h['creator_id'],
          creator_name: h['creator_name'],
          diffable_attributes_hash: h['diffable_attributes'],
          importance: h['importance'],
          importance_name: h['importance_name'],
          milestone_id: h['milestone_id'],
          milestone_order: h['milestone_order'],
          number: h['number'],
          permalink: h['permalink'],
          priority: h['priority'],
          project_id: h['project_id'],
          spam: h['spam'],
          state: h['state'],
          tag: h['tag'],
          title: h['title'],
          updated_at: h['updated_at'],
          url: h['url'],
          user_id: h['user_id'],
          user_name: h['user_name'],
          version: h['version'],
          watchers_ids: h['watchers_ids']
        }
      end

      def ticket_message
        "Ticket: #{ticket.title}\nState:#{ticket.state}\nImportance:#{ticket.importance_name}\nTags:#{ticket.tag}\n#{ticket.url}"
      end
    end

    Lita.register_handler(TicketNotifier)
  end
end

