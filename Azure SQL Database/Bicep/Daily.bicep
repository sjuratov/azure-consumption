param api_connection_name string = 'sql'
param api_connection_name_suffix string = '1'

param azure_subscription string = '<Subscription ID>'
param azure_region string = resourceGroup().location
param logic_app_name string = '<Logic App name>'

param azure_sql_server string = '<SQL server name>'
param azure_sql_database string = '<SQL database name>'
param azure_sql_database_stored_procedure string = '<SQL stored procedure>'

var resourceManager = environment().resourceManager

resource api_connection_sql_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: '${api_connection_name}-${api_connection_name_suffix}'
  location: azure_region
  properties: {
    displayName: '${azure_sql_database}-${api_connection_name}-db'
    api: {
      name: api_connection_name
      displayName: 'SQL Server'
      iconUri: 'https://connectoricons-prod.azureedge.net/laborbol/patches/1520/${api_connection_name}-mi/1.0.1520.2572/${api_connection_name}/icon.png'
      brandColor: '#ba141a'
      id: '/subscriptions/${azure_subscription}/providers/Microsoft.Web/locations/${azure_region}/managedApis/${api_connection_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    parameterValueSet: {
      name: 'oauthMI'
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
        For_each: {
          foreach: '@body(\'Parse_JSON_result\')?[\'value\']'
          actions: {
            'Execute_stored_procedure_(V2)': {
              runAfter: {}
              type: 'ApiConnection'
              inputs: {
                body: {
                  billingCurrency: '@items(\'For_each\')?[\'properties\']?[\'billingCurrency\']'
                  consumedService: '@items(\'For_each\')?[\'properties\']?[\'consumedService\']'
                  cost: '@items(\'For_each\')?[\'properties\']?[\'cost\']'
                  datetime: '@items(\'For_each\')?[\'properties\']?[\'date\']'
                  effectivePrice: '@items(\'For_each\')?[\'properties\']?[\'effectivePrice\']'
                  quantity: '@items(\'For_each\')?[\'properties\']?[\'quantity\']'
                  resourceGroup: '@items(\'For_each\')?[\'properties\']?[\'resourceGroup\']'
                  resourceId: '@items(\'For_each\')?[\'properties\']?[\'resourceId\']'
                  resourceName: '@items(\'For_each\')?[\'properties\']?[\'resourceName\']'
                  subscriptionId: '@items(\'For_each\')?[\'properties\']?[\'subscriptionId\']'
                  tagsCostCenter: '@{items(\'For_each\')?[\'tags\']?[\'Cost Center\']}'
                  tagsEnvironment: '@{items(\'For_each\')?[\'tags\']?[\'Environment\']}'
                  tagsOwner: '@{items(\'For_each\')?[\'tags\']?[\'Owner\']}'
                }
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${azure_sql_server}\'))},@{encodeURIComponent(encodeURIComponent(\'${azure_sql_database}\'))}/procedures/@{encodeURIComponent(encodeURIComponent(\'${azure_sql_database_stored_procedure}\'))}'
              }
            }
          }
          runAfter: {
            Parse_JSON_result: [
              'Succeeded'
            ]
          }
          type: 'Foreach'
        }
        Initialize_date_variable: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'date'
                type: 'string'
                value: '@{formatDateTime(addDays(utcNow(),-1),\'yyyy-MM-dd\')}'
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
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          sql: {
            connectionId: api_connection_sql_resource.id
            connectionName: '${api_connection_name}-${api_connection_name_suffix}'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${azure_subscription}/providers/Microsoft.Web/locations/${azure_region}/managedApis/sql'
          }
        }
      }
    }
  }
}
