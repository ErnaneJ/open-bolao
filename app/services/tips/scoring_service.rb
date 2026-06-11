module Tips
  class ScoringService
    def self.call(tip:, match:, pool:)
      new(tip: tip, match: match, pool: pool).call
    end

    def initialize(tip:, match:, pool:)
      @tip   = tip
      @match = match
      @pool  = pool
      @config = pool.scoring_config_with_defaults
    end

    def call
      points = calculate_points
      @tip.update!(points_earned: points)
      points
    end

    private

    attr_reader :tip, :match, :pool, :config

    def calculate_points
      return 0 if tip.home_score_tip.nil? || tip.away_score_tip.nil?
      return 0 unless match.status_finished?
      return 0 if match.home_score.nil? || match.away_score.nil?

      actual_draw = match.home_score == match.away_score
      tip_result  = tip.home_score_tip <=> tip.away_score_tip  # -1, 0, 1
      real_result = match.home_score   <=> match.away_score
      exact       = tip.home_score_tip == match.home_score &&
                    tip.away_score_tip == match.away_score

      if exact
        actual_draw ? config.fetch("correct_draw_score", 5).to_i
                    : config.fetch("correct_score", 5).to_i
      elsif tip_result == real_result && actual_draw
        config.fetch("correct_draw", 3).to_i   # acertou empate, errou o placar
      elsif tip_result == real_result
        config.fetch("correct_winner", 3).to_i  # acertou vencedor, errou o placar
      else
        0
      end
    end
  end
end
