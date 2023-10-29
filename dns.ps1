<#
    DNS Changer
    An Easy-to-Use PowerShell Script to Change DNS in Windows
#>
param (
    # Operation (1: Status, 2: On, 3: Off, 4: isOn)
    [Parameter(Mandatory = $false, Position = 0)]
    [int]$op = 0,

    # DNS Server 1
    [Parameter(Position = 1)]
    [string]$s1 = "178.22.122.100",

    # DNS Server 2
    [Parameter(Position = 2)]
    [string]$s2 = "185.51.200.2"
)

# Check privilege
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`" `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}

function Change-Dns {
    param (
        # Operation (1: Status, 2: On, 3: Off, 4: isOn)
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$op,

        # DNS Server 1
        [Parameter(Position = 1)]
        [string]$s1,

        # DNS Server 2
        [Parameter(Position = 2)]
        [string]$s2
    )

    $interfaces = Get-NetIPInterface |
    Where-Object {
        $_.ConnectionState -eq "Connected" -and
        $_.InterfaceAlias -notlike "Loopback*" -and
        $_.AddressFamily -eq "IPv4" -and
        ($_.InterfaceAlias -like "Wi-Fi*" -or $_.InterfaceAlias -like "Ethernet*")
    }

    foreach ($itf in $interfaces) {
        $dns = $itf | Get-DnsClientServerAddress
        $dns1 = $dns.ServerAddresses[0]
        $dns2 = $dns.ServerAddresses[1]

        if ($op -eq 1) {
            Write-Output "DNS Servers for $($itf.ifIndex) $($itf.InterfaceAlias) :"
            Write-Output $dns.ServerAddresses
            Write-Output ""
        }

        elseif ($op -eq 2) {
            $dns1 = $s1
            $dns2 = $s2
            $itf | Set-DnsClientServerAddress -ServerAddresses $dns1, $dns2
            [Environment]::SetEnvironmentVariable("GER_DNS1", $dns1, [System.EnvironmentVariableTarget]::User)
            [Environment]::SetEnvironmentVariable("GER_DNS2", $dns2, [System.EnvironmentVariableTarget]::User)
        }

        elseif ($op -eq 3) {
            $itf | Set-DnsClientServerAddress -ResetServerAddresses
        }

        elseif ($op -eq 4) {
            if ($dns1 -ne $s1 -or $dns2 -ne $s2) {
                return $false
            }
        }
    }

    if ($op -eq 2 -or $op -eq 3) {
        Clear-DnsClientCache
    }

    if ($op -eq 4) {
        return $true
    }
}

if ($op -gt 0) {
    Change-Dns $op $s1 $s2
}

elseif ($op -eq -1) {
    while ($true) {
        Change-Dns 1
        $uop = Read-Host -Prompt "Operation (1: Status, 2: On, 3: Off)"
        if ($uop -lt 1 -or $uop -gt 3) {
            break
        }
        if ($uop -ne 1) {
            Change-Dns $uop $s1 $s2
        }
        Write-Output "****************************************"
        Write-Output ""
    }
}

elseif ($op -eq 0) {

    Add-Type -AssemblyName System.Windows.Forms

    # Create a form
    $form = [System.Windows.Forms.Form]::new()
    $form.Text = "DNS Changer"
    $form.Size = [System.Drawing.Size]::new(300, 250)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $true

    # Create a TableLayoutPanel
    $layout = [System.Windows.Forms.TableLayoutPanel]::new()
    $layout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $layout.ColumnCount = 1
    $layout.Padding = 15
    $form.Controls.Add($layout)

    # Create the labels
    $label1 = [System.Windows.Forms.Label]::new()
    $label1.Text = "DNS 1:"

    $label2 = [System.Windows.Forms.Label]::new()
    $label2.Text = "DNS 2:"

    # Create two input boxes
    $textBox1 = [System.Windows.Forms.TextBox]::new()
    $textBox1.BorderStyle = "FixedSingle"
    $textBox1.BackColor = [System.Drawing.Color]::White
    $textBox1.Dock = [System.Windows.Forms.DockStyle]::Fill
    $textBox1.Margin = [System.Windows.Forms.Padding]::new(0, 0, 0, 15)
    $textBox1.Font = [System.Drawing.Font]::new("Consolas", 12)

    $textBox2 = [System.Windows.Forms.TextBox]::new()
    $textBox2.BorderStyle = $textBox1.BorderStyle
    $textBox2.BackColor = $textBox1.BackColor
    $textBox2.Dock = $textBox1.Dock
    $textBox2.Margin = $textBox1.Margin
    $textBox2.Font = $textBox1.Font

    # Create a button
    $button = [System.Windows.Forms.Button]::new()
    $button.Dock = [System.Windows.Forms.DockStyle]::Fill
    $button.Margin = [System.Windows.Forms.Padding]::new(50, 0, 50, 0)
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 0

    # Add controls to the TableLayoutPanel
    $layout.Controls.Add($label1)
    $layout.Controls.Add($textBox1)
    $layout.Controls.Add($label2)
    $layout.Controls.Add($textBox2)
    $layout.Controls.Add($button)

    # Initial State
    $DNS1 = [Environment]::GetEnvironmentVariable("GER_DNS1", [System.EnvironmentVariableTarget]::User)
    $DNS2 = [Environment]::GetEnvironmentVariable("GER_DNS2", [System.EnvironmentVariableTarget]::User)
    if ($DNS1 -eq $null) {
        $DNS1 = $s1
    }
    if ($DNS2 -eq $null) {
        $DNS2 = $s2
    }
    $textBox1.Text = $DNS1
    $textBox2.Text = $DNS2
    $isOn = Change-Dns 4 $DNS1 $DNS2
    if ($isOn) {
        $button.BackColor = [System.Drawing.Color]::LightGreen
        $button.Text = "ON"
        $textBox1.Enabled = $false
        $textBox2.Enabled = $false
    }
    else {
        $button.BackColor = [System.Drawing.Color]::Silver
        $button.Text = "OFF"
        $textBox1.Enabled = $true
        $textBox2.Enabled = $true
    }

    # Define the button's click event
    $button.Add_Click({
            $ip1 = $textBox1.Text
            $ip2 = $textBox2.Text

            if ($ip1 -eq "") {
                $ip1 = $s1
                $textBox1.Text = $ip1
            }
            if ($ip2 -eq "") {
                $ip2 = $s2
                $textBox2.Text = $ip2
            }

            # Validate the IPv4 addresses
            $validIP1 = [System.Net.IPAddress]::TryParse($ip1, [ref]$null)
            $validIP2 = [System.Net.IPAddress]::TryParse($ip2, [ref]$null)

            if (-not $validIP1) {
                [System.Windows.Forms.MessageBox]::Show("DNS Address 1 is invalid.", "Validation Error", "OK", "Error")
            }
            elseif (-not $validIP2) {
                [System.Windows.Forms.MessageBox]::Show("DNS Address 2 is invalid.", "Validation Error", "OK", "Error")
            }
            else {
                # Perform some action with the valid input values
                if ($isOn) {
                    Change-Dns 3 $ip1 $ip2
                }
                else {
                    Change-Dns 2 $ip1 $ip2
                }

                $isOn = Change-Dns 4 $DNS1 $DNS2

                if ($isOn) {
                    $button.BackColor = [System.Drawing.Color]::LightGreen
                    $button.Text = "ON"
                    $textBox1.Enabled = $false
                    $textBox2.Enabled = $false
                }
                else {
                    $button.BackColor = [System.Drawing.Color]::Silver
                    $button.Text = "OFF"
                    $textBox1.Enabled = $true
                    $textBox2.Enabled = $true
                }
            }
        })

    # Show the form
    $form.ShowDialog() | Out-Null

}