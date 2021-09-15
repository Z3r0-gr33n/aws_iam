##Install Powershell AWS Module Tools
Install-Module -Name AWS.Tools.Installer -Force -Confirm:$False
Install-Module -Name AWS.Tools.Organizations -Confirm:$False -Force
Install-Module -Name AWS.Tools.SecurityToken -Force -Confirm:$False
Install-Module -Name AWS.Tools.IdentityManagement -Force -Confirm:$false

Set-AWSCredential -AccessKey  -SecretKey  -StoreAs MasterProfile
Initialize-AWSDefaultConfiguration -ProfileName MasterProfile -Region us-east-1

##Update Master Account Roles
##Check if folder is not empty
$dir = (Get-ChildItem ..\roles\master_roles\ | Measure-Object).Count

##If folder is empty then move to child accounts
if ( $dir -ne 0 ){

    ##Get the names of the local git roles in for master account
    $local_master_role_name = (Get-ChildItem ..\roles\master_roles\).BaseName

    ##Get the names of the currently deployed roles in master account 
    $aws_master_roles_name = (Get-IAMRoleList).RoleName

    ##Compare the names of the master roles deployed and master local git roles
    $local_master_role_name | foreach-object {
        if ($aws_master_roles_name -contains $_) {
            write-host "The role $_ will be updated" 
        } else {
            New-IAMRole -RoleName $_ -AssumeRolePolicyDocument (Get-Content -raw ../roles/master_roles/$_.json)
        }
    }
}

##Update Child Accounts Roles

##Get the list of child accounts in the org and remove the master account
$child_accounts = (Get-ORGAccountList | Where-Object Id -NotLike "550605119618").Id

##Conduct a foreach object for all accounts
$child_accounts | ForEach-Object {
    $acct = $_

    ##Create an arn for trust relationship
    $arn="arn:aws:iam::" + $acct + ":role/iam_admin_role"

    ##Store STS Credentials
    $creds = (Use-STSRole -RoleArn "$arn" -RoleSessionName "roleUpdate").Credentials

    ##Get the names of the local git roles for child accounts
    $local_child_role_name = (Get-ChildItem ..\roles\child_roles\).BaseName

    ##Get the names of the currently deployed roles in child accounts 
    $aws_child_roles_name = (Get-IAMRoleList -Credential $creds).RoleName 

    ##Compare the names of the child roles deployed and child local git roles
    $local_child_role_name | foreach-object {
        if ($aws_child_roles_name -contains $_) {
            write-host "Roles exists updating roles" 
            Update-IAMAssumeRolePolicy -RoleName $_ -PolicyDocument (Get-Content -raw ..\roles\child_roles\$_.json) -Credential $creds 
        } else {
            New-IAMRole -RoleName $_ -AssumeRolePolicyDocument (Get-Content -raw ..\roles\child_roles\$_.json) -Credential $creds
        } 
    }
}



