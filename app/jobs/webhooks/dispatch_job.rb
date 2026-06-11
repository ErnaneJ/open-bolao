module Webhooks
  class DispatchJob < ApplicationJob
    queue_as :webhooks

    RETRY_DELAYS = [ 60, 300, 900 ].freeze # 1min, 5min, 15min

    def perform(event_type:, payload:, owner_ids: nil, idempotency_key: nil)
      endpoints = WebhookEndpoint.for_event(event_type)
      endpoints = endpoints.where(owner_id: owner_ids) if owner_ids.present?

      # Attach pool metadata + webhook_enabled guard when we know the pool
      pool = owner_ids.present? ? Pool.find_by(id: owner_ids) : nil
      return if pool && !pool.webhook_enabled?

      enriched = payload.merge("pool_metadata" => pool&.webhook_metadata || {})

      endpoints.find_each do |endpoint|
        deliver(endpoint, event_type, enriched, idempotency_key)
      end
    end

    private

    def deliver(endpoint, event_type, payload, idempotency_key)
      body = payload.merge(
        "event"            => event_type,
        "occurred_at"      => Time.current.iso8601,
        "idempotency_key"  => idempotency_key || SecureRandom.uuid
      ).to_json

      delivery = WebhookDelivery.create!(
        webhook_endpoint: endpoint,
        event_type:       event_type,
        payload:          payload,
        attempted_at:     Time.current,
        attempt_count:    0
      )

      begin
        conn = Faraday.new do |f|
          f.request :retry, max: 0
          f.adapter Faraday.default_adapter
        end
        signature = endpoint.sign(body)
        headers   = {
          "Content-Type"       => "application/json",
          "X-Bolao-Signature"  => "sha256=#{signature}",
          "X-Bolao-Event"      => event_type,
          "X-Bolao-Delivery"   => delivery.id.to_s
        }

        resp = if endpoint.http_method == "GET"
          conn.get(endpoint.url) do |req|
            req.headers.merge!(headers)
            req.params[:payload] = body
          end
        else
          conn.post(endpoint.url) do |req|
            req.headers.merge!(headers)
            req.body = body
          end
        end

        if resp.success?
          delivery.update!(response_code: resp.status, response_body: resp.body.truncate(2000), delivered_at: Time.current, attempt_count: 1)
          endpoint.update_columns(last_triggered_at: Time.current, last_response_code: resp.status)
        else
          schedule_retry(delivery, endpoint, event_type, payload, idempotency_key, 0)
        end
      rescue Faraday::Error => e
        delivery.update!(response_code: 0, response_body: e.message, attempt_count: 1)
        schedule_retry(delivery, endpoint, event_type, payload, idempotency_key, 0)
      end
    end

    def schedule_retry(delivery, endpoint, event_type, payload, idempotency_key, attempt_index)
      next_attempt = attempt_index + 1
      return if next_attempt >= RETRY_DELAYS.size

      delay = RETRY_DELAYS[next_attempt]
      delivery.update!(next_retry_at: delay.seconds.from_now, attempt_count: next_attempt)
      Webhooks::RetryJob.set(wait: delay.seconds).perform_later(
        delivery_id:   delivery.id,
        attempt_index: next_attempt
      )
    end
  end
end
