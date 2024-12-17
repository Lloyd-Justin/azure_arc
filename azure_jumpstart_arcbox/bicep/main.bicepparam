using 'main.bicep'

param tenantId = 'a8b4ecc9-bcb6-4213-81d5-8f8b79042bc8'

param windowsAdminUsername = 'arconaut'

param windowsAdminPassword = '£ArcoPrime1918£'

param logAnalyticsWorkspaceName = 'loganalytics-ARCbox'

param flavor = 'ITPro'

param autoShutdownEnabled = true

param autoShutdownTime = '1900'

param autoShutdownTimezone = 'UTC'

param autoShutdownEmailRecipient = 'justin.lloyd@crydent.com'

param deployBastion = false

param vmAutologon = true

param namingPrefix = 'ARCBox'

param resourceTags = {} // Add tags as needed
