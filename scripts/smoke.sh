#!/usr/bin/env bash
# Poziva server mimo aplikacija (curl) i proverava da pravila važe i tamo.
# Server mora da radi (docker compose up). Pokretanje: ./scripts/smoke.sh
BASE=${BASE:-http://localhost:8080}
FAILED=0

call() { # metoda putanja token aplikacija telo
  local args=(-s -X "$1" "$BASE$2" -H 'content-type: application/json' -w $'\n%{http_code}')
  [ -n "$3" ] && args+=(-H "authorization: Bearer $3")
  [ -n "$4" ] && args+=(-H "x-client-app: $4")
  [ -n "$5" ] && args+=(-d "$5")
  curl "${args[@]}"
}
code() { echo "${1##*$'\n'}"; }
body() { echo "${1%$'\n'*}"; }

expect() { # opis očekivani-status izlaz [tekst-u-odgovoru]
  local actual; actual=$(code "$3")
  if [ "$actual" = "$2" ] && { [ -z "$4" ] || body "$3" | grep -q "$4"; }; then
    echo "  OK   $1  ($actual)"
  else
    echo "  FAIL $1  (očekivano $2 $4, dobijeno $actual: $(body "$3" | head -c 200))"; FAILED=1
  fi
}
token() { body "$1" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p'; }
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

echo "== Prijava"
expect "marshal u backoffice-u je odbijen" 403 "$(call POST /api/auth/login '' backoffice '{"username":"marshal1","password":"demo1234"}')" wrong_app
expect "direkcija u mobilnoj je odbijena"  403 "$(call POST /api/auth/login '' mobile '{"username":"director1","password":"demo1234"}')" wrong_app
expect "pogrešna lozinka"                  401 "$(call POST /api/auth/login '' mobile '{"username":"marshal1","password":"pogresna"}')" invalid_credentials
R=$(call POST /api/auth/login '' backoffice '{"username":"director1","password":"demo1234"}'); expect "direkcija u backoffice-u" 200 "$R"; DIR=$(token "$R")
R=$(call POST /api/auth/login '' mobile '{"username":"marshal1","password":"demo1234"}');       expect "marshal u mobilnoj" 200 "$R"; MAR=$(token "$R")
R=$(call POST /api/auth/login '' mobile '{"username":"marshal2","password":"demo1234"}');       MAR2=$(token "$R")

echo "== Prijava je obavezna, javno je samo stanje poena"
expect "bez prijave"                401 "$(call GET /api/incidents)" unauthorized
expect "izmišljena prijava"         401 "$(call GET /api/incidents 'a.b.c')" unauthorized
expect "javno stanje poena"         200 "$(call GET /api/standings)"

echo "== Ko šta vidi"
expect "direkcija vidi 15+ incidenata" 200 "$(call GET '/api/incidents?limit=200' "$DIR")" '"i-15"'
expect "marshal1 ne vidi tuđe"         200 "$(call GET '/api/incidents?limit=200' "$MAR")" '"i-01"'
call GET '/api/incidents?limit=200' "$MAR" | grep -q '"i-13"' && { echo "  FAIL marshal1 vidi incident marshala2"; FAILED=1; } || echo "  OK   marshal1 ne vidi i-13"
expect "stranica od 3"                 200 "$(call GET '/api/incidents?limit=3' "$DIR")" nextCursor

echo "== Pravila važe i mimo aplikacije"
rep() { # id vozač opis krivina  (telo prijave, pravi se van navodnika zbog starog bash-a na macOS-u)
  printf '{"id":"%s","riderId":"%s","kind":"crash","description":"%s","turn":%s,"reportedAt":"%s"}' "$1" "$2" "$3" "$4" "$(now)"
}
NEW="i-smoke-$RANDOM"
BODY=$(rep "$NEW" r-90 "kratko" 3);                      R=$(call POST /api/incidents "$MAR" mobile "$BODY")
expect "prekratak opis" 422 "$R" description_too_short
BODY=$(rep "$NEW" r-90 "Vozač je pao u krivini." 31);    R=$(call POST /api/incidents "$MAR" mobile "$BODY")
expect "krivina 31" 422 "$R" invalid_turn
BODY=$(rep "$NEW" r-90 "Vozač je pao u krivini." 3);     R=$(call POST /api/incidents "$DIR" backoffice "$BODY")
expect "direkcija ne prijavljuje" 403 "$R" not_allowed
REPORT=$(rep "$NEW" r-90 "Vozač je pao u krivini." 3)
R=$(call POST /api/incidents "$MAR" mobile "$REPORT");   expect "ispravna prijava" 201 "$R"
R=$(call POST /api/incidents "$MAR" mobile "$REPORT");   expect "ista prijava ponovo (sinhronizacija) ne pravi duplikat" 200 "$R"
R=$(call POST /api/incidents "$MAR2" mobile "$REPORT");  expect "tuđa prijava istim id-jem" 403 "$R" not_allowed

echo "== Akcije direkcije mimo aplikacije"
expect "marshal ne potvrđuje" 403 "$(call POST "/api/incidents/$NEW/decision" "$MAR" mobile '{"action":"confirm"}')" not_allowed
expect "odbacivanje traži razlog" 422 "$(call POST "/api/incidents/$NEW/decision" "$DIR" backoffice '{"action":"dismiss","reason":"  "}')" reason_required
expect "kazna pre razmatranja" 409 "$(call POST "/api/incidents/$NEW/decision" "$DIR" backoffice '{"action":"issuePenalty","penaltyKind":"warning","penaltyPoints":1}')" invalid_transition

echo "== Pet istovremenih potvrda istog incidenta: prolazi tačno jedna"
for i in 1 2 3 4 5; do call POST "/api/incidents/$NEW/decision" "$DIR" backoffice '{"action":"confirm"}' > "/tmp/smoke_par_$i" & done; wait
OK=0; STALE=0
for i in 1 2 3 4 5; do c=$(code "$(cat /tmp/smoke_par_$i)"); [ "$c" = 200 ] && OK=$((OK+1)); [ "$c" = 409 ] && STALE=$((STALE+1)); done
if [ $OK = 1 ] && [ $STALE = 4 ]; then echo "  OK   1 prošla, 4 zakasnela (409 invalid_transition)"; else echo "  FAIL prošlo $OK, zakasnelo $STALE"; FAILED=1; fi

echo "== Prag kaznenih poena: dve kazne od 3 poena istovremeno, long lap tačno jednom"
mk() { # id
  local r="{\"id\":\"$1\",\"riderId\":\"r-90\",\"kind\":\"trackLimits\",\"description\":\"Prelazak linije staze u krivini.\",\"turn\":4,\"reportedAt\":\"$(now)\"}"
  call POST /api/incidents "$MAR" mobile "$r" > /dev/null
  call POST "/api/incidents/$1/decision" "$DIR" backoffice '{"action":"confirm"}' > /dev/null
  call POST "/api/incidents/$1/decision" "$DIR" backoffice '{"action":"startReview"}' > /dev/null
}
A="i-smoke-a-$RANDOM"; B="i-smoke-b-$RANDOM"; mk "$A"; mk "$B"
call POST "/api/incidents/$A/decision" "$DIR" backoffice '{"action":"issuePenalty","penaltyKind":"warning","penaltyPoints":3}' > /tmp/smoke_pen_1 &
call POST "/api/incidents/$B/decision" "$DIR" backoffice '{"action":"issuePenalty","penaltyKind":"warning","penaltyPoints":3}' > /tmp/smoke_pen_2 &
wait
expect "kazna A" 200 "$(cat /tmp/smoke_pen_1)"
expect "kazna B" 200 "$(cat /tmp/smoke_pen_2)"
S=$(call GET /api/standings)
body "$S" | grep -o '{[^}]*"riderId":"r-90"[^}]*}' | grep -q '"longLap":true' && echo "  OK   r-90 ima long lap" || { echo "  FAIL r-90 nema long lap: $(body "$S")"; FAILED=1; }
echo "  (u bazi: docker compose exec db psql -U race -d race_direction -c 'select * from rider_long_laps')"

echo "== Tuđ zapis i povlačenje sopstvene prijave"
expect "marshal2 ne povlači tuđu prijavu"    403 "$(call DELETE "/api/incidents/$NEW" "$MAR2" mobile)" not_allowed
expect "direkcija ne povlači prijave"        403 "$(call DELETE "/api/incidents/$NEW" "$DIR" backoffice)" not_allowed
expect "potvrđena prijava se ne povlači"     409 "$(call DELETE "/api/incidents/$NEW" "$MAR" mobile)" not_withdrawable
W="i-smoke-w-$RANDOM"; BODY=$(rep "$W" r-90 "Vozač je pao u krivini." 3); call POST /api/incidents "$MAR" mobile "$BODY" > /dev/null
expect "marshal povlači svoju prijavu"       204 "$(call DELETE "/api/incidents/$W" "$MAR" mobile)"
expect "povučena prijava više ne postoji"    404 "$(call DELETE "/api/incidents/$W" "$MAR" mobile)" not_found

echo "== Povlačenje i potvrda u isto vreme: prolazi tačno jedno"
V="i-smoke-v-$RANDOM"; BODY=$(rep "$V" r-90 "Vozač je pao u krivini." 3); call POST /api/incidents "$MAR" mobile "$BODY" > /dev/null
call DELETE "/api/incidents/$V" "$MAR" mobile > /tmp/smoke_w &
call POST "/api/incidents/$V/decision" "$DIR" backoffice '{"action":"confirm"}' > /tmp/smoke_c &
wait
WC=$(code "$(cat /tmp/smoke_w)"); CC=$(code "$(cat /tmp/smoke_c)")
if { [ "$WC" = 204 ] && [ "$CC" = 404 ]; } || { [ "$WC" = 409 ] && [ "$CC" = 200 ]; }; then
  echo "  OK   povlačenje $WC, potvrda $CC (jedno je prvo, drugo zakasnilo)"
else
  echo "  FAIL povlačenje $WC, potvrda $CC"; FAILED=1
fi

echo
[ $FAILED = 0 ] && echo "SVE PROŠLO" || { echo "NEKA PROVERA NIJE PROŠLA"; exit 1; }
