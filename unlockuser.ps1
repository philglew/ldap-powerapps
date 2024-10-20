param (  
    [string]$ldapServer = "localhost:389",
    [string]$userName   # The CN of the user to be unlocked
)

function Unlock-LDAPUser {
    param (
        [string]$ldapServer,
        [string]$userName
    )

    $baseDN = "DC=LocalLDAP,DC=COM"
    
    $ldapPath = "LDAP://$ldapServer/$baseDN"
    
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher
    $directorySearcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry($ldapPath)
    $directorySearcher.Filter = "(&(objectClass=user)(cn=$userName))"  # Search for the user by CN
    $directorySearcher.PropertiesToLoad.Add("lockoutTime")  # Load the lockoutTime attribute

    try {
        # Find the user
        $searchResult = $directorySearcher.FindOne()

        if ($searchResult -ne $null) {
            $userDN = $searchResult.Properties["distinguishedname"][0]
            Write-Output "User found: $userDN"

            $userEntry = New-Object DirectoryServices.DirectoryEntry("LDAP://$userDN")

            if ($userEntry.Properties["lockoutTime"].Value -gt 0) {
                # Reset the lockoutTime attribute to 0 to unlock the user
                $userEntry.Properties["lockoutTime"].Value = 0
                $userEntry.CommitChanges()

                Write-Output "User $userName has been successfully unlocked."
            } else {
                Write-Output "User $userName is not locked out."
            }
        } else {
            Write-Output "User $userName not found in LDAP."
        }
    } catch {
        Write-Error "An error occurred while unlocking the user: $_"
    }
}

try {
    Unlock-LDAPUser -ldapServer $ldapServer -userName $userName
} catch {
    Write-Error "An error occurred: $_"
}
