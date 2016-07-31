[CmdletBinding()]
param(
    [string[]]
    [Parameter(Position=0)]
    $Groups = @('domain admins','schema admins','enterprise admins'),

    [string[]]
    [Parameter(Mandatory=$true, Position=1)]
    $Members
)

$Groups | ForEach-Object{
    Add-ADGroupMember -Identity $_ -Members $Members
}