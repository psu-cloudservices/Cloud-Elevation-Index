with 
  account_spend as (
    SELECT account_id, 
    DATE(billing_period) as billing_period, 
    Round(SUM(cost),2) as total_cost 
    From `Cloud_Elevation_Index.AWS CUR Cost By Service` 
    group by 1,2 order by account_id
  )
SELECT account_id, 
billing_period, 
IF(Round(SUM(percentage_spend),2) >0, 
Round(SUM(weighted_score)/SUM(percentage_spend),2), 0) as CEI, 
total_cost from (
    Select account_id, 
    service_score.billing_period, 
    servicecode, 
    score, 
    cost, 
    total_cost, 
    Round((cost/total_cost)*100,2) as percentage_spend, 
    Round((cost/total_cost)*100,2)*score as weighted_score 
    from `Cloud_Elevation_Index.AWS_Service_Scoring` service_score 
    join account_spend using (account_id,billing_period) 
    where total_cost > 0  order by account_id 
) group by 1,2,4 order by 1,2