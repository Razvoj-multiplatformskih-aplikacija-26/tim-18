-- Šema baze. Izvršava se pri prvom podizanju baze (docker-entrypoint-initdb.d).
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id            text PRIMARY KEY,
  username      text NOT NULL UNIQUE,
  -- Lozinka postoji samo kao bcrypt heš (pgcrypto crypt + gen_salt('bf')).
  password_hash text NOT NULL,
  role          text NOT NULL CHECK (role IN ('marshal', 'director'))
);

CREATE TABLE riders (
  id     text PRIMARY KEY,
  number integer NOT NULL UNIQUE,
  name   text NOT NULL
);

CREATE TABLE incidents (
  id          text PRIMARY KEY,
  reporter_id text NOT NULL REFERENCES users (id),
  rider_id    text NOT NULL REFERENCES riders (id),
  kind        text NOT NULL CHECK (kind IN
                ('crash', 'illegalOvertake', 'trackLimits', 'jumpStart', 'dangerousRiding')),
  description text NOT NULL CHECK (char_length(description) BETWEEN 10 AND 300),
  turn        integer NOT NULL CHECK (turn BETWEEN 1 AND 30),
  reported_at timestamptz NOT NULL,

  stage       text NOT NULL DEFAULT 'reported' CHECK (stage IN
                ('reported', 'confirmed', 'underReview', 'penaltyIssued', 'dismissed')),
  status_by   text REFERENCES users (id),
  status_at   timestamptz,
  penalty_kind   text CHECK (penalty_kind IN ('warning', 'longLap', 'rideThrough', 'positionDrop')),
  penalty_points integer CHECK (penalty_points BETWEEN 0 AND 3),
  dismissal_reason text,

  -- Podaci stanja moraju odgovarati stanju (isto kao sealed hijerarhija u domenu).
  CONSTRAINT status_data_matches_stage CHECK (
    (stage = 'reported'      AND status_by IS NULL AND status_at IS NULL
                             AND penalty_kind IS NULL AND penalty_points IS NULL AND dismissal_reason IS NULL)
 OR (stage IN ('confirmed', 'underReview') AND status_by IS NOT NULL AND status_at IS NOT NULL
                             AND penalty_kind IS NULL AND penalty_points IS NULL AND dismissal_reason IS NULL)
 OR (stage = 'penaltyIssued' AND status_by IS NOT NULL AND status_at IS NOT NULL
                             AND penalty_kind IS NOT NULL AND penalty_points IS NOT NULL AND dismissal_reason IS NULL)
 OR (stage = 'dismissed'     AND status_by IS NOT NULL AND status_at IS NOT NULL
                             AND dismissal_reason IS NOT NULL AND char_length(btrim(dismissal_reason)) > 0
                             AND penalty_kind IS NULL AND penalty_points IS NULL)
  )
);

CREATE INDEX incidents_rider_idx    ON incidents (rider_id);
CREATE INDEX incidents_reporter_idx ON incidents (reporter_id);
CREATE INDEX incidents_stage_idx    ON incidents (stage);
CREATE INDEX incidents_reported_idx ON incidents (reported_at DESC);
