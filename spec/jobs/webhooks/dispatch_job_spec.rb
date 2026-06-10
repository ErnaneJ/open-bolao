require "rails_helper"

RSpec.describe Webhooks::DispatchJob do
  subject(:job) { described_class.new }

  let(:pool) { create(:pool) }
  let(:endpoint) do
    create(:webhook_endpoint, owner: pool, events: ["goal"], active: true)
  end

  let(:payload) { { "match" => { "id" => 1, "home_score" => 1, "away_score" => 0 } } }

  before { endpoint } # ensure endpoint exists

  describe "#perform" do
    it "creates a WebhookDelivery" do
      stub_request(:post, endpoint.url).to_return(status: 200, body: "ok")
      expect { job.perform(event_type: "goal", payload: payload) }
        .to change(WebhookDelivery, :count).by(1)
    end

    it "sends correct HMAC signature" do
      stub = stub_request(:post, endpoint.url).to_return(status: 200, body: "ok")
      job.perform(event_type: "goal", payload: payload)

      expect(stub).to have_been_requested
      request = stub.requests.last
      signature_header = request.headers["X-Bolao-Signature"]
      expect(signature_header).to start_with("sha256=")
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
