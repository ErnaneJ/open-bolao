class Stage < ApplicationRecord
  STAGE_TYPES = %i[group round_of_32 round_of_16 quarterfinal semifinal third_place final].freeze

  enum :stage_type, { group: 0, round_of_32: 1, round_of_16: 2, quarterfinal: 3,
                      semifinal: 4, third_place: 5, final: 6 }

  belongs_to :tournament
  has_many :matches, dependent: :nullify

  validates :name, presence: true
  validates :stage_type, presence: true
  validates :order_position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:order_position) }

  def knockout?
    !group?
  end
end
