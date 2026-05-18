# Cloud Elevation Index

## Billing Data Export Guide

Step-by-step setup for AWS, Azure, and GCP

*Last verified against CSP docs: [DATE]*

> **Who this guide is for:** Higher education IT staff onboarding to the Cloud Elevation Index (CEI). This guide walks through how to export billing data from each major cloud provider and get it into BigQuery, where CEI can analyze it.
>
> **What this guide covers:** The CEI-specific configuration you need when setting up billing exports for AWS, Azure, and GCP. We point you at each provider's official setup walkthrough for the actual console clicks (their UIs change often, and their docs stay current). We focus on what only CEI can tell you: which export settings matter, what to note down for the ingestion pipeline, and operational gotchas.

> **Note:** The data migration step (moving billing data from S3 and Azure Storage into GCP Cloud Storage and BigQuery) is handled by a separate pipeline not covered here. Documentation for that layer is referenced at the end of this guide. The CEI project welcomes community contributions; if you build an infrastructure-as-code version of that pipeline, please consider opening a pull request at the CEI GitHub repository.

---

## What is the Cloud Elevation Index?

CEI is a metric that helps you gauge the maturity of your cloud architecture. It provides a score from 1 to 10, calculated from the services in use and their relative spend, representing how elevated your accounts are on the shared responsibility model.

Higher CEI scores indicate greater use of managed, cloud-native services, where the cloud provider assumes more responsibility for operations, maintenance, and security. CEI can be tracked over time to measure your organization's progress from IaaS toward managed services and SaaS.

| Institution-Level CEI | Account-Level CEI |
| :---- | :---- |
| The big picture. High-level view of cloud maturity across your entire organization. Best suited for executive reporting, strategic planning, and tracking institutional trends. | Where action happens. Focuses on individual accounts to identify which are infrastructure-heavy and where targeted optimization or guidance is needed. |

---

## How Billing Data Flows into CEI

CEI analyzes billing data that has been loaded into BigQuery. Each cloud provider gets its data there differently.

| Provider | Export Source | Intermediate Storage | CEI Destination |
| :---- | :---- | :---- | :---- |
| **AWS** | Cost and Usage Report (CUR 2.0) | S3 bucket | BigQuery (via GCP Data Transfer + Cloud Functions) |
| **Azure** | Cost Management Exports | Azure Storage Account | BigQuery (via GCP Data Transfer + Cloud Functions) |
| **GCP** | Cloud Billing Export | None, native BigQuery | BigQuery (direct) |

> **About the ingestion pipeline:** For AWS and Azure, you will also need to run a separate pipeline that moves billing data from cloud-native storage into GCP Cloud Storage, then transforms and loads it into BigQuery. That pipeline is documented separately (see the end of this guide). This document covers the billing export setup, getting the data into S3 or Azure Storage, which is the required first step.

---

# AWS

Exporting CUR data to S3 for CEI ingestion

## Overview

AWS Data Exports publishes Cost and Usage Report (CUR 2.0) data to an S3 bucket on a recurring schedule. Once the data lands in S3, the CEI ingestion pipeline picks it up and loads it into BigQuery.

This guide covers what CEI needs from your export. For the actual console setup, follow AWS's official walkthrough (linked below).

## Prerequisites

- AWS account with billing access (management account recommended for org-wide data)
- An existing S3 bucket, or permission to create one
- IAM permissions: `billing:PutReportDefinition` on the billing account; `s3:PutBucketPolicy` on the target bucket

## CEI-required export settings

When you create your export, configure these specific settings. Other options (file versioning, compression format) are your call.

| Setting | Required value | Why |
| :---- | :---- | :---- |
| Export type | Standard data export | Legacy CUR is being phased out and the CEI views expect 2.0 schema |
| Data table | CUR 2.0 | Same reason |
| Include Resource IDs | Enabled | Required for account-level CEI scoring |
| Time granularity | Daily | Best balance of freshness and file size for CEI |
| S3 destination | Bucket + path prefix of your choice | Note these down, you'll need them for the ingestion pipeline |

**Follow AWS's setup guide:** [Create a Standard data export](https://docs.aws.amazon.com/cur/latest/userguide/dataexports-create-standard.html)

## After setup, note these connection details

You'll need them when configuring the CEI ingestion pipeline:

- S3 bucket name
- S3 path prefix
- Export name

Initial delivery can take up to 24 hours. Once delivered, confirm the export status shows "Healthy" in the Data Exports console.

## Update frequency

AWS refreshes the S3 export automatically. No scheduling needed on your end.

| Granularity | How it works |
| :---- | :---- |
| **Daily (recommended)** | AWS refreshes S3 at least once per day, up to 3 times. Data is cumulative for the billing month. Best balance of freshness and file size for CEI. |
| **Hourly** | Granular hourly line items. Larger files, longer initial generation time. Useful for spike detection or hourly chargeback, but not required for CEI. |
| **Monthly** | Finalized billing data once per billing period. Lowest storage cost. Limits how current CEI scores will be. |

> **Finalization note:** Data throughout the month is estimated. The finalized bill for each month typically appears in S3 within the first 2 weeks after month-end. Don't run reconciliation-grade CEI reports against mid-month data.

## S3 file structure

Exports land in S3 using a predictable path. The CEI ingestion pipeline references this structure.

```
s3://your-bucket/your-prefix/export-name/
  BILLING_PERIOD=YYYY-MM/
    export-name-part-00001.parquet  (or .csv.gz)
    Manifest.json
```

The `Manifest.json` updates with every refresh and lists all current files for that billing period. The CEI ingestion pipeline uses this to know which files to process.

## AWS documentation references

- [What is Data Exports](https://docs.aws.amazon.com/cur/latest/userguide/what-is-data-exports.html)
- [Create a Standard data export](https://docs.aws.amazon.com/cur/latest/userguide/dataexports-create-standard.html)
- [Data export delivery](https://docs.aws.amazon.com/cur/latest/userguide/dataexports-export-delivery.html)

---

# Azure

Exporting Cost Management data to Blob Storage for CEI ingestion

## Overview

Azure Cost Management has a native Exports feature that schedules recurring delivery of cost and usage data to an Azure Storage Account blob container. Once data lands in blob storage, the CEI ingestion pipeline handles moving it to BigQuery.

This guide covers what CEI needs from your export. For the actual portal setup, follow Microsoft's official walkthrough (linked below).

## Prerequisites

- EA or MCA Azure account with Cost Management access
- An existing Storage Account configured for blob storage, or permission to create one
- IAM role: Owner or Contributor on the subscription scope; Storage Account Contributor on the target storage account

## CEI-required export settings

When you create your export, configure these specific settings.

| Setting | Required value | Why |
| :---- | :---- | :---- |
| Export type | Daily export of month-to-date costs | Best option for keeping CEI scores current |
| Metric | Actual cost | Matches what shows up on your invoice, the basis for CEI scoring |
| Scope | Subscription, Resource Group, or Management Group | Pick whatever matches how your institution organizes accounts |
| File format | CSV or Parquet | Either is supported by the ingestion pipeline |
| Storage destination | Storage Account + container + directory prefix of your choice | Note these down, you'll need them for the ingestion pipeline |

**Follow Microsoft's setup guide:** [Tutorial: Create and manage exports](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-improved-exports)

## After setup, note these connection details

You'll need them when configuring the CEI ingestion pipeline:

- Storage Account name
- Container name
- Directory prefix
- Export name

The first run may take up to 24 hours. Confirm the export appears in the Exports list with a "Healthy" status.

## Update frequency

| Schedule | Description |
| :---- | :---- |
| **Daily (recommended)** | Month-to-date costs exported once per day. Best option for keeping CEI scores current. |
| **Weekly** | Suitable if your institution reviews costs on a weekly cadence. CEI scores will update weekly. |
| **Monthly** | Finalized prior-month data. Lowest storage cost. CEI scores will only update once per month. |

> **Finalization note:** Azure cost data can take 24-72 hours to finalize. Mid-month data is an estimate. For billing reconciliation use cases, always use the monthly finalized export or wait 2-3 days after month-end.

## Storage file structure

Files land in blob storage under a predictable path. The CEI ingestion pipeline references this structure.

```
container/directory/ExportName/
  [20250301-20250331]/[RunID]/
    ExportName_[hash].csv  (or .parquet)
    manifest.json
```

## Azure documentation references

- [Tutorial: Create and manage exports](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-improved-exports)
- [Understand Cost Management data](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/understand-cost-mgt-data)

---

# GCP

Enabling native BigQuery billing export for CEI

## Overview

GCP is the simplest of the three. Billing data streams directly into BigQuery, there is no intermediate object storage step and no separate ingestion pipeline needed. Once you enable the export and point it at a BigQuery dataset, CEI can query the data directly.

This guide covers what CEI needs from your export. For the actual console setup, follow Google's official walkthrough (linked below).

> **Enable this early:** GCP does not backfill data before the export was enabled (except for the previous month in multi-region datasets). Enable billing export as part of your day-1 GCP setup to avoid gaps in your CEI history.

## Prerequisites

- Billing Account Administrator role on the Cloud Billing account
- BigQuery User role on the project that will hold the dataset
- A GCP project linked to the same billing account you want to export from (a dedicated FinOps/billing project is recommended)
- BigQuery Data Transfer Service API enabled on that project

## CEI-required export settings

When you create your dataset and enable export, configure these specific settings.

| Setting | Required value | Why |
| :---- | :---- | :---- |
| Dataset name | Broad/generic (e.g. `all_billing_data`) | This dataset holds all billing data, not project-specific |
| Dataset location | Multi-region: US or EU | Required for retroactive backfill and the detailed export |
| Table expiration | Unchecked (no expiration) | Billing data should persist indefinitely |
| Standard usage cost export | Enabled | Good for high-level trends |
| Detailed usage cost export | Enabled (recommended) | Required for resource-level CEI scoring |

**Follow Google's setup guide:** [Set up Cloud Billing data export to BigQuery](https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery-setup)

## After setup, note these connection details

You'll need them when pointing the CEI views at your billing data:

- GCP project ID
- BigQuery dataset name

Initial data may take a few hours to appear; the full backfill can take up to 5 days.

## Update frequency

GCP billing export updates automatically throughout the day with no schedule to configure. Google writes data to BigQuery continuously as usage is reported by GCP services. Most services report within a few hours.

## BigQuery table structure

GCP automatically creates these tables in your dataset. Do not modify them directly. The CEI views in the GitHub repo query against this schema.

```
-- Standard usage cost (high-level trends)
gcp_billing_export_v1_<BILLING_ACCOUNT_ID>

-- Detailed usage cost (resource-level, recommended for CEI)
gcp_billing_export_resource_v1_<BILLING_ACCOUNT_ID>
```

## GCP documentation references

- [Set up Cloud Billing data export to BigQuery](https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery-setup)
- [Cloud Billing data export to BigQuery](https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery)
- [Detailed usage cost data schema](https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery-tables/detailed-usage)

---

# Next Steps

Getting your billing data into CEI

## What happens after the export is set up

Once your billing data is landing in S3, Azure Blob Storage, or BigQuery, the next step is the CEI ingestion pipeline. For AWS and Azure, this pipeline transfers data from cloud-native storage into GCP Cloud Storage, transforms it, and loads it into BigQuery tables matching the schemas in the CEI repository.

> **Open source note:** The ingestion pipeline code (Cloud Functions, Data Transfer configuration, and supporting infrastructure) has not been included in the public CEI repository at this time. Documentation for setting up that layer is provided separately. If your institution builds a working IaC version of this pipeline, contributions via pull request to the CEI GitHub repo are welcome.

## Once billing data is in BigQuery

With billing data loaded into BigQuery tables, the CEI BigQuery views generate the analysis. The full walkthrough is in the [BigQuery Views Guide](bigquery-views.md). The sequence is:

1. Load CEI service scores into BigQuery using the schema and data file in the repo
2. Create the BigQuery views for each provider (AWS, Azure, GCP), each view needs to be pointed at your billing data tables
3. Run the CEI views to generate institution-level and account-level scores

---

# References

**AWS:**
- https://docs.aws.amazon.com/cur/latest/userguide/what-is-data-exports.html
- https://docs.aws.amazon.com/cur/latest/userguide/dataexports-export-delivery.html

**Azure:**
- https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-improved-exports

**GCP:**
- https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery-setup
- https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery