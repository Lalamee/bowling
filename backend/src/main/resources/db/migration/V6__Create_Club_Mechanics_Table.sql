CREATE TABLE IF NOT EXISTS club_mechanics (
    mechanic_profile_id BIGINT NOT NULL REFERENCES mechanic_profiles(profile_id) ON DELETE CASCADE,
    club_id BIGINT NOT NULL REFERENCES bowling_clubs(club_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (mechanic_profile_id, club_id)
);

CREATE INDEX IF NOT EXISTS idx_club_mechanics_profile_id
    ON club_mechanics(mechanic_profile_id);

CREATE INDEX IF NOT EXISTS idx_club_mechanics_club_id
    ON club_mechanics(club_id);
