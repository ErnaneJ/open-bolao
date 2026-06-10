class Pool < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  SCORING_DEFAULTS = {
    "correct_winner" => 3,
    "correct_draw" => 3,
    "exact_score" => 5,
    "correct_goal_difference" => 1,
    "correct_total_goals" => 1,
    "knockout_multiplier" => 2.0,
    "final_multiplier" => 3.0,
    "no_tip_penalty" => 0
  }.freeze

  SPECIAL_BETS_DEFAULTS = {
    "champion" => { "enabled" => true, "points" => 15 },
    "top_scorer" => { "enabled" => true, "points" => 10 },
    "golden_glove" => { "enabled" => false, "points" => 5 },
    "finalist_home" => { "enabled" => true, "points" => 8 },
    "finalist_away" => { "enabled" => true, "points" => 8 },
    "total_goals" => { "enabled" => false, "points" => 10 }
  }.freeze

  enum :pool_scope, { tournament: 0, single_match: 1 }, prefix: true
  enum :status, { draft: 0, open: 1, locked: 2, finished: 3 }, prefix: true
  enum :visibility, { public_pool: 0, private_pool: 1, invite_only: 2 }

  belongs_to :admin, class_name: "User"
  belongs_to :tournament, optional: true

  has_many :pool_matches, dependent: :destroy
  has_many :selected_matches, through: :pool_matches, source: :match
  belongs_to :match, optional: true
  has_many :pool_participants, dependent: :destroy
  has_many :participants, through: :pool_participants, source: :user
  has_many :tips, dependent: :destroy
  has_many :special_bets, dependent: :destroy
  has_many :webhook_endpoints, as: :owner, dependent: :destroy

  validates :name, presence: true, length: { maximum: 200 }
  validates :pool_scope, presence: true
  validates :status, presence: true
  validates :visibility, presence: true
  validate :scope_reference_consistency

  before_validation :set_defaults
  before_create :generate_invite_code

  scope :open_pools, -> { where(status: :open) }
  scope :public_or_invite, -> { where(visibility: [:public_pool, :invite_only]) }

  def scoring_config_with_defaults
    SCORING_DEFAULTS.merge(scoring_config || {})
  end

  def special_bets_config_with_defaults
    SPECIAL_BETS_DEFAULTS.merge(special_bets_config || {})
  end

  def tournament_pool?
    pool_scope_tournament?
  end

  def single_match_pool?
    pool_scope_single_match?
  end

  # Returns the match set for this pool:
  # 1. Explicit pool_matches if any have been defined
  # 2. All tournament matches (fallback for existing tournament pools)
  # 3. The single linked match
  def active_matches
    if pool_matches.loaded? ? pool_matches.any? : pool_matches.exists?
      selected_matches.includes(:home_team, :away_team, :stage).order(:scheduled_at)
    elsif pool_scope_tournament? && tournament.present?
      tournament.matches.includes(:home_team, :away_team, :stage).order(:scheduled_at)
    elsif pool_scope_single_match? && match_id.present?
      Match.where(id: match_id).includes(:home_team, :away_team)
    else
      Match.none
    end
  end

  # Returns true when the competition has effectively started (any match live/finished)
  def competition_started?
    if pool_scope_tournament? && tournament.present?
      tournament.matches.where(status: [ :live, :finished ]).exists?
    elsif pool_scope_single_match? && match.present?
      match.status_live? || match.status_finished?
    else
      false
    end
  end

  # Returns true when tips should no longer be accepted for this match
  def tips_locked_for?(match)
    return true if status_locked? || status_finished?
    return true if match.status_live? || match.status_finished? || match.status_cancelled?
    return false unless match.scheduled_at.present?
    Time.current >= match.scheduled_at - (lock_before_minutes || 0).minutes
  end

  # Human-readable deadline for a match's tips
  def tip_deadline_for(match)
    return nil unless match.scheduled_at.present?
    match.scheduled_at - (lock_before_minutes || 0).minutes
  end

  private

  def set_defaults
    self.scoring_config = scoring_config_with_defaults if scoring_config.blank?
    self.special_bets_config = {} if pool_scope_single_match?
  end

  def generate_invite_code
    self.invite_code ||= SecureRandom.alphanumeric(8).upcase
  end

  def scope_reference_consistency
    if pool_scope_tournament?
      errors.add(:tournament, :blank) if tournament_id.blank?
      errors.add(:match, :must_be_blank) if match_id.present?
    elsif pool_scope_single_match?
      errors.add(:match, :blank) if match_id.blank?
      errors.add(:tournament, :must_be_blank) if tournament_id.present?
    end
  end
end
