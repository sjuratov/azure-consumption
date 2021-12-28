param api_connection_name string = 'azureblob'
param api_connection_name_suffix string = '1'

param azure_subscription string = '<Subscription ID>'
param azure_region string = resourceGroup().location
param logic_app_name string = '<Logic App name>'

param azure_storage_account string = '<Storage account name>'
param azure_storage_account_folder_path string = '<Storage account folder path>'

var resourceManager = environment().resourceManager

resource api_connection_storage_account_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: '${api_connection_name}-${api_connection_name_suffix}'
  location: resourceGroup().location
  properties: {
    displayName: '${azure_storage_account}-${api_connection_name}'
    api: {
      name: api_connection_name
      displayName: 'Azure Blob Storage'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1544/1.0.1544.2640/${api_connection_name}/icon.png'
      brandColor: '#804998'
      id: '/subscriptions/${azure_subscription}/providers/Microsoft.Web/locations/${azure_region}/managedApis/${api_connection_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    parameterValueSet: {
      name: 'managedIdentityAuth'
      values: {}
    }
  }
}

resource logic_app_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logic_app_name
  location: azure_region
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Disabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
        date: {
          defaultValue: '2021-10-01'
          type: 'String'
        }
        subscription: {
          defaultValue: azure_subscription
          type: 'String'
        }
      }
      triggers: {
        'Runs_at_8:00_every_day': {
          recurrence: {
            frequency: 'Day'
            interval: 1
            schedule: {
              hours: [
                '8'
              ]
              minutes: [
                0
              ]
            }
            timeZone: 'W. Europe Standard Time'
          }
          evaluatedRecurrence: {
            frequency: 'Day'
            interval: 1
            schedule: {
              hours: [
                '8'
              ]
              minutes: [
                0
              ]
            }
            timeZone: 'W. Europe Standard Time'
          }
          type: 'Recurrence'
        }
      }
      actions: {
        Call_Azure_Consumption_REST_API: {
          runAfter: {
            Initialize_date_variable: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            authentication: {
              audience: resourceManager
              type: 'ManagedServiceIdentity'
            }
            method: 'GET'
            queries: {
              '$filter': 'properties/usageEnd eq \'@{variables(\'date\')}\''
              'api-version': '2021-10-01'
            }
            uri: '${resourceManager}subscriptions/@{parameters(\'subscription\')}/providers/Microsoft.Consumption/usageDetails'
          }
        }
        Create_CSV_table: {
          runAfter: {
            Parse_JSON_result: [
              'Succeeded'
            ]
          }
          type: 'Table'
          inputs: {
            columns: [
              {
                header: 'subscriptionId'
                value: '@item()?[\'properties\']?[\'subscriptionId\']'
              }
              {
                header: 'date'
                value: '@item()?[\'properties\']?[\'date\']'
              }
              {
                header: 'quantity'
                value: '@item()?[\'properties\']?[\'quantity\']'
              }
              {
                header: 'effectivePrice'
                value: '@item()?[\'properties\']?[\'effectivePrice\']'
              }
              {
                header: 'cost'
                value: '@item()?[\'properties\']?[\'cost\']'
              }
              {
                header: 'billingCurrency'
                value: '@item()?[\'properties\']?[\'billingCurrency\']'
              }
              {
                header: 'resourceId'
                value: '@item()?[\'properties\']?[\'resourceId\']'
              }
              {
                header: 'resourceName'
                value: '@item()?[\'properties\']?[\'resourceName\']'
              }
              {
                header: 'resourceGroup'
                value: '@item()?[\'properties\']?[\'resourceGroup\']'
              }
              {
                header: 'consumedService'
                value: '@item()?[\'properties\']?[\'consumedService\']'
              }
              {
                header: 'tags.Environment'
                value: '@item()?[\'tags\']?[\'Environment\']'
              }
              {
                header: 'tags.Owner'
                value: '@item()?[\'tags\']?[\'Owner\']'
              }
              {
                header: 'tags.CostCenter'
                value: '@item()?[\'tags\']?[\'Cost Center\']'
              }
            ]
            format: 'CSV'
            from: '@body(\'Parse_JSON_result\')?[\'value\']'
          }
        }
        Initialize_date_variable: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'date'
                type: 'string'
                value: '@parameters(\'date\')'
              }
            ]
          }
        }
        Parse_JSON_result: {
          runAfter: {
            Call_Azure_Consumption_REST_API: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Call_Azure_Consumption_REST_API\')'
            schema: {
              properties: {
                value: {
                  items: {
                    properties: {
                      id: {
                        type: 'string'
                      }
                      kind: {
                        type: 'string'
                      }
                      name: {
                        type: 'string'
                      }
                      properties: {
                        properties: {
                          billingCurrency: {
                            type: 'string'
                          }
                          billingPeriodEndDate: {
                            type: 'string'
                          }
                          billingPeriodStartDate: {
                            type: 'string'
                          }
                          billingProfileId: {
                            type: 'string'
                          }
                          billingProfileName: {
                            type: 'string'
                          }
                          chargeType: {
                            type: 'string'
                          }
                          consumedService: {
                            type: 'string'
                          }
                          cost: {
                            type: 'number'
                          }
                          date: {
                            type: 'string'
                          }
                          effectivePrice: {
                            type: 'number'
                          }
                          frequency: {
                            type: 'string'
                          }
                          isAzureCreditEligible: {
                            type: 'boolean'
                          }
                          meterDetails: {}
                          meterId: {
                            type: 'string'
                          }
                          offerId: {
                            type: 'string'
                          }
                          publisherType: {
                            type: 'string'
                          }
                          quantity: {
                            type: 'number'
                          }
                          resourceGroup: {
                            type: 'string'
                          }
                          resourceId: {
                            type: 'string'
                          }
                          resourceLocation: {
                            type: 'string'
                          }
                          resourceName: {
                            type: 'string'
                          }
                          subscriptionId: {
                            type: 'string'
                          }
                          subscriptionName: {
                            type: 'string'
                          }
                          unitPrice: {
                            type: 'integer'
                          }
                        }
                        type: 'object'
                      }
                      tags: {}
                      type: {
                        type: 'string'
                      }
                    }
                    required: [
                      'kind'
                      'id'
                      'name'
                      'type'
                      'tags'
                      'properties'
                    ]
                    type: 'object'
                  }
                  type: 'array'
                }
              }
              type: 'object'
            }
          }
        }
        Save_result_to_storage_account: {
          runAfter: {
            Create_CSV_table: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: '@body(\'Create_CSV_table\')'
            headers: {
              ReadFileMetadataFromServer: true
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${azure_storage_account}\'))}/files'
            queries: {
              folderPath: '/${azure_storage_account_folder_path}'
              name: '@{variables(\'date\')}.csv'
              queryParametersSingleEncoded: true
            }
          }
          runtimeConfiguration: {
            contentTransfer: {
              transferMode: 'Chunked'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azureblob: {
            connectionId: api_connection_storage_account_resource.id
            connectionName: '${api_connection_name}-${api_connection_name_suffix}'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${azure_subscription}/providers/Microsoft.Web/locations/${azure_region}/managedApis/azureblob'
          }
        }
      }
    }
  }
}
