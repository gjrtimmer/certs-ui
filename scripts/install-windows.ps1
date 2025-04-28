

Write-Output "Downloading internal CA certificate..."
$certUrl = "https://certs.k3s/certs/ca-root.pem"
$certPath = "$env:TEMP\internal-ca.cer"
Invoke-WebRequest -Uri $certUrl -OutFile $certPath

Write-Output "Installing certificate into LocalMachine Root store..."
Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\Root

Write-Output "Internal CA installed successfully."
