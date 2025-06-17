with 
  account_spend as (
    SELECT SubAccountId, 
    Date(BillingPeriodStart) as billing_period, 
    Round(SUM(EffectiveCost),2) as total_cost 
    From `CSP_Billing.FOCUS_Usage` 
    group by 1,2 order by SubAccountId
  )
SELECT SubAccountId, 
billing_period, 
IF(Round(SUM(percentage_spend),2) >0, 
Round(SUM(weighted_score)/SUM(percentage_spend),2), 0) as CEI, 
total_cost from (
    Select SubAccountId, 
    service_score.billing_period, 
    ServiceName, 
    score, 
    cost, 
    total_cost, 
    Round((cost/total_cost)*100,2) as percentage_spend, 
    Round((cost/total_cost)*100,2)*score as weighted_score 
    from `Cloud_Elevation_Index.FOCUS_Service_Scoring` service_score 
    join account_spend using (SubAccountId,billing_period) 
    where total_cost > 0  order by SubAccountId
    ) 
group by 1,2,4 order by 1,2