param (  
    [string]$ldapServer = "localhost:389" 
)

function Add-LDAPUser {
    param (
        [string]$ldapServer,
        [string]$userName,     # User's Common Name (CN)
        [string]$userMail,     # User's email
        [string]$userCompany,  # User's company
        [array]$userGroups     # Groups to add the user to
    )

    $usersContainerDN = "CN=Users,DC=LocalLDAP,DC=COM"  # Modify as per your LDAP structure
    $ldapPath = "LDAP://$ldapServer/$usersContainerDN"
    
    $container = New-Object DirectoryServices.DirectoryEntry($ldapPath)

    try {
        $newUser = $container.Create("user", "CN=$userName")
        $newUser.Put("mail", $userMail)
        $newUser.Put("company", $userCompany)
        $newUser.SetInfo()  # Commit the user to LDAP

        Write-Output "User $userName created successfully in LDAP."

        if ($userGroups -ne $null) {
            foreach ($group in $userGroups) {
                try {
                    $groupDN = "CN=$group,CN=Groups,DC=LocalLDAP,DC=COM"  # Modify as per your LDAP structure
                    $groupEntry = New-Object DirectoryServices.DirectoryEntry("LDAP://$ldapServer/$groupDN")
                    $groupEntry.Properties["member"].Add($newUser.distinguishedName)
                    $groupEntry.CommitChanges()
                    Write-Output "User $userName successfully added to group $group."
                } catch {
                    Write-Error "Failed to add user $userName to group $group: $_"
                }
            }
        }

    } catch {
        Write-Error "Failed to create user $userName: $_"
    }
}

$userName = "John Doe"           # Common Name (CN) of the user
$userMail = "johndoe@example.com"  # Email
$userCompany = "ExampleCorp"       # Company name
$userGroups = @("Administrators", "Users")  # Placeholder group memberships

try {
    Add-LDAPUser -ldapServer $ldapServer -userName $userName -userMail $userMail -userCompany $userCompany -userGroups $userGroups
} catch {
    Write-Error "An error occurred: $_"
}
