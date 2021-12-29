# Azure Consumption

Microsoft provides Azure cost export functionality as documented at https://docs.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-export-acm-data?tabs=azure-portal

Unfortunately, one of the requirements is that storage account (where data is exported to) must not have a firewall configured. In some environments that might be a problem.

Alternative to native export functionality is custom solution.

This repo provides one such solution, where data can be written to either Azure storage account or Azure SQL database.

Solution is using Azure Logic App to make REST API call to Azure Consumption Usage Details - https://docs.microsoft.com/en-us/rest/api/consumption/usage-details/list

Returned JSON is parsed and then written to either Azure storage account or Azure SQL database.

There are four Logic Apps - two writing to Azure SQL database and two writing to Azure storage account.

## Repo description

Two top level folders **Azure SQL Database** and **Azure Storage Account** contain notebooks and Bicep templates.

Bicep folders under top level folders contain Daily and Backfill templates, both taking parameters.

Daily templates take **subscription** (e.g. 99842294-660a-431a-88c0-52b9d8263a32) as an input. **date** (e.g. 2021-11-25) is another (optional) input. Default trigger would run Logic App every day at 8:00 CET and call REST API endpoint for a previous day. *Initialize date variable* action can be changed so that value is set to **date** parameter. In other words, this Logic App can run every day and collect data for previous day or it can be run ad-hoc with any other arbitrary date (when **date** parameter is used).

Backfill templates take **subscription** (e.g. 99842294-660a-431a-88c0-52b9d8263a32), **numberOfDaysToBackfill** (e.g. 2) and **numberOfDaysToGoBack** (e.g. -30) as an input. Although default trigger would run Logic App every day at 8:00 CET, this Logic App is intended to be used on ad-hoc basis, when past data needs to be backfilled. Normally, this Logic App would be disabled. **numberOfDaysToGoBack** is a bit strange implementation. Ideally we would have different variable e.g. **startBackfillOn** set to some string/date representation (e.g. 2021-11-25) and then use **numberOfDaysToBackfill**. However, I wasn't able to find a way to take string (parameters don't support *date* type) and then convert it to date (ref: https://docs.microsoft.com/en-us/azure/logic-apps/workflow-definition-language-functions-reference).


