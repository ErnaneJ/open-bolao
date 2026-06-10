module Tips
  class ScoringService
    def self.call(tip:, match:, pool:)
      new(tip: tip, match: match, pool: pool).call
    end

    def initialize(tip:, match:, pool:)
      @tip = tip
      @match = match
      @pool = pool
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
      return no_tip_penalty if tip_missing?
      return 0 unless match.status_finished?

      base = base_points
      base = apply_stage_multiplier(base) if pool.tournament_pool?
      base
    end

    def tip_missing?
      tip.home_score_tip.nil? || tip.away_score_tip.nil?
    end

    def no_tip_penalty
      config.fetch("no_tip_penalty", 0).to_i
    end

    def base_points
      points = 0

      if exact_score?
        points += winner_points + config.fetch("exact_score", 5).to_i
      elsif correct_winner?
        points += winner_points
        points += config.fetch("correct_goal_difference", 1).to_i if correct_goal_difference?
      end

      points += config.fetch("correct_total_goals", 1).to_i if correct_total_goals? && !exact_score?

      points
    end

    def winner_points
      result = match_result(match.home_score, match.away_score)
      if result == :draw
        config.fetch("correct_draw", 3).to_i
      else
        config.fetch("correct_winner", 3).to_i
      end
    end

    def exact_score?
      tip.home_score_tip == match.home_score &&
        tip.away_score_tip == match.away_score
    end

    def correct_winner?
      match_result(tip.home_score_tip, tip.away_score_tip) ==
        match_result(match.home_score, match.away_score)
    end

    def correct_goal_difference?
      (tip.home_score_tip - tip.away_score_tip) ==
        (match.home_score - match.away_score)
    end

    def correct_total_goals?
      (tip.home_score_tip + tip.away_score_tip) ==
        (match.home_score + match.away_score)
    end

    def match_result(home, away)
      return :home if home > away
      return :away if home < away
      :draw
    end

    def apply_stage_multiplier(points)
      return points unless match.stage.present?

      multiplier = case match.stage.stage_type
                   when "final"        then config.fetch("final_multiplier", 3.0).to_f
                   when "group"        then 1.0
                   else config.fetch("knockout_multiplier", 2.0).to_f
                   end

      (points * multiplier).to_i
    end
  end
end
