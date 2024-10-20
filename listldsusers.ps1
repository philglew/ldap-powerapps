param ( 
    [string]$ldapServer = "localhost:389" 
)

function Get-DataverseAccessToken {
    param (
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$Resource = "https://org76d778ff.crm11.dynamics.com"
    )

    $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

    $body = @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = "$Resource/.default"
        grant_type    = "client_credentials"
    }

    $response = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -Body $body
    return $response.access_token
}

# Authentication parameters
$TenantId = "REDACTED"
$ClientId = "REDACTED"
$ClientSecret = "REDACTED"
$Resource = "https://org76d778ff.crm11.dynamics.com"  # Replace with your Dataverse URL

# Obtain access token
$accessToken = Get-DataverseAccessToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret -Resource $Resource

function Get-LDAPUsers {
    param (
        [string]$ldapServer
    )

    $usersContainerDN = "CN=Users,DC=LocalLDAP,DC=COM"
    $ldapPath = "LDAP://$ldapServer/$usersContainerDN"
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher
    $directorySearcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry($ldapPath)
    $directorySearcher.Filter = "(objectClass=user)"
    [void]$directorySearcher.PropertiesToLoad.Add("cn")
    [void]$directorySearcher.PropertiesToLoad.Add("mail")
    [void]$directorySearcher.PropertiesToLoad.Add("company")
    [void]$directorySearcher.PropertiesToLoad.Add("memberOf")

    $allUsers = @()

    try {
        $result = $directorySearcher.FindAll()
        foreach ($user in $result) {
            $userName = $user.Properties["cn"][0]
            $userMail = $user.Properties["mail"][0]
            $userCompany = $user.Properties["company"][0]
            $groupMemberships = $user.Properties["memberOf"]

            $groups = $groupMemberships | ForEach-Object {
                $groupDN = $_
                $groupCN = ($groupDN -split ",")[0] -replace "CN=", ""
                $groupCN
            }

            $userObject = [PSCustomObject]@{
                Username  = $userName
                Email     = $userMail
                Company   = $userCompany
                Groups    = $groups -join ', '
            }

            # Dataverse entity (table) logical name
            $entityName = "crf98_table1"  # Replace with your actual table logical name

            # Construct the API endpoint
            $apiUrl = "$Resource/api/data/v9.2/$($entityName)s"

            # Prepare the user data for Dataverse
            $userData = @{
                "crf98_username" = $userObject.Username
                "crf98_email"    = $userObject.Email
                "crf98_company"  = $userObject.Company
                "crf98_groups"   = $userObject.Groups
            }

            # Convert the data to JSON
            $userDataJson = $userData | ConvertTo-Json -Depth 3

            # Send a POST request to create a new record
            try {
                $response = Invoke-RestMethod -Method Post -Uri $apiUrl -Headers @{
                    "Authorization" = "Bearer $accessToken"
                    "Content-Type"  = "application/json"
                    "OData-MaxVersion" = "4.0"
                    "OData-Version" = "4.0"
                } -Body $userDataJson
                Write-Output "Successfully created record for $($userObject.Username)"
            } catch {
                Write-Error "Error creating record for $($userObject.Username): $_"
            }
        }
    } catch {
        Write-Error "Error retrieving users: $_"
    }
}

try {
    Get-LDAPUsers -ldapServer $ldapServer
} catch {
    Write-Error "Error: $_"
}
