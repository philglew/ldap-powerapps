param (  
    [string]$ldapServer = "localhost:389",
    [string]$userName   # The CN of the user whose password will be reset
)

function Generate-RandomPassword {
    param (
        [int]$length = 12  # Password length (default 12 characters)
    )

    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count $length | ForEach-Object { [char]$_ })
    
    return $password
}

function Reset-LDAPUserPassword {
    param (
        [string]$ldapServer,
        [string]$userName,
        [string]$newPassword
    )

    $baseDN = "DC=LocalLDAP,DC=COM"
    
    $ldapPath = "LDAP://$ldapServer/$baseDN"
    
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher
    $directorySearcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry($ldapPath)
    $directorySearcher.Filter = "(&(objectClass=user)(cn=$userName))"  # Search for the user by CN

    try {
        $searchResult = $directorySearcher.FindOne()

        if ($searchResult -ne $null) {
            $userDN = $searchResult.Properties["distinguishedname"][0]
            Write-Output "User found: $userDN"

            $userEntry = New-Object DirectoryServices.DirectoryEntry("LDAP://$userDN")

            $userEntry.Invoke("SetPassword", $newPassword)
            $userEntry.CommitChanges()

            Write-Output "Password reset successfully for user: $userName"
            return $newPassword
        } else {
            Write-Output "User $userName not found in LDAP."
        }
    } catch {
        Write-Error "An error occurred while resetting the password: $_"
    }
}

$newPassword = Generate-RandomPassword -length 12

try {
    $resetPassword = Reset-LDAPUserPassword -ldapServer $ldapServer -userName $userName -newPassword $newPassword
    if ($resetPassword -ne $null) {
        Write-Output "The new password for user $userName is: $resetPassword"
    }
} catch {
    Write-Error "An error occurred: $_"
}
