-- Read-only snapshot from Calendar Platform tkvpnkxchkhcftttdyos.
-- Do not infer absent daily rows as zero. Query/page windows have separate dates.
with sites as (
 select id,country_code,domain,search_console from site_instances where country_code in ('FI','FR','DE','SE')
), bounds as (
 select s.*,max(m.source_property) as source_property,max(m.metric_date) as end_date,max(m.fetched_at) as fetched_at
 from sites s left join search_console_daily_metrics m on m.site_instance_id=s.id group by s.id,s.country_code,s.domain,s.search_console
)
select jsonb_build_object('status','available','observed_at',now(),'source_project','tkvpnkxchkhcftttdyos','refresh_note','Kalenterien nykyinen päivittäinen GSC-haku; Office-kooste päivitetään ylläpitotarkistuksessa.','sites',jsonb_agg(jsonb_build_object(
 'site_id',b.id,'country_code',b.country_code,'property',b.source_property,'registry_status',b.search_console,'fetched_at',b.fetched_at,'period_start',b.end_date-27,'period_end',b.end_date,
 'current',(select jsonb_build_object('days',count(*),'clicks',sum(clicks),'impressions',sum(impressions)) from search_console_daily_metrics where site_instance_id=b.id and metric_date between b.end_date-27 and b.end_date),
 'previous',(select jsonb_build_object('days',count(*),'clicks',sum(clicks),'impressions',sum(impressions)) from search_console_daily_metrics where site_instance_id=b.id and metric_date between b.end_date-55 and b.end_date-28),
 'top_queries',coalesce((select jsonb_agg(t) from (select query as label,clicks,impressions,period_start,period_end,fetched_at from search_console_query_windows where site_instance_id=b.id and window_days=28 and period_end=(select max(period_end) from search_console_query_windows where site_instance_id=b.id and window_days=28) order by clicks desc,impressions desc,query limit 5)t),'[]'::jsonb),
 'top_pages',coalesce((select jsonb_agg(t) from (select page as label,clicks,impressions,period_start,period_end,fetched_at from search_console_page_windows where site_instance_id=b.id and window_days=28 and period_end=(select max(period_end) from search_console_page_windows where site_instance_id=b.id and window_days=28) order by clicks desc,impressions desc,page limit 5)t),'[]'::jsonb)
) order by b.country_code)) as snapshot from bounds b;
