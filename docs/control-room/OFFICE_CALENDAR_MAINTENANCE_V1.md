# Office: kevyt kalenteriylläpito
Päivitetty 10.10.2026 käyttäjän päätöksellä: pidetään Office kevyenä.

Office näyttää projektit ja työt. ChatGPT/Dot ohjaa työtä. Nykyinen Supabase säilyttää yhden työmerkinnän tavoitteen, tilan, tuloksen ja seuraavan toimen. Tavalliselle tarkistukselle ei luoda graph-runeja, nodeja, claim-/transition-kutsuja, erillistä verifier-agenttia eikä mallireititystä. Nykyiset Control Room -taulut jäävät tallennuspaikaksi; niiden vaihemoottori ei ole tämän tarkistuksen riippuvuus. Vanha valmistunut pilotin ajo säilyy historiassa.

## Rajaus
Lue Calendar Supabase tkvpnkxchkhcftttdyos, maat FI/FR/DE/SE. Tallenna vain tämän työn merkintä Supabase cavvdvxicadgfftbziao:n nykyiseen public.control_room_project_work_units_v1-tauluun. Ei uusia ajastuksia/tauluja, maksullisia API-kutsuja, lähdemuutoksia, synkronoinnin käynnistystä, julkaisuja tai ulkoisia viestejä. Ajastus: olemassa oleva seitsemän ajon pilotti 11.–17.10.2026, noin klo 10–11 Europe/Helsinki. Älä pidennä sitä itse.

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
