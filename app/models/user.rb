class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
         :validatable

  enum :role, { user: 0, admin: 1, super_admin: 2 }, prefix: true
  enum :locale, { pt_br: 0, en: 1 }

  has_many :administered_pools, class_name: "Pool", foreign_key: :admin_id, dependent: :destroy
  has_many :pool_participants, dependent: :destroy
  has_many :pools, through: :pool_participants
  has_many :tips, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :webhook_endpoints, as: :owner, dependent: :destroy
  has_many :created_tournaments, class_name: "Tournament", foreign_key: :created_by_id
  belongs_to :invited_by, class_name: "User", optional: true

  has_one_attached :avatar

  validates :name, presence: true, length: { maximum: 100 }

  scope :admins, -> { where(role: :admin) }
  scope :super_admins, -> { where(role: :super_admin) }
  scope :by_name, -> { order(:name) }

  LOCALE_MAP = { "pt_br" => :"pt-BR", "en" => :en }.freeze

  def i18n_locale
    LOCALE_MAP[locale] || I18n.default_locale
  end

  def display_name
    name.presence || email.split("@").first
  end
end
