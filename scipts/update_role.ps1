##Update Master Account Roles
$local_master_role_name = (Get-ChildItem ../roles/master_roles.).BaseName

$aws_master_roles_name = aws iam list-roles | ConvertFrom-Json

$local_master_role_name | foreach-object {
    if ($aws_master_roles_name -contains $_) {
        write-host "Roles exists no action needed" 
    } else {
        aws iam create-role --role-name $_ --assume-role-policy-document file://../roles/master_roles/$_.json
    }
}

##Install Powershell AWS Module Tools
Install-Module -Name AWS.Tools.Installer -Force
Install-AWSToolsModule AWS.Tools.Organizations,AWS.Tools.IdentityManagement


##Update Child Accounts Roles
$child_accounts = ((aws organizations list-accounts | ConvertFrom-Json).Accounts | Where-Object Id -NotLike "550605119618").Id
$child_accounts | ForEach-Object {
    $acct = $_
    $arn="arn:aws:iam::" + $acct + ":role/iam_admin_role"
    aws sts assume-role --role-arn "$arn" --role-session-name role_udate_session --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]"
    aws sts get-caller-identity
    # $local_child_role_name = (Get-ChildItem ../roles/child_roles/).BaseName

    # $aws_child_roles_name = aws iam list-roles | ConvertFrom-Json
    
    # $local_child_role_name | foreach-object {
    #     if ($aws_child_roles_name -contains $_) {
    #         write-host "Roles exists no action needed" 
    #         aws iam update-role --role-name $_ --assume-role-policy-document file://../roles/child_roles/$_.json
    #     } else {
    #         aws iam create-role --role-name $_ --assume-role-policy-document file://../roles/child_roles/$_.json
    #     } 
    # }
}



