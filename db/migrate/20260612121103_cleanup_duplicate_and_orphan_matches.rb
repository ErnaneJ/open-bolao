class CleanupDuplicateAndOrphanMatches < ActiveRecord::Migration[8.1]
  def up
    # 1. Matches with no external IDs, no tips, not linked to any pool
    execute <<~SQL
      DELETE FROM matches
      WHERE external_tsdb_id IS NULL
        AND external_id IS NULL
        AND id NOT IN (SELECT DISTINCT match_id FROM tips WHERE match_id IS NOT NULL)
        AND id NOT IN (SELECT match_id FROM pools WHERE match_id IS NOT NULL)
        AND id NOT IN (SELECT match_id FROM pool_matches WHERE match_id IS NOT NULL)
    SQL

    # 2. Duplicate external_tsdb_id — keep the lowest id, skip rows referenced by tips/pools
    execute <<~SQL
      DELETE FROM matches
      WHERE external_tsdb_id IS NOT NULL
        AND id NOT IN (
          SELECT MIN(id) FROM matches
          WHERE external_tsdb_id IS NOT NULL
          GROUP BY external_tsdb_id
        )
        AND id NOT IN (SELECT DISTINCT match_id FROM tips WHERE match_id IS NOT NULL)
        AND id NOT IN (SELECT match_id FROM pools WHERE match_id IS NOT NULL)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
