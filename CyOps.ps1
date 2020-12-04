## HOST-DISCOVERY

function Host-Discovery
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidatePattern("(?:[0-9]{1,3}\.){2}[0-9]{1,3}$")]
        [string]
        $Subnet,

        [Parameter(Position=1)]
        [ValidatePattern("(?:[0-9]{1,3}\.){2}[0-9]{1,3}$")]
        [string[]]
        $Exclude
     )

    Process
    {
        workflow pingit {
            param([string[]]$Targets)
            foreach -parallel -throttlelimit 128 ($item in $Targets) 
            {
                Test-Connection -ComputerName $item -Count 1 -ErrorAction SilentlyContinue
            }
    }

    $Targets = 0..255 | ForEach-Object {$Subnet + ".$_"}
    $Targets = $Targets | Where-Object {$_ -notin $Exclude}

    $Result = pingit $Targets
    foreach ($item in $Result) {
        $os = switch($item.ResponseTimeToLive) {
        {$_ -lt 65}      {"Linux"}
        {$_ -in 65..128} {"Windows"}
        Default          {"Unknown"}
        }
        [pscustomobject]@{Host=$item.address;OS=$os}
        }
    }
}

## PII-LOCATOR

function PII-Location
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string[]]
        $FilePath,

        [switch]
        $Recursive,

        [switch]
        $Email,

        [switch]
        $SSN,

        [Alias("RE")]
        [string[]]
        $RegularExpression
    )

    Process
    {
        if($Email) {$RegularExpression += "[\w\.=-]+@[\w\.-]+\.[\w]{2,3}"}
        if($SSN) {$RegularExpression += "\d{3}-\d{2}-\d{4}"}

        if($Recursive) {
            $Search = @(Get-ChildItem -Attributes !Directory -Path $FilePath -Recurse | Select-Object -ExpandProperty FullName)
            }
        else {
            $Search = @(Get-ChildItem -Attributes !Directory -Path $FilePath | Select-Object -ExpandProperty FullName)
            }
        Select-String -Path $Search -Pattern $RegularExpression -AllMatches | Select-Object Path, LineNumber -ExpandProperty Matches | export-csv -Path C:\Users\Public\notes_test.csv -Append -NoTypeInformation

        C:\Users\Public\notes_test.csv
        import-csv C:\Users\Public\notes_test.csv
        }
}

## FILE-DISCOVERY

function File-Discovery
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string[]]
        $FilePath,

        [string]
        $Extension,

        [switch]
        $Hidden
    )

       Process
        {
              
        if($Hidden) 
            {
            Get-ChildItem -Attributes !Directory -Path $FilePath -Force -Recurse -Include $Extension
            }
        else {
            Get-ChildItem -Attributes !Directory -Path $FilePath -Recurse -Include $Extension
             }
        }

}

### ACCOUNT-DISCOVERY

function Account-Discovery
{
    [CmdletBinding()]
    Param
    (
        [switch]
        $Group,

        [switch]
        $User
    )

       Process
        {
              
        if($Group) 
            {
            Get-LocalGroup > C:\Users\Public\LocalGroup_current.txt ##ENTER YOUR BASELINE PATHWAY HERE!
            Write-Host "Groups not identified on baseline: "
            Compare-Object -ReferenceObject (Get-Content -Path C:\Users\Public\LocalGroup_baseline.txt) -DifferenceObject (Get-Content -Path C:\Users\Public\LocalGroup_current.txt)
            }

        if($User)
            {
            Get-LocalUser > C:\Users\Public\LocalUser_current.txt ##ENTER YOUR BASELINE PATHWAY HERE!
            Write-Host "Users not identified on baseline: "
            Compare-Object -ReferenceObject (Get-Content -Path C:\Users\Public\LocalUser_baseline.txt) -DifferenceObject (Get-Content -Path C:\Users\Public\LocalUser_current.txt)
            }

                else
                { 
                Get-LocalUser | Select Name, LastLogon, PasswordLastSet
                }
         }
}

## NETWORK-PROCESS

function Network-Process
{
    gwmi win32_process | select ProcessID, ParentProcessID, ProcessName, ExecutablePath
}

##TEXTBOX


$server = $args


[array]$DropDownArray = "Host Discovery", "PII Location", "File Discovery", "Account Discovery", "Network Processes"

function Return-DropDown 
{
	$Choice = $DropDown.SelectedItem.ToString()
	$Form.Close()
        if ($choice -eq "Host Discovery") 
        {
                        Add-Type -AssemblyName System.Windows.Forms
                        Add-Type -AssemblyName System.Drawing

                        $form = New-Object System.Windows.Forms.Form
                        $form.Text = 'Host-Discovery Guide'
                        $form.Size = New-Object System.Drawing.Size(300,300)
                        $form.StartPosition = 'CenterScreen'
                        $form.Backcolor = 'Lavender'

                        $OKButton = New-Object System.Windows.Forms.Button
                        $OKButton.Location = New-Object System.Drawing.Point(105,200)
                        $OKButton.Size = New-Object System.Drawing.Size(75,23)
                        $OKButton.Text = 'OK'
                        $Okbutton.backcolor = 'white'
                        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                        $form.AcceptButton = $OKButton
                        $form.Controls.Add($OKButton)
                        $OKButton.Add_Click({$global:subnetIP=$textBox.Text;$global:excludeIP=$textBox_2.Text;$Form.Close()})

                        #Label 1
                        $label = New-Object System.Windows.Forms.Label
                        $label.Location = New-Object System.Drawing.Point(10,20)
                        $label.Size = New-Object System.Drawing.Size(280,50)
                        $label.Text = 'This script identifies hosts and OS types within the specified subnet. To get started, type in the subnet below (this program assumes a /24 network). For example, 10.0.0:  '
                        $form.Controls.Add($label)

                        $textBox = New-Object System.Windows.Forms.TextBox
                        $textBox.Location = New-Object System.Drawing.Point(10,70)
                        $textBox.Size = New-Object System.Drawing.Size(260,20)
                        $form.Controls.Add($textBox)

                        $label_2 = New-Object System.Windows.Forms.Label
                        $label_2.Location = New-Object System.Drawing.Point(10,120)
                        $label_2.Size = New-Object System.Drawing.Size(280,40)
                        $label_2.Text = 'To exclude IPs, type the IP address. For multiple IP addresses, type the IP followed by a comma (10.0.0.5, 10.0.0.27): '
                        $form.Controls.Add($label_2)

                        $textBox_2 = New-Object System.Windows.Forms.TextBox
                        $textBox_2.Location = New-Object System.Drawing.Point(10,160)
                        $textBox_2.Size = New-Object System.Drawing.Size(260,20)
                        $form.Controls.Add($textBox_2)

                        $form.Topmost = $true

                        $form.Add_Shown({$textBox.Select()})
                        $result = $form.ShowDialog()

                        ########
                        Add-Type -AssemblyName System.Windows.Forms
                        Add-Type -AssemblyName System.Drawing

                        $form = New-Object System.Windows.Forms.Form
                        $form.Text = 'Host-Discovery Guide'
                        $form.Size = New-Object System.Drawing.Size(300,300)
                        $form.StartPosition = 'CenterScreen'
                        $form.Backcolor = 'Lavender'

                        $OKButton = New-Object System.Windows.Forms.Button
                        $OKButton.Location = New-Object System.Drawing.Point(105,200)
                        $OKButton.Size = New-Object System.Drawing.Size(75,23)
                        $OKButton.Text = 'OK'
                        $Okbutton.backcolor = 'white'
                        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                        $form.AcceptButton = $OKButton
                        $form.Controls.Add($OKButton)
                        

                        #Label 1
                        $label = New-Object System.Windows.Forms.Label
                        $label.Location = New-Object System.Drawing.Point(10,20)
                        $label.Size = New-Object System.Drawing.Size(280,50)
                        $label.Text = 'To identify hosts on the specfied subnet, right-click > select all > copy and paste the code below into the command line: '
                        $form.Controls.Add($label)

                        $textBox = New-Object System.Windows.Forms.TextBox
                        $textBox.Location = New-Object System.Drawing.Point(10,70)
                        $textBox.Size = New-Object System.Drawing.Size(260,20)
                        $textBox.Text = "Host-Discovery -Subnet $($subnetIP)"
                        $form.Controls.Add($textBox)

                        $label_2 = New-Object System.Windows.Forms.Label
                        $label_2.Location = New-Object System.Drawing.Point(10,120)
                        $label_2.Size = New-Object System.Drawing.Size(280,40)
                        $label_2.Text = 'To identify hosts on the specfied subnet AND exclude the specified IP address(es), right-click > select all > copy and paste the code below into the command line: '
                        $form.Controls.Add($label_2)

                        $textBox_2 = New-Object System.Windows.Forms.TextBox
                        $textBox_2.Location = New-Object System.Drawing.Point(10,160)
                        $textBox_2.Size = New-Object System.Drawing.Size(260,20)
                        $textBox_2.Text = "Host-Discovery -Subnet $($subnetIP) -Exclude $($excludeIP)"
                        $form.Controls.Add($textBox_2)

                        $form.Topmost = $true

                        $form.Add_Shown({$textBox.Select()})
                        $result = $form.ShowDialog()
        }
        
        elseif ($choice -eq "PII Location") 
        {
                        Add-Type -AssemblyName System.Windows.Forms
                        Add-Type -AssemblyName System.Drawing

                        $form = New-Object System.Windows.Forms.Form
                        $form.Text = 'PII-Location Guide'
                        $form.Size = New-Object System.Drawing.Size(300,300)
                        $form.StartPosition = 'CenterScreen'
                        $form.Backcolor = 'Lavender'

                        $OKButton = New-Object System.Windows.Forms.Button
                        $OKButton.Location = New-Object System.Drawing.Point(105,200)
                        $OKButton.Size = New-Object System.Drawing.Size(75,23)
                        $OKButton.Text = 'OK'
                        $Okbutton.backcolor = 'white'
                        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                        $form.AcceptButton = $OKButton
                        $form.Controls.Add($OKButton)
                        $OKButton.Add_Click({$global:filePath=$textBox.Text;$Form.Close()})

                        #Label 1
                        $label = New-Object System.Windows.Forms.Label
                        $label.Location = New-Object System.Drawing.Point(10,20)
                        $label.Size = New-Object System.Drawing.Size(280,40)
                        $label.Text = 'This script identifies PII such as email addresses and social security numbers. To get started, type in the filepath and click OK. '
                        $form.Controls.Add($label)

                        $textBox = New-Object System.Windows.Forms.TextBox
                        $textBox.Location = New-Object System.Drawing.Point(10,80)
                        $textBox.Size = New-Object System.Drawing.Size(260,20)
                        $form.Controls.Add($textBox)

                        $form.Topmost = $true

                        $form.Add_Shown({$textBox.Select()})
                        $result = $form.ShowDialog()


                        ###########

                        Add-Type -AssemblyName System.Windows.Forms
                        Add-Type -AssemblyName System.Drawing

                        $form = New-Object System.Windows.Forms.Form
                        $form.Text = 'PII-Location Guide'
                        $form.Size = New-Object System.Drawing.Size(320,450)
                        $form.StartPosition = 'CenterScreen'
                        $form.Backcolor = 'Lavender'

                        $OKButton = New-Object System.Windows.Forms.Button
                        $OKButton.Location = New-Object System.Drawing.Point(115,380)
                        $OKButton.Size = New-Object System.Drawing.Size(75,23)
                        $OKButton.Text = 'OK'
                        $Okbutton.backcolor = 'white'
                        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                        $form.AcceptButton = $OKButton
                        $form.Controls.Add($OKButton)

                        #Label 1
                        $label = New-Object System.Windows.Forms.Label
                        $label.Location = New-Object System.Drawing.Point(10,20)
                        $label.Size = New-Object System.Drawing.Size(280,40)
                        $label.Text = 'To search for email addresses recursively, right-click > select all > copy and paste the code below into the command line: '
                        $form.Controls.Add($label)

                        $textBox = New-Object System.Windows.Forms.TextBox
                        $textBox.Location = New-Object System.Drawing.Point(10,60)
                        $textBox.Size = New-Object System.Drawing.Size(260,20)
                        $textBox.Text = "PII-Location -Email -Recursive -FilePath $($filePath)"
                        $form.Controls.Add($textBox)

                        #Label 2
                        $label_2 = New-Object System.Windows.Forms.Label
                        $label_2.Location = New-Object System.Drawing.Point(10,100)
                        $label_2.Size = New-Object System.Drawing.Size(280,40)
                        $label_2.Text = 'To search for email addresses non-recursively, right-click > select all > copy and paste the code below into the command line:'
                        $form.Controls.Add($label_2)

                        $textBox_2 = New-Object System.Windows.Forms.TextBox
                        $textBox_2.Location = New-Object System.Drawing.Point(10,140)
                        $textBox_2.Size = New-Object System.Drawing.Size(260,20)
                        $textBox_2.Text = "PII-Location -Email -FilePath $($filePath)"
                        $form.Controls.Add($textBox_2)

                        #Label 3
                        $label_3 = New-Object System.Windows.Forms.Label
                        $label_3.Location = New-Object System.Drawing.Point(10,180)
                        $label_3.Size = New-Object System.Drawing.Size(280,40)
                        $label_3.Text = 'To search for SSN recursively, right-click > select all > copy and paste the code below into the command line:'
                        $form.Controls.Add($label_3)

                        $textBox_3 = New-Object System.Windows.Forms.TextBox
                        $textBox_3.Location = New-Object System.Drawing.Point(10,220)
                        $textBox_3.Size = New-Object System.Drawing.Size(260,20)
                        $textBox_3.Text = "PII-Location -SSN -Recursive -FilePath $($filePath)"
                        $form.Controls.Add($textBox_3)

                        #Label 4
                        $label_4 = New-Object System.Windows.Forms.Label
                        $label_4.Location = New-Object System.Drawing.Point(10,260)
                        $label_4.Size = New-Object System.Drawing.Size(280,40)
                        $label_4.Text = 'To search for SSN non-recursively, right-click > select all > copy and paste the code below into the command line:'
                        $form.Controls.Add($label_4)

                        $textBox_4 = New-Object System.Windows.Forms.TextBox
                        $textBox_4.Location = New-Object System.Drawing.Point(10,300)
                        $textBox_4.Size = New-Object System.Drawing.Size(260,20)
                        $textBox_4.Text = "PII-Location -SSN  -FilePath $($filePath)"
                        $form.Controls.Add($textBox_4)

                        #Label 5
                        $label_5 = New-Object System.Windows.Forms.Label
                        $label_5.Location = New-Object System.Drawing.Point(10,340)
                        $label_5.Size = New-Object System.Drawing.Size(280,40)
                        $label_5.Text = 'After you copy and paste the code into the command line, hit the enter key.'
                        $form.Controls.Add($label_5)

                        $form.Topmost = $true

                        $form.Add_Shown({$textBox.Select()})
                        $result = $form.ShowDialog()



        }

        elseif ($choice -eq "File Discovery") 
        {
                        Add-Type -AssemblyName System.Windows.Forms
                        Add-Type -AssemblyName System.Drawing

                        $form = New-Object System.Windows.Forms.Form
                        $form.Text = 'File-Discovery Guide'
                        $form.Size = New-Object System.Drawing.Size(300,300)
                        $form.StartPosition = 'CenterScreen'
                        $form.Backcolor = 'Lavender'

                        $OKButton = New-Object System.Windows.Forms.Button
                        $OKButton.Location = New-Object System.Drawing.Point(105,200)
                        $OKButton.Size = New-Object System.Drawing.Size(75,23)
                        $OKButton.Text = 'OK'
                        $Okbutton.backcolor = 'white'
                        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                        $form.AcceptButton = $OKButton
                        $form.Controls.Add($OKButton)
                        $OKButton.Add_Click({$global:FilePath=$textBox.Text;$global:extension=$textBox_2.Text;$Form.Close()})

                        #Label 1
                        $label = New-Object System.Windows.Forms.Label
                        $label.Location = New-Object System.Drawing.Point(10,20)
                        $label.Size = New-Object System.Drawing.Size(280,40)
                        $label.Text = 'This script identifies specified file extension types. To get started, type in the filepath below:  '
                        $form.Controls.Add($label)

                        $textBox = New-Object System.Windows.Forms.TextBox
                        $textBox.Location = New-Object System.Drawing.Point(10,60)
                        $textBox.Size = New-Object System.Drawing.Size(260,20)
                        $form.Controls.Add($textBox)

                        $label_2 = New-Object System.Windows.Forms.Label
                        $label_2.Location = New-Object System.Drawing.Point(10,100)
                        $label_2.Size = New-Object System.Drawing.Size(280,40)
                        $label_2.Text = 'Type in a file extension (.exe, .txt, .bat, etc.) and click OK.'
                        $form.Controls.Add($label_2)

                        $textBox_2 = New-Object System.Windows.Forms.TextBox
                        $textBox_2.Location = New-Object System.Drawing.Point(10,140)
                        $textBox_2.Size = New-Object System.Drawing.Size(260,20)
                        $form.Controls.Add($textBox_2)

                        $form.Topmost = $true

                        $form.Add_Shown({$textBox.Select()})
                        $result = $form.ShowDialog()


                        ###########

                        Add-Type -AssemblyName System.Windows.Forms
                        Add-Type -AssemblyName System.Drawing

                        $form = New-Object System.Windows.Forms.Form
                        $form.Text = 'File-Discovery Guide'
                        $form.Size = New-Object System.Drawing.Size(320,300)
                        $form.StartPosition = 'CenterScreen'
                        $form.Backcolor = 'Lavender'

                        $OKButton = New-Object System.Windows.Forms.Button
                        $OKButton.Location = New-Object System.Drawing.Point(115,220)
                        $OKButton.Size = New-Object System.Drawing.Size(75,23)
                        $OKButton.Text = 'OK'
                        $Okbutton.backcolor = 'white'
                        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                        $form.AcceptButton = $OKButton
                        $form.Controls.Add($OKButton)

                        #Label 1
                        $label = New-Object System.Windows.Forms.Label
                        $label.Location = New-Object System.Drawing.Point(10,20)
                        $label.Size = New-Object System.Drawing.Size(280,40)
                        $label.Text = 'To search for the specified extension, right-click > select all > copy and paste the code below into the command line: '
                        $form.Controls.Add($label)

                        $textBox = New-Object System.Windows.Forms.TextBox
                        $textBox.Location = New-Object System.Drawing.Point(10,60)
                        $textBox.Size = New-Object System.Drawing.Size(260,20)
                        $textBox.Text = "File-Discovery -FilePath $($FilePath) -Extension *$($extension)"
                        $form.Controls.Add($textBox)

                        #Label 2
                        $label_2 = New-Object System.Windows.Forms.Label
                        $label_2.Location = New-Object System.Drawing.Point(10,100)
                        $label_2.Size = New-Object System.Drawing.Size(280,40)
                        $label_2.Text = 'To search for HIDDEN specified extensions, right-click > select all > copy and paste the code below into the command line: '
                        $form.Controls.Add($label_2)

                        $textBox_2 = New-Object System.Windows.Forms.TextBox
                        $textBox_2.Location = New-Object System.Drawing.Point(10,140)
                        $textBox_2.Size = New-Object System.Drawing.Size(260,20)
                        $textBox_2.Text = "File-Discovery -FilePath $($FilePath) -Extension *$($extension) -Hidden"
                        $form.Controls.Add($textBox_2)


                        #Label 5
                        $label_5 = New-Object System.Windows.Forms.Label
                        $label_5.Location = New-Object System.Drawing.Point(10,180)
                        $label_5.Size = New-Object System.Drawing.Size(280,40)
                        $label_5.Text = 'After you copy and paste the code into the command line, hit the enter key.'
                        $form.Controls.Add($label_5)

                        $form.Topmost = $true

                        $form.Add_Shown({$textBox.Select()})
                        $result = $form.ShowDialog()
        }    	
        
        elseif ($choice -eq "Account Discovery") 
        {
                        Add-Type -AssemblyName System.Windows.Forms
                        Add-Type -AssemblyName System.Drawing

                        $form = New-Object System.Windows.Forms.Form
                        $form.Text = 'PII-Location Guide'
                        $form.Size = New-Object System.Drawing.Size(320,450)
                        $form.StartPosition = 'CenterScreen'
                        $form.Backcolor = 'Lavender'

                        $OKButton = New-Object System.Windows.Forms.Button
                        $OKButton.Location = New-Object System.Drawing.Point(115,380)
                        $OKButton.Size = New-Object System.Drawing.Size(75,23)
                        $OKButton.Text = 'OK'
                        $Okbutton.backcolor = 'white'
                        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                        $form.AcceptButton = $OKButton
                        $form.Controls.Add($OKButton)

                        #Label 1
                        $label = New-Object System.Windows.Forms.Label
                        $label.Location = New-Object System.Drawing.Point(10,20)
                        $label.Size = New-Object System.Drawing.Size(280,50)
                        $label.Text = 'This script identifies users and groups not identified on the system baseline. If no parameters are selected, basic user information will be shown.'
                        $form.Controls.Add($label)


                        #Label 2
                        $label_2 = New-Object System.Windows.Forms.Label
                        $label_2.Location = New-Object System.Drawing.Point(10,100)
                        $label_2.Size = New-Object System.Drawing.Size(280,40)
                        $label_2.Text = 'To identify users not on the baseline, right-click > select all > copy and paste the code below into the command line: '
                        $form.Controls.Add($label_2)

                        $textBox_2 = New-Object System.Windows.Forms.TextBox
                        $textBox_2.Location = New-Object System.Drawing.Point(10,140)
                        $textBox_2.Size = New-Object System.Drawing.Size(260,20)
                        $textBox_2.Text = "Account-Discovery -User"
                        $form.Controls.Add($textBox_2)

                        #Label 3
                        $label_3 = New-Object System.Windows.Forms.Label
                        $label_3.Location = New-Object System.Drawing.Point(10,180)
                        $label_3.Size = New-Object System.Drawing.Size(280,40)
                        $label_3.Text = 'To identify groups not on the baseline, right-click > select all > copy and paste the code below into the command line: '
                        $form.Controls.Add($label_3)

                        $textBox_3 = New-Object System.Windows.Forms.TextBox
                        $textBox_3.Location = New-Object System.Drawing.Point(10,220)
                        $textBox_3.Size = New-Object System.Drawing.Size(260,20)
                        $textBox_3.Text = "Account-Discovery -Group"
                        $form.Controls.Add($textBox_3)

                        #Label 4
                        $label_4 = New-Object System.Windows.Forms.Label
                        $label_4.Location = New-Object System.Drawing.Point(10,260)
                        $label_4.Size = New-Object System.Drawing.Size(280,40)
                        $label_4.Text = 'If no parameters are selected, simply right-click > select all > copy and paste the code below into the command line'
                        $form.Controls.Add($label_4)

                        $textBox_4 = New-Object System.Windows.Forms.TextBox
                        $textBox_4.Location = New-Object System.Drawing.Point(10,300)
                        $textBox_4.Size = New-Object System.Drawing.Size(260,20)
                        $textBox_4.Text = "Account-Discovery"
                        $form.Controls.Add($textBox_4)

                        #Label 5
                        $label_5 = New-Object System.Windows.Forms.Label
                        $label_5.Location = New-Object System.Drawing.Point(10,340)
                        $label_5.Size = New-Object System.Drawing.Size(280,40)
                        $label_5.Text = 'After you copy and paste the code into the command line, hit the enter key.'
                        $form.Controls.Add($label_5)

                        $form.Topmost = $true

                        $form.Add_Shown({$textBox.Select()})
                        $result = $form.ShowDialog()

        }  
        
        elseif ($choice -eq "Network Processes") 
        {
            Network-Process | Out-Default
        }

}

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$Form = New-Object System.Windows.Forms.Form

$Form.width = 400
$Form.height = 150
$Form.Text = "Cyber Operations Repository"


$DropDown = new-object System.Windows.Forms.ComboBox
$DropDown.Location = new-object System.Drawing.Size(130,20)
$DropDown.Size = new-object System.Drawing.Size(130,30)


ForEach ($Item in $DropDownArray) {
	$DropDown.Items.Add($Item)
}

$Form.Controls.Add($DropDown)
$form.StartPosition = 'CenterScreen'
$Form.Backcolor = 'SlateGray'

$DropDownLabel = new-object System.Windows.Forms.Label
$DropDownLabel.Location = new-object System.Drawing.Size(10,10)
$DropDownLabel.size = new-object System.Drawing.Size(100,20)
$DropDownLabel.Text = $args
$args = $server
$Form.Controls.Add($DropDownLabel)

$Button = new-object System.Windows.Forms.Button
$Button.Location = new-object System.Drawing.Size(143,60)
$Button.Size = new-object System.Drawing.Size(100,20)
$Button.Backcolor = 'White'
$Button.Text = "OK"
$Button.Add_Click({Return-DropDown})
$form.Controls.Add($Button)


$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()
$Form.Close()
