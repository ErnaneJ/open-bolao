module Webhooks
  class RetryJob < ApplicationJob
    queue_as :webhooks

    def perform(delivery_id:, attempt_index:)
      delivery = WebhookDelivery.find_by(id: delivery_id)
      return if delivery.nil? || delivery.delivered?

      endpoint = delivery.webhook_endpoint
      return unless endpoint.active?

      body = delivery.payload.merge(
        "event" => delivery.event_type,
        "occurred_at" => Time.current.iso8601
      ).to_json

      signature = endpoint.sign(body)

      begin
        conn = Faraday.new
        resp = conn.post(endpoint.url) do |req|
          req.headers["Content-Type"] = "application/json"
          req.headers["X-Bolao-Signature"] = "sha256=#{signature}"
          req.body = body
        end

        if resp.success?
          delivery.update!(
            response_code: resp.status,
            response_body: resp.body.truncate(2000),
            delivered_at: Time.current,
            attempt_count: attempt_index + 1
          )
        else
          schedule_next_retry(delivery, endpoint, attempt_index)
        end
      rescue Faraday::Error => e
        delivery.update!(response_body: e.message, attempt_count: attempt_index + 1)
        schedule_next_retry(delivery, endpoint, attempt_index)
      end
    end

    private

    RETRY_DELAYS = Webhooks::DispatchJob::RETRY_DELAYS

    def schedule_next_retry(delivery, endpoint, current_index)
      next_index = current_index + 1
      return if next_index >= RETRY_DELAYS.size

      delay = RETRY_DELAYS[next_index]
      delivery.update!(next_retry_at: delay.seconds.from_now)
      Webhooks::RetryJob.set(wait: delay.seconds).perform_later(
        delivery_id: delivery.id,
        attempt_index: next_index
      )
    end
  end
end
