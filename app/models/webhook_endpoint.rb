class WebhookEndpoint < ApplicationRecord
  ALL_EVENTS = {
    "match.finished"       => "Jogo encerrado",
    "match.live"           => "Jogo ao vivo",
    "match.goal"           => "Gol marcado",
    "pool.daily_matches"   => "Jogos do dia (8h)",
    "pool.ranking_updated" => "Ranking atualizado",
    "pool.finished"        => "Bolão encerrado",
    "tip.scored"           => "Palpite pontuado"
  }.freeze

  belongs_to :owner, polymorphic: true
  has_many :webhook_deliveries, dependent: :destroy

  HTTP_METHODS = %w[POST GET].freeze

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :events, presence: true
  validates :http_method, inclusion: { in: HTTP_METHODS }

  scope :active, -> { where(active: true) }
  scope :for_event, ->(event) { active.where("events @> ?", [ event ].to_json) }

  before_create :generate_secret_token

  def sign(payload)
    OpenSSL::HMAC.hexdigest("SHA256", secret_token, payload)
  end

  private

  def generate_secret_token
    self.secret_token ||= SecureRandom.hex(32)
  end
end
