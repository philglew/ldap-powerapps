param (  
    [string]$ldapServer = "localhost:389",
    [string]$userName   # The CN of the user to be moved
)

function Move-LDAPUser {
    param (
        [string]$ldapServer,
        [string]$userName
    )

    $baseDN = "DC=LocalLDAP,DC=COM"
    $deletedUsersContainerDN = "CN=DeletedUsers,DC=LocalLDAP,DC=COM"
    
    $ldapPath = "LDAP://$ldapServer/$baseDN"
    
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher
    $directorySearcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry($ldapPath)
    $directorySearcher.Filter = "(&(objectClass=user)(cn=$userName))"  # Search for the user by CN
    $directorySearcher.PropertiesToLoad.Add("distinguishedName")  # Load the distinguished name

    try {
        # Find the user
        $searchResult = $directorySearcher.FindOne()

        if ($searchResult -ne $null) {
            $userDN = $searchResult.Properties["distinguishedname"][0]
            Write-Output "User found: $userDN"

            $newUserDN = "CN=$userName,$deletedUsersContainerDN"

            $userEntry = New-Object DirectoryServices.DirectoryEntry("LDAP://$userDN")

            $userEntry.MoveTo("LDAP://$ldapServer/$newUserDN")

            Write-Output "User $userName has been successfully moved to the DeletedUsers container."
        } else {
            Write-Output "User $userName not found in LDAP."
        }
    } catch {
        Write-Error "An error occurred while moving the user: $_"
    }
}

try {
    Move-LDAPUser -ldapServer $ldapServer -userName $userName
} catch {
    Write-Error "An error occurred: $_"
}
