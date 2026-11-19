-- Početni podaci (isti kao u lažnoj implementaciji iz KT1).
-- Demo lozinka za sve naloge: demo1234 (u bazi samo kao bcrypt heš).

INSERT INTO users (id, username, password_hash, role) VALUES
  ('u-marshal-1',  'marshal1',  crypt('demo1234', gen_salt('bf', 10)), 'marshal'),
  ('u-marshal-2',  'marshal2',  crypt('demo1234', gen_salt('bf', 10)), 'marshal'),
  ('u-director-1', 'director1', crypt('demo1234', gen_salt('bf', 10)), 'director');

INSERT INTO riders (id, number, name) VALUES
  ('r-12', 12, 'Luka Vidić'),
  ('r-27', 27, 'Marko Ilić'),
  ('r-44', 44, 'Stefan Marić'),
  ('r-63', 63, 'Nikola Savić'),
  ('r-90', 90, 'Andrej Lukić');

-- Početak trke: 2026-10-18 14:00 UTC.
INSERT INTO incidents
  (id, reporter_id, rider_id, kind, description, turn, reported_at,
   stage, status_by, status_at, penalty_kind, penalty_points, dismissal_reason)
VALUES
  ('i-01','u-marshal-1','r-12','crash','Vozač je pao u krivini 3, motor je ostao na stazi.',3,
     timestamptz '2026-10-18 14:00+00' + interval '5 minutes','reported',NULL,NULL,NULL,NULL,NULL),
  ('i-02','u-marshal-1','r-27','illegalOvertake','Preticanje u krivini 7 uz kontakt sa vozačem ispred.',7,
     timestamptz '2026-10-18 14:00+00' + interval '12 minutes','reported',NULL,NULL,NULL,NULL,NULL),
  ('i-03','u-marshal-1','r-44','trackLimits','Vozač je sa obe strane motora izašao van linije staze.',11,
     timestamptz '2026-10-18 14:00+00' + interval '20 minutes','reported',NULL,NULL,NULL,NULL,NULL),
  ('i-04','u-marshal-1','r-12','dangerousRiding','Naglo menjanje putanje na izlazu iz krivine 5.',5,
     timestamptz '2026-10-18 14:00+00' + interval '25 minutes','confirmed','u-director-1',
     timestamptz '2026-10-18 14:00+00' + interval '27 minutes',NULL,NULL,NULL),
  ('i-05','u-marshal-1','r-27','trackLimits','Ponovljen prelazak bele linije u krivini 9.',9,
     timestamptz '2026-10-18 14:00+00' + interval '33 minutes','confirmed','u-director-1',
     timestamptz '2026-10-18 14:00+00' + interval '35 minutes',NULL,NULL,NULL),
  ('i-06','u-marshal-1','r-63','jumpStart','Vozač je krenuo pre nego što se ugasilo crveno svetlo.',1,
     timestamptz '2026-10-18 14:00+00' + interval '2 minutes','underReview','u-director-1',
     timestamptz '2026-10-18 14:00+00' + interval '6 minutes',NULL,NULL,NULL),
  ('i-07','u-marshal-1','r-44','illegalOvertake','Preticanje pod žutom zastavom u krivini 14.',14,
     timestamptz '2026-10-18 14:00+00' + interval '41 minutes','underReview','u-director-1',
     timestamptz '2026-10-18 14:00+00' + interval '44 minutes',NULL,NULL,NULL),
  ('i-08','u-marshal-1','r-63','crash','Pad posle kontakta sa vozačem pored, bez povreda.',6,
     timestamptz '2026-10-18 14:00+00' + interval '18 minutes','penaltyIssued','u-director-1',
     timestamptz '2026-10-18 14:00+00' + interval '30 minutes','warning',1,NULL),
  ('i-09','u-marshal-1','r-12','trackLimits','Dva prelaska linije u istom krugu u krivini 8.',8,
     timestamptz '2026-10-18 14:00+00' + interval '48 minutes','penaltyIssued','u-director-1',
     timestamptz '2026-10-18 14:00+00' + interval '55 minutes','warning',1,NULL),
  ('i-10','u-marshal-1','r-27','dangerousRiding','Opasna vožnja u gužvi odmah posle starta, kontakt sa dva vozača.',2,
     timestamptz '2026-10-18 14:00+00' + interval '8 minutes','penaltyIssued','u-director-1',
     timestamptz '2026-10-18 14:00+00' + interval '15 minutes','rideThrough',3,NULL),
  ('i-11','u-marshal-1','r-44','trackLimits','Kratak izlazak van staze bez ostvarene prednosti.',4,
     timestamptz '2026-10-18 14:00+00' + interval '52 minutes','dismissed','u-director-1',
     timestamptz '2026-10-18 14:00+00' + interval '58 minutes',NULL,NULL,'Prednost nije ostvarena.'),
  ('i-12','u-marshal-1','r-63','crash','Prijava pada koji je već obrađen kroz drugu prijavu.',10,
     timestamptz '2026-10-18 14:00+00' + interval '36 minutes','dismissed','u-director-1',
     timestamptz '2026-10-18 14:00+00' + interval '40 minutes',NULL,NULL,'Duplikat druge prijave.'),
  ('i-13','u-marshal-2','r-12','trackLimits','Vozač je prešao liniju staze u krivini 8, drugi put u krugu.',8,
     timestamptz '2026-10-18 14:00+00' + interval '50 minutes','reported',NULL,NULL,NULL,NULL,NULL),
  ('i-14','u-marshal-2','r-90','crash','Pad u krivini 12, vozač je odmah ustao.',12,
     timestamptz '2026-10-18 14:00+00' + interval '60 minutes','reported',NULL,NULL,NULL,NULL,NULL),
  ('i-15','u-marshal-2','r-90','illegalOvertake','Preticanje izvan staze u krivini 13.',13,
     timestamptz '2026-10-18 14:00+00' + interval '62 minutes','reported',NULL,NULL,NULL,NULL,NULL);
