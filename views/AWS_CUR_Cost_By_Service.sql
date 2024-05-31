SELECT 
`lineItem:usage_account_id` as account_id, 
IFNULL(`product:servicecode` , 
IF(`lineItem:legal_entity`="Amazon Web Services, Inc.",`lineItem:product_code`, "Marketplace")) as servicecode, 
`bill:billing_period_start_date` as billing_period, 
Round(SUM(IFNULL(`lineItem:net_unblended_cost`, `lineItem:unblended_cost`)),2) as cost 
FROM `{{AWS CUR DATA LOCATION}}`  
where `lineItem:line_item_type` != "Credit" group by 1,2,3 order by 1,3,4