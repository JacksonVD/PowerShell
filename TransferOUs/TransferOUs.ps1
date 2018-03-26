$Data = Import-CSV .\Data.CSV
$PasswordServer = ""
foreach ($Record in $Data)
{

    ldifde -s $Record.SourceDC -f ACLS_$($Record.OU).txt -d "OU=$($Record.OU),DC=$($Record.SourceDomain.Replace(".",",DC="))" -r "(objectcategory=organizationalUnit)" -l "objectClass,distinguishedName,name,ntSecurityDescriptor" -c "DC=$($Record.SourceDomain.Replace(".",",DC="))" "DC=$($Record.TargetDomain.Replace(".",",DC="))"
    ldifde -i -f ACLS_$($Record.OU).txt
    
    $u = Get-ADObject -Server $Record.SourceDC -LDAPFilter "(objectClass=user)" -searchbase "OU=$($Record.OU),DC=$($Record.SourceDomain.Replace(".",",DC="))"
    $g = Get-ADObject -Server $Record.SourceDC -LDAPFilter "(objectClass=group)" -searchbase "OU=$($Record.OU),DC=$($Record.SourceDomain.Replace(".",",DC="))"
    $c = Get-ADObject -Server $Record.SourceDC -LDAPFilter "(objectClass=computer)" -searchbase "OU=$($Record.OU),DC=$($Record.SourceDomain.Replace(".",",DC="))"

    foreach ($UserRecord in $u)
    {
        $name = Get-ADUser -Server $Record.SourceDC -SearchBase "$($UserRecord.DistinguishedName)" -Filter * | select sAMAccountName
        admt user /n "$($name.sAMAccountName)" /sd:$($Record.SourceDomain) /td:$($Record.TargetDomain) /to:"$($Record.OU)" /mss:yes /uur:yes /umo:yes /fgm:yes /co:ignore /po:copy /ps:"$($PasswordServer)"
        Get-ADUser -Server $Record.TargetDC -SearchBase "$($UserRecord.DistinguishedName)" -Filter {pwdlastset -eq 0} | Set-ADUser -changepasswordatlogon $false
    }

    foreach ($GroupRecord in $g)
    {
        admt group /n "$($GroupRecord.Name)" /sd:$($Record.SourceDomain) /td:$($Record.TargetDomain) /to:"$($Record.OU)" /mss:yes /uur:yes /umo:yes /fgm:yes /co:ignore
    }

    foreach ($ComputerRecord in $c)
    {
        admt computer /n "$($ComputerRecord.Name)" /sd:$($Record.SourceDomain) /td:$($Record.TargetDomain) /to:"$($Record.OU)" /tot:add /tff:yes /tlg:yes /tps:yes /trg:yes /tss:yes /tur:yes /co:ignore /rdl:1
    }

}