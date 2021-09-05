export CHILD_ACCOUNTS="aws organizations list-accounts"
$child_accounts | ForEach-Object {
    $acct = $_
    $arn="arn:aws:iam::" + $acct + ":role/iam_admin_role"
    aws sts assume-role --role-arn "$arn" --role-session-name role_udate_session
    $local_child_role_name = (Get-ChildItem ../roles/child_roles/).BaseName

    $aws_child_roles_name = aws iam list-roles | ConvertFrom-Json
    
    $local_child_role_name | foreach-object {
        if ($aws_child_roles_name -contains $_) {
            write-host "Roles exists no action needed" 
            aws iam update-role --role-name $_ --assume-role-policy-document file://../roles/child_roles/$_.json
        } else {
            aws iam create-role --role-name $_ --assume-role-policy-document file://../roles/child_roles/$_.json
        } 
    }
}

aws sts assume-role --role-arn "arn:aws:iam::055202506244:role/iam_admin_role" --role-session-name AWSCLI-Session
