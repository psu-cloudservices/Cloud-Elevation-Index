SELECT account_id, 
DATE(billing_period) as billing_period, 
servicecode, 
score_v1 as score, 
cost 
From `Cloud_Elevation_Index.AWS_CUR_Cost_By_Service` 
join (Select * from `Cloud_Elevation_Index.CEI_Versioned_Scoring` where provider = "AWS") on servicecode = service_name 
group by 1,2,3,4,5 order by account_id