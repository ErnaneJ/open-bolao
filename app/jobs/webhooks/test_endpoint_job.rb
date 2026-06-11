module Webhooks
  class TestEndpointJob < ApplicationJob
    queue_as :webhooks

    SAMPLE_PAYLOADS = {
      "match.finished"       => { "match" => { "id" => 0, "home_team" => "Brasil", "away_team" => "Argentina", "home_score" => 2, "away_score" => 1 } },
      "match.live"           => { "match" => { "id" => 0, "home_team" => "Brasil", "away_team" => "Argentina", "home_score" => 1, "away_score" => 0 } },
      "match.goal"           => { "match" => { "id" => 0, "home_team" => "Brasil", "away_team" => "Argentina", "home_score" => 1, "away_score" => 0 }, "goals_count" => 1 },
      "pool.ranking_updated" => { "pool" => { "id" => 0, "name" => "Bolão de Teste" }, "leader" => "Usuário Teste" },
      "pool.daily_matches"   => {
        "pool"        => { "id" => 0, "name" => "Bolão de Teste", "invite_code" => "ABCD1234", "participants_count" => 10 },
        "matches"     => [ { "home_team" => "Brasil", "away_team" => "Argentina", "scheduled_at" => "2026-06-15T21:00:00Z" } ],
        "match_count" => 1,
        "date"        => Date.current.iso8601
      },
      "pool.finished"        => { "pool" => { "id" => 0, "name" => "Bolão de Teste" } },
      "tip.scored"           => { "tip" => { "user" => "Usuário Teste", "home_score_tip" => 2, "away_score_tip" => 1, "points_earned" => 5 } }
    }.freeze

    def perform(endpoint_id, event_type = nil)
      endpoint = WebhookEndpoint.find_by(id: endpoint_id)
      return unless endpoint

      pool = endpoint.owner if endpoint.owner.is_a?(Pool)
      event_type ||= endpoint.events&.first || "test"
      data = SAMPLE_PAYLOADS.fetch(event_type, { "message" => "Teste do Open Bolão" })

      body = data.merge(
        "event"            => event_type,
        "test"             => true,
        "occurred_at"      => Time.current.iso8601,
        "idempotency_key"  => SecureRandom.uuid,
        "pool_metadata"    => pool&.webhook_metadata || {}
      ).to_json

      delivery = WebhookDelivery.create!(
        webhook_endpoint: endpoint,
        event_type:       event_type,
        payload:          data.merge("test" => true),
        attempted_at:     Time.current,
        attempt_count:    1
      )

      headers = {
        "Content-Type"      => "application/json",
        "X-Bolao-Signature" => "sha256=#{endpoint.sign(body)}",
        "X-Bolao-Event"     => event_type,
        "X-Bolao-Delivery"  => delivery.id.to_s
      }

      conn = Faraday.new { |f| f.adapter Faraday.default_adapter }

      resp = if endpoint.http_method == "GET"
        conn.get(endpoint.url) { |req| req.headers.merge!(headers); req.params[:payload] = body }
      else
        conn.post(endpoint.url) { |req| req.headers.merge!(headers); req.body = body }
      end

      delivery.update!(
        response_code: resp.status,
        response_body: resp.body.to_s.truncate(2000),
        delivered_at:  resp.success? ? Time.current : nil
      )
      endpoint.update_columns(last_triggered_at: Time.current, last_response_code: resp.status)
    rescue => e
      Rails.logger.error("TestEndpointJob #{endpoint_id}: #{e.message}")
    end
  end
end
