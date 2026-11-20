-- Long lap kazna koju sistem dodeljuje kad vozač pređe prag kaznenih poena.
-- Primarni ključ je poslednja linija odbrane: vozač je može dobiti najviše jednom,
-- čak i kad dva poziva stignu istovremeno.
CREATE TABLE rider_long_laps (
  rider_id    text PRIMARY KEY REFERENCES riders (id),
  incident_id text NOT NULL REFERENCES incidents (id),
  awarded_at  timestamptz NOT NULL DEFAULT now()
);
