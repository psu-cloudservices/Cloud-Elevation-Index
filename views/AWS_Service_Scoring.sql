SELECT account_id, 
DATE(billing_period) as billing_period, 
servicecode, IFNULL(score, gemini_1_5_pro_score) as score, 
cost 
From `Cloud_Elevation_Index.AWS_CUR_Cost_By_Service` 
join (Select * from `Cloud_Elevation_Index.CEI_SKU_Scoring` where provider = "AWS") on servicecode = service_name 
group by 1,2,3,4,5 order by account_id