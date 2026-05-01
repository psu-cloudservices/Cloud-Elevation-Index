SELECT 
SubAccountId,
Date(BillingPeriodStart) as billing_period, 
ServiceName,
score_v1 as score, 
Round(SUM(EffectiveCost),2) as cost
From `up-eit-ce-production.CSP_Billing.FOCUS_Usage` focus
join `Cloud_Elevation_Index.CEI_SKU_Scoring` on focus.ServiceName = service_name 
where ChargeCategory="Usage" 
group by 1,2,3,4  order by SubAccountId, billing_period, ServiceName