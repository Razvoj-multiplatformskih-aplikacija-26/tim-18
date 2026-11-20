## Pokretanje (KT2)

Potrebno: Docker, Flutter (isti kao u CI), na Linuxu za backoffice još `libsecret-1-dev` i `libjsoncpp-dev`.

```bash
git clone https://github.com/Razvoj-multiplatformskih-aplikacija-26/tim-18.git
cd tim-18
cp .env.example .env            # razvojne vrednosti, rade bez izmena
docker compose up --build       # baza (šema + početni podaci) i server na :8080
flutter pub get                 # u korenu
```

Zatim, u drugom terminalu:

```bash
cd apps/mobile     && flutter run     # iOS simulator ili Android emulator
cd apps/backoffice && flutter run -d macos     # ili windows / linux
cd apps/backoffice && flutter run -d chrome    # isti kôd u pregledaču
```

Adresa servera se bira po platformi: Android emulator koristi `10.0.2.2`, ostalo `localhost`.
Drugu adresu zadaje `--dart-define=API_URL=http://<adresa>:8080`.
Verzija nad lažnom implementacijom (bez servera): `flutter run -t lib/main_fake.dart`.

## Demo nalozi

Lozinka za sve naloge je `demo1234` (u bazi samo kao bcrypt heš).

| Nalog       | Uloga     | Aplikacija |
|-------------|-----------|------------|
| `marshal1`  | marshal   | mobilna    |
| `marshal2`  | marshal   | mobilna    |
| `director1` | direkcija | backoffice |

Prijava u pogrešnu aplikaciju je odbijena sa objašnjenjem. Server se proverava skriptom `./scripts/smoke.sh`.
