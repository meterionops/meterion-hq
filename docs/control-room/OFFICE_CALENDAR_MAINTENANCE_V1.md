# Office: kevyt kalenteriylläpito
Päivitetty 10.10.2026 käyttäjän päätöksellä: pidetään Office kevyenä.

Office näyttää projektit ja työt. ChatGPT/Dot ohjaa työtä. Nykyinen Supabase säilyttää yhden työmerkinnän tavoitteen, tilan, tuloksen ja seuraavan toimen. Tavalliselle tarkistukselle ei luoda graph-runeja, nodeja, claim-/transition-kutsuja, erillistä verifier-agenttia eikä mallireititystä. Nykyiset Control Room -taulut jäävät tallennuspaikaksi; niiden vaihemoottori ei ole tämän tarkistuksen riippuvuus. Vanha valmistunut pilotin ajo säilyy historiassa.

## Rajaus
Lue Calendar Supabase tkvpnkxchkhcftttdyos, maat FI/FR/DE/SE. Tallenna tämän työn merkintä Supabase cavvdvxicadgfftbziao:n nykyiseen public.control_room_project_work_units_v1-tauluun. Lisäksi päivitä alla kuvattu office_gsc-kooste nykyiseen projektikytkentään. Ei uusia ajastuksia/tauluja, maksullisia API-kutsuja, lähdemuutoksia, synkronoinnin käynnistystä, julkaisuja tai ulkoisia viestejä. Ajastus: olemassa oleva seitsemän ajon pilotti 11.–17.10.2026, noin klo 10–11 Europe/Helsinki. Älä pidennä sitä itse.

## Yksi tarkistus
1. Päiväkohtainen work_unit_key on office-calendar-maintenance-YYYYMMDD (UTC). Lue merkintä ensin: completed = valmis, älä toista. active alle 30 min = toinen suoritus voi olla käynnissä, älä aloita toista. Odottavan/epäonnistuneen työn saa uusia kerran; päivitä vain jos updated_at ja status vastaavat lukemaasi. Yli 30 min vanha active voidaan jatkaa samana työnä, enintään toinen yritys. Säilytä aiempi virhe metadata.last_error-kentässä. Tämä on read-only-tarkistus: keskeytynyt lähdeluku voidaan tehdä uudelleen.
2. Uuden työn voi kirjata yhdellä INSERTillä; vain RETURNING-rivin saanut suoritus jatkaa:
```sql
insert into public.control_room_project_work_units_v1
(project_id,work_unit_key,source_state_version,objective,definition_of_done,contract_hash,status,metadata)
select p.id, :work_key, s.version,
'Tarkista Calendar Platformin Search Console -ylläpidon toimivuus neljässä maassa',
'{"criteria":["Ajastus ja datan tuoreus tarkistettu FI/FR/DE/SE","Tulos, lähteet ja jatkotoimi tallennettu"]}'::jsonb,
md5(p.id::text || ':' || :work_key || ':office-calendar-light-v1'),
'active','{"office_workflow":"calendar-maintenance-v1","office_storage_mode":"simple_work_record","attempts":1}'::jsonb
from control_room_projects p join control_room_project_current_v2 s on s.project_id=p.id
where p.project_key='calendar-platform'
on conflict(project_id,work_unit_key) do nothing returning id,updated_at;
```
Kaksoispisteparametrit ovat sidottavia arvoja, eivät valmista SQL:ää. Jos connector ei tue parametreja, validoi päiväavain ja käytä oikein escapettuja SQL-literaaleja.
3. Tee yksi koottu lähdekysely: cron.job (nimi sync-search-console-daily; active, schedule), viimeisin cron.job_run_details (status,start_time) ja site_instances LEFT JOIN search_console_daily_metrics site_instance_id:llä. Palauta kullekin maalle country_code,search_console,count(m.id),max(metric_date),max(fetched_at) ja havainnon now(). Älä lue cron-komentoa tai salaisuuksia.
4. Tarkista koodilla tai täsmällisillä säännöillä neljän maan kattavuus. Erottele cron-kutsun onnistuminen ja datan tuoreus. Disabled/failed/ajo yli36h, puuttuva data, haku yli36h tai mittauspäivä yli7vrk = huomio. 4–7vrk viive on seurantahavainto, ei yksin todettu synkronointivika. PENDING + tuore data = rekisteriristiriita. Puuttuva lähde ei ole onnistunut tarkistus.
5. Tallenna samaan työmerkintään metadata.office_result: summary,outcome(healthy/attention),observed_at,verified_at,next_action,alerts[string],checks[string],source_project,source_tables[string],countries[{country_code,search_console,latest_fetch,latest_metric_date}],verification_method,cost_status=UNKNOWN. Tallenna myös metadata.next_action. Varmennus tarkoittaa tehtyjä lähde-/kattavuustarkistuksia, ei erillistä AI-tuomaria. Säilytä vanha metadata JSONB-yhdistämisellä. Vain onnistuneen tarkistuksen jälkeen status=completed,completed_at=now(),updated_at=now(). Päivityksen WHERE sitoo id:n sekä oman aloitus-/jatkamispäivityksen palauttaman updated_at-arvon ja active-tilan, jotta vanhentunut suorittaja ei korvaa tulosta.
6. Lähde- tai tallennusvirheessä jätä työ waiting/failed ja metadata.last_error sekä resume_note (mitä puuttuu). Ei keksittyä tulosta. Enintään yksi uusintayritys, ei silmukkaa.
7. metadata.office_maintenance säilyttää automation_id,schedule_label,schedule_recorded_at,next_expected_at,pilot_end_at. Tarkista olemassa olevan ajastuksen tila yksityisellä peek-haulla. Seuraava odotettu aika on seuraavan todellisen ajoikkunan loppu, ei takuu. Viimeisen pilotin jälkeen jätä next_expected_at pois, älä keksi jatkoa. Pilotin lopussa schedule_label kertoo pilotin päättyneen.
8. Lue tallennettu työ takaisin. Käyttöliittymä lukee office_resultin suoraan työmerkinnästä, joten älä kirjoita uusia tuloksia graph-tauluihin. Ilmoita vain uudesta olennaisesta poikkeamasta tai käyttöoikeusesteestä. Ei päivittäistä ilmoitusta samasta DE/SE PENDING-ristiriidasta.

## Yleinen Office-periaate
Useita tavoitteellisia töitä voi kuulua projektiin. Yksi työmerkintä per työ, ja lyhyt resume_note vain kun tarvitaan jatkamiskohta. Ei yleistä agenttiorganisaatiota tai uutta suoritusalustaa. Pitkissä tuoteomissa ajoissa käytetään niiden olemassa olevaa työntekijää ja tallennetaan Officeen tulos/viite.

## GSC-kooste Officeen (hyväksytty 10.10.2026)
Päivittäisen tarkistuksen yhteydessä lue saman branchin `docs/control-room/office-gsc-snapshot.sql` ja suorita se Calendar Supabasessa. SQL on vain luku. Se tuottaa neljä sivustokoostetta: viimeiset 28 päivää ja edelliset 28 päivää viimeisestä tallennetusta päivästä, päivien kattavuus sekä enintään viisi hakusanaa ja laskeutumissivua omine jaksoineen. Älä sekoita jaksoja tai laske hakusanojen summaa koko liikenteeksi. Puuttuva päivä ei ole nolla, prosenttivertailu vain 28/28 + 28/28 kattavuudella ja positiivisella vertailuarvolla. GSC ei ole koko sivuston kävijämittaus.

Päivitä tulos nykyiseen `control_room_project_connections.metadata.office_gsc`-kenttään, ainoastaan Calendar Platformin project_id=171b3a31-575f-4883-a0fd-009ed304dcc7 ja connection_type=supabase. Säilytä muut metadata-avaimet. Kooste on lähteestä johdettu rajattu näyttöaineisto, ei uusi master. Säilytä source_project, observed_at, lähteen fetched_at sekä period_start/end. Tallenna kokonaisuus atomisesti yhteen riviin ja varmista takaisinluvulla neljä yksilöllistä site_id:tä. Tarvittaessa pienet maaerät staging-avaimeen ja vaihto office_gsc-avaimeen vasta neljän maan validoinnin jälkeen; älä jätä keskeneräistä koontia näkyviin. Lähdevirheessä säilytä vanha kooste alkuperäisellä päiväyksellä ja kirjaa työn virhe. Älä päivitä havainnon aikaa ilman uutta lähdelukua.

`office_gsc.next_action` säilyttää viimeisen perustellun suosituksen. `refresh_note` kertoo päivittäisestä lähdehausta ja Office-päivityksestä sekä pilotin 11.–17.10. rajasta. UI näyttää yli36h vanhan koosteen vanhentuneena. Maiden PENDING-merkintää ei muuteta pelkän päiväkoosteen perusteella; lukijan kuuluu erottaa saatu data ja vanha rekisterimerkintä.

Lauantaina tee samalla viikkoarvio. Valitse korkeintaan yksi evidenssiin sidottu parannus ja kirjaa planned-työ samaan nykyiseen työtauluun vain, jos samaan sivuun ja tavoitteeseen ei jo ole avointa työtä. Käytä vakaata work_unit_key:tä ja ON CONFLICT DO NOTHING; ei automaattista julkaisua tai muutosta kohdesivustoon. Jos aineisto ei riitä, kirjaa se; älä keksi parannusehdotusta. Päivitä next_action vastaamaan avoinna olevaa tehtävää, älä monista sitä jokaiselle päivälle.
Ensimmäinen tällainen työ: `office-gsc-fr-numero-de-semaine` (Ranskan viikkonumerosivun hakuaikomuksen ja otsikon tutkiminen).

Maistion ja Far by Railin suora GSC-yhteys on valmistelussa. Käyttäjän päätös 10.10.2026: käytä suoraa Google Search Console API -yhteyttä; GSC Wizard on toistaiseksi kokonaan pois Meterion Officen työnkuluista. Älä kutsu Wizard-työkaluja, käytä sitä fallbackina tai edellytä sen tilausta. ChatGPT-pluginin asennusta ei poistettu, koska pyyntö koski tilapäistä käytöstä poistamista.

Nykyiset Calendar Platformin suorat Google-yhteydet FI/FR/DE/SE varmennettu telemetry_integrations-taulusta 10.10.2026: auth_state CONFIGURED, sync_state OK, last_success_at noin05:30 UTC. Näiden toimintaa ei muuteta. Maistion ja Far by Railin property-käyttöoikeudet vielä varmentamatta. Lovable-agentille annettu read-only-pyyntö käyttää nykyistä palvelutunnusta Google sites.list -tarkistukseen hylättiin automaattisessa hyväksyntätarkistuksessa: palvelutunnuksen käyttö ja principal-tunnisteen palautus ulkoisen agentin kautta vaativat täsmennetyn omistajaluvan. Ensimmäinen pyyntö ei toteutunut. Omistaja hyväksyi 10.10.2026 klo11:49 Europe/Helsinki tämän rajatun tarkistuksen ja lisäsi korvauskirje.fi:n samaan rajaukseen. Uusi hyväksytty tarkistus lähetetty Lovableen (umsg_01m4jg2vc3fart3nr2pfafyv9f); tulos vielä odottaa. Ei uutta tunnusta. Tavoiteltu tarkistus: Google webmasters.readonly, vain maistio.fi/farbyrail.com/korvauskirje.fi-tulokset, exact property + permissionLevel, tarvittaessa palvelutunnuksen julkinen client_email oikeuksien määrittämiseen; ei private_key/access_token/credentials JSON -paljastusta tai siirtoa. Vasta tarkistuksen jälkeen pienin suora yhteys nykyisiin Office-koosteisiin, ei uutta yleistä integraatioalustaa eikä keinotekoisia Calendar-maita.
