# Azure Consumption

Microsoft provides Azure cost export functionality as documented at https://docs.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-export-acm-data?tabs=azure-portal

Unfortunately, one of the requirements is that storage account (where data is exported to) must not have a firewall configured. In some environments that might be a problem.

Alternative to native export functionality is custom solution.

This repo provides one such solution, where data can be written to either Azure storage account or Azure SQL database.