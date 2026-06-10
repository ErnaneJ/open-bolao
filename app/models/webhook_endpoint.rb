class WebhookEndpoint < ApplicationRecord
  belongs_to :owner, polymorphic: true
  has_many :webhook_deliveries, dependent: :destroy

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :events, presence: true

  scope :active, -> { where(active: true) }
  scope :for_event, ->(event) { active.where("events @> ?", [event].to_json) }

  before_create :generate_secret_token

  def sign(payload)
    OpenSSL::HMAC.hexdigest("SHA256", secret_token, payload)
  end

  private

  def generate_secret_token
    self.secret_token ||= SecureRandom.hex(32)
  end
end
