$rg = @{
    Name = 'publicLB'
    Location = 'switzerland North'
}
New-AzResourceGroup @rg


$publicip = @{
    Name = 'myPublicIP'
    ResourceGroupName = 'publicLB'
    Location = 'switzerlandnorth'
    Sku = 'Standard'
    AllocationMethod = 'static'
    Zone = 1,2,3
}
New-AzPublicIpAddress @publicip



## Place public IP created in previous steps into variable. ##
$pip = @{
    Name = 'myPublicIP'
    ResourceGroupName = 'publicLB'
}
$publicIp = Get-AzPublicIpAddress @pip

## Create load balancer frontend configuration and place in variable. ##
$fip = @{
    Name = 'myFrontEnd'
    PublicIpAddress = $publicIp 
}
$feip = New-AzLoadBalancerFrontendIpConfig @fip

## Create backend address pool configuration and place in variable. ##
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name 'myBackEndPool'

## Create the health probe and place in variable. ##
$probe = @{
    Name = 'myHealthProbe'
    Protocol = 'tcp'
    Port = '80'
    IntervalInSeconds = '360'
    ProbeCount = '5'
}
$healthprobe = New-AzLoadBalancerProbeConfig @probe

## Create the load balancer rule and place in variable. ##
$lbrule = @{
    Name = 'myHTTPRule'
    Protocol = 'tcp'
    FrontendPort = '80'
    BackendPort = '80'
    IdleTimeoutInMinutes = '15'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
}
$rule = New-AzLoadBalancerRuleConfig @lbrule -EnableTcpReset -DisableOutboundSNAT

## Create the load balancer resource. ##
$loadbalancer = @{
    ResourceGroupName = 'publicLB'
    Name = 'myLoadBalancer'
    Location = 'switzerlandnorth'
    Sku = 'Standard'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
    LoadBalancingRule = $rule
    Probe = $healthprobe
}
New-AzLoadBalancer @loadbalancer





# Set the administrator and password for the VMs. ##
$cred = Get-Credential

# user:JSteiner PW: Jst155390.

## Place the virtual network into a variable. ##
$net = @{
    Name = 'myVNet'
    ResourceGroupName = 'publicLB'
}
$vnet = Get-AzVirtualNetwork @net

## Place the load balancer into a variable. ##
$lb = @{
    Name = 'myLoadBalancer'
    ResourceGroupName = 'publicLB'
}
$bepool = Get-AzLoadBalancer @lb  | Get-AzLoadBalancerBackendAddressPoolConfig

## Place the network security group into a variable. ##
$ns = @{
    Name = 'myNSG'
    ResourceGroupName = 'publicLB'
}
$nsg = Get-AzNetworkSecurityGroup @ns

## For loop with variable to create virtual machines for load balancer backend pool. ##
for ($i=1; $i -le 2; $i++)
{
    ## Command to create network interface for VMs ##
    $nic = @{
        Name = "myNicVM$i"
        ResourceGroupName = 'publicLB'
        Location = 'switzerlandnorth'
        Subnet = $vnet.Subnets[0]
        NetworkSecurityGroup = $nsg
        LoadBalancerBackendAddressPool = $bepool
    }
    $nicVM = New-AzNetworkInterface @nic

    ## Create a virtual machine configuration for VMs ##
    $vmsz = @{
        VMName = "myVM$i"
        VMSize = 'Standard_DS1_v2'  
    }
    $vmos = @{
        ComputerName = "myVM$i"
        Credential = $cred
    }
    $vmimage = @{
        PublisherName = 'MicrosoftWindowsServer'
        Offer = 'WindowsServer'
        Skus = '2019-Datacenter'
        Version = 'latest'    
    }
    $vmConfig = New-AzVMConfig @vmsz `
        | Set-AzVMOperatingSystem @vmos -Windows `
        | Set-AzVMSourceImage @vmimage `
        | Add-AzVMNetworkInterface -Id $nicVM.Id

    ## Create the virtual machine for VMs ##
    $vm = @{
        ResourceGroupName = 'publicLB'
        Location = 'switzerlandnorth'
        VM = $vmConfig
        Zone = "$i"
    }
    New-AzVM @vm -AsJob
}



## For loop with variable to install custom script extension on virtual machines. ##
for ($i=1; $i -le 2; $i++)
{
$ext = @{
    Publisher = 'Microsoft.Compute'
    ExtensionType = 'CustomScriptExtension'
    ExtensionName = 'IIS'
    ResourceGroupName = 'publicLB'
    VMName = "myVM$i"
    Location = 'switzerlandnorth'
    TypeHandlerVersion = '1.8'
    SettingString = '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}'
}
Set-AzVMExtension @ext -AsJob
}


$ip = @{
    ResourceGroupName = 'publicLB'
    Name = 'myPublicIP'
}  
Get-AzPublicIPAddress @ip | select IpAddress


##-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#keien berechtigungen wie erwartet:

# Create a credential object
#$cred = Get-Credential

# Define the path for the local HTML file and the destination on the VM
#$src = "C:\Users\i00205126\Desktop\index.html"
#$dst = "\\vmname\c$\inetpub\wwwroot\"

# Copy the file to the remote machine
#Copy-Item -Path $src -Destination $dst -ToSession (New-PSSession -ComputerName vmname -Credential $cred) -Force





#funktioniert nicht
## For loop with variable to install custom script extension on virtual machines. ##
#for ($i=1; $i -le 2; $i++)
#{
 # $ext = @{
  # Publisher = 'Microsoft.Compute'
   # ExtensionType = 'CustomScriptExtension'
    #ExtensionName = 'IIS'
    #ResourceGroupName = 'publicLB'
    #VMName = "myVM$i"
    #Location = 'switzerlandnorth'
    #TypeHandlerVersion = '1.8'
    #SettingString = '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.html\" -Value \"<!DOCTYPE html><html><head><title>Hello World</title></head><body><h1>Hello World!</h1><p>Computer Name: $($env:computername)</p></body></html>\""}'
#}
#Set-AzVMExtension @ext -AsJob
#}







## For loop with variable to run a command on virtual machines. ##
#for ($i=1; $i -le 2; $i++)
#{
 #   $vmName = "myVM$i"
  #  $ResourceGroupName = 'publicLB'
 #   $command = 'powershell Add-Content -Path "C:\inetpub\wwwroot\Default.html" -Value "<!DOCTYPE html><html><head><title>Hello World</title></head><body><h1>Hello World!</h1><p>Computer Name: $($env:computername)</p></body></html>"'
  #  Invoke-AzVMRunCommand -CommandId 'RunPowerShellScript' -ResourceGroupName $ResourceGroupName -Name $vmName -ScriptPath $command
#}


## For loop with variable to run a command on virtual machines. ##
#for ($i=1; $i -le 2; $i++)
#{
#    $vmName = "myVM$i"
#    $ResourceGroupName = 'publicLB'
#    $command = 'powershell Add-Content -Path \"C:\inetpub\wwwroot\Default.htm" -Value "$($env:computername) <br> <html><head><title>Hello World</title></head><body><h1>Hello World!</h1></body></html>"'
#    Invoke-AzVMRunCommand -CommandId 'RunPowerShellScript' -ResourceGroupName $ResourceGroupName -Name $vmName -ScriptPath $command
#}

##-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------