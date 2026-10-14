# tim-18
# Race Direction

Mobilna i web aplikacija za marshale i direkciju MotoGP trke: marshali na stazi prijavljuju incidente (i bez internet veze), a direkcija ih razmatra, spaja duplirane prijave i izriče kazne i kaznene poene vozačima.

## Tim

| Ime i prezime | Broj indeksa | GitHub nalog |
| --- | --- | --- |
| Emilija Mićović | 120/24 SI | [emilija212](https://github.com/emilija212) |
| Katarina Rakić | 101/24 SI | [katarinaRakic](https://github.com/katarinaRakic) |

## Opis sistema

Race Direction digitalizuje prijavu i obradu incidenata na MotoGP trci. Marshal sa mobilnog telefona prijavljuje incident (pad, nedozvoljeno preticanje, prelazak granica staze) sa opisom, vozačem i lokacijom na stazi. Direkcija trke na velikom ekranu vidi sve prijave, razmatra ih i određuje kaznu. Kazneni poeni se skupljaju kroz celu sezonu, a kad vozač pređe prag, server automatski dodeljuje kaznu (na primer long lap penalty). Javni deo aplikacije prikazuje izrečene kazne i stanje kaznenih poena po vozaču.

## Ispunjenost zahteva

### 1. Uloge korisnika

Postoje dve uloge: **marshal**, koji sa mobilnog šalje prijave incidenata, i **direkcija trke** (osoblje), koja prijave razmatra i odlučuje o kaznama. Svaka uloga vidi samo ono što joj treba za posao.

### 2. Glavni pojam i njegova stanja

Glavni pojam je **incident**, koji prolazi kroz stanja: prijavljen → potvrđen → u razmatranju → kazna izrečena / odbačen. Prelazi između stanja su ograničeni, na primer kazna ne može biti izrečena za incident koji nije prošao razmatranje.

### 3. Pravilo koje zavisi od podataka drugih korisnika

Kazneni poeni jednog vozača skupljaju se iz incidenata koje su prijavili različiti marshali, pa server, a ne klijent, računa ukupan broj poena i automatski dodeljuje kaznu kad se pređe prag. Server takođe spaja duplirane prijave istog incidenta koje stignu od više marshala.

### 4. Rad bez internet veze

Na stazi signal često nestaje, pa marshal može da kreira prijavu incidenta i bez veze. Prijava se čuva lokalno u aplikaciji i sinhronizuje sa serverom čim se veza vrati, a server tada proverava duplikate i primenjuje pravila.

### 5. Posao za osoblje na velikom ekranu

Direkcija trke koristi web aplikaciju na velikom ekranu u kojoj vidi tabelu svih incidenata trke, filtrira ih po stanju i vozaču, razmatra ih i izriče kazne.

### 6. Javno dostupan sadržaj

Javne stranice bez prijave prikazuju listu izrečenih kazni i stanje kaznenih poena po vozaču, pa ih navijači i pretraživači mogu otvoriti direktno.
