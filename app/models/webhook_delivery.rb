class WebhookDelivery < ApplicationRecord
  belongs_to :webhook_endpoint

  validates :event_type, presence: true

  scope :pending_retry, -> { where("next_retry_at <= ? AND delivered_at IS NULL", Time.current) }
  scope :recent, -> { order(attempted_at: :desc) }

  def delivered?
    delivered_at.present?
  end

  def failed?
    response_code.nil? || response_code >= 400
  end
end
