module Notifications
  class BroadcastJob < ApplicationJob
    queue_as :default

    def perform(user_id:, kind:, title:, body: nil, notifiable_type: nil, notifiable_id: nil)
      notification = Notification.create!(
        user_id: user_id,
        kind: kind,
        title: title,
        body: body,
        notifiable_type: notifiable_type,
        notifiable_id: notifiable_id
      )

      ActionCable.server.broadcast(
        "notifications_user_#{user_id}",
        {
          event: "new_notification",
          id: notification.id,
          kind: kind,
          title: title,
          body: body
        }
      )
    end
  end
end
