## About ##
The Cloud Elevation Index metric was developed at Penn State University to show the releative usage of higher level cloud services across accounts and in larger groupings. The Index value tracks the spend of services against a relative score for every service in the big three providers. 

[Telling Our Story: The Somewhat Painful, Probably Never-Ending Search for Cloud Metrics](https://drive.google.com/file/d/19nPqr4m0cxjSRZbBE-f4FiY1yiPmBLOq/view?usp=sharing)

## Loading CEI Scores into BigQuery ##

Note that the schema has additional fields than are currently used. This is for future use.  

`bq load Cloud_Elevation_Index.CEI_SKU_Scoring --schema schema.json --clustering_fields provider,service_name cei_scores.nljson`

## Creating BQ Views ##
Each provider has at minimum two views towards generating a CEI value. The first view creates an intermediate that creates a spend by service in each billing period by account joined to the service score table. This was done to make it easy to troubleshoot issues in queries. The CEI view then creates the final scores. Each service scoring view definition will need to be edited to point to the appropriate spend data.

### AWS ###
AWS relies on a third intermediate that simplifies the raw CUR data for CEI. This is the one to edit to point to billing data.

```bq mk --view `cat ./views/AWS_CUR_Cost_By_Service` Cloud_Elevation_Index.AWS_CUR_Cost_By_Service```

The AWS Service Scoring view may require editing to use the service_alias field during the score table join if not using CUR data. This is likely if using data from a third party cost managment service.  
```bq mk --view `cat ./views/AWS_Service_Scoring` Cloud_Elevation_Index.AWS_Service_Scoring```

```bq mk --view `cat ./views/AWS_CEI` Cloud_Elevation_Index.AWS_CEI```

### GCP ###
```bq mk --view `cat ./views/GCP_Service_Scoring` Cloud_Elevation_Index.GCP_Service_Scoring```

```bq mk --view `cat ./views/GCP_CEI` Cloud_Elevation_Index.GCP_CEI```

### Azure ###
```bq mk --view `cat ./views/Azure_Service_Scoring` Cloud_Elevation_Index.Azure_Service_Scoring```

```bq mk --view `cat ./views/Azure_CEI` Cloud_Elevation_Index.Azure_CEI```