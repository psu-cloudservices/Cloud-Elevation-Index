SELECT 
subscription_id as account_id, 
DATE(billing_period_start_date)as billing_period, 
meter_category as servicecode, 
IFNULL(score, gemini_1_5_pro_score) as score, 
Round(SUM(cost),2) as cost
From {{Azure Data export location}} ade 
join (Select * from `Cloud_Elevation_Index.CEI_SKU_Scoring` where provider = "Azure") on ade.meter_category = service_name 
where aps.price_type="Consumption" 
group by 1,2,3,4  order by subscription_id,billing_period, servicecode