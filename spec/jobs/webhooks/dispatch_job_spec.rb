require "rails_helper"

RSpec.describe Webhooks::DispatchJob do
  include WebMock::API

  subject(:job) { described_class.new }

  let!(:pool) { create(:pool) }
  let!(:endpoint) { create(:webhook_endpoint, owner: pool, events: ["goal"], active: true) }
  let(:payload) { { "match" => { "id" => 1, "home_score" => 1, "away_score" => 0 } } }

  describe "#perform" do
    it "creates a WebhookDelivery" do
      stub_request(:post, endpoint.url).to_return(status: 200, body: "ok")
      expect { job.perform(event_type: "goal", payload: payload) }
        .to change(WebhookDelivery, :count).by(1)
    end

    it "sends HMAC signature header" do
      stub_request(:post, endpoint.url)
        .with { |req| req.headers["X-Bolao-Signature"]&.start_with?("sha256=") }
        .to_return(status: 200, body: "ok")

      job.perform(event_type: "goal", payload: payload)

      expect(a_request(:post, endpoint.url)
        .with { |req| req.headers["X-Bolao-Signature"]&.start_with?("sha256=") })
        .to have_been_made
    end

    it "marks delivery as delivered on success" do
      stub_request(:post, endpoint.url).to_return(status: 200, body: "ok")
      job.perform(event_type: "goal", payload: payload)
      expect(WebhookDelivery.last.delivered_at).to be_present
    end

    context "when endpoint returns 500" do
      it "schedules a retry" do
        stub_request(:post, endpoint.url).to_return(status: 500, body: "error")
        expect { job.perform(event_type: "goal", payload: payload) }
          .to have_enqueued_job(Webhooks::RetryJob)
      end
    end

    context "when endpoint URL is unreachable" do
      it "creates a delivery with attempt_count 1" do
        stub_request(:post, endpoint.url).to_raise(Faraday::ConnectionFailed.new("connection refused"))
        job.perform(event_type: "goal", payload: payload)
        expect(WebhookDelivery.last.attempt_count).to eq(1)
      end
    end
  end
end
