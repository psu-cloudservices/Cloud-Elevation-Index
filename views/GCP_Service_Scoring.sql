SELECT project.id as account_id, 
Date(CONCAT(SUBSTR(invoice.month,0,4),"-",SUBSTR(invoice.month,5,2),"-01")) as billing_period, 
service.description as servicecode, 
score_v1 as score, 
cost, 
IFNULL((SUM((SELECT SUM(if(c.type !="PROMOTION", CAST(c.amount * 1000000 AS int64), 0)) FROM   UNNEST(credits) c))/1000000),0.0) as credits_applied 
From `{{GCP BIGQUERY BILLING EXPORT}}` 
join (Select * from `Cloud_Elevation_Index.CEI_Versioned_Scoring` where provider = "GCP") on service.description = service_name 
group by 1,2,3,4,5 order by 1