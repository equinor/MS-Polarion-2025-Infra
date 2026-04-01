# Author - Tore Melberg (Adjusted script received from Terje Gjøse)

# Test Credential
$myCredential = Get-AutomationPSCredential -Name 'WebHook'
$webhook = $myCredential.GetNetworkCredential().Password


# Certification Check
$UrlList = @(
    "aris.equinor.com"
    "arisqa.equinor.com"
    "disp.equinor.com"
    "disqa.equinor.com"
    "docmap.equinor.com"
    "docmapqa.equinor.com"
    "ncrequest.equinor.com"
    "ncrequestqa.equinor.com"
    "polarion.equinor.com"
    "polarion-qa.equinor.com"
    "msselfservices.equinor.com"
    "msselfservices.statoil.no"
    "imp.equinor.com"
    "actorsoverview.equinor.com"
    "mslinks.statoil.no"
)

# Trust the certificate presented by the server
[Net.ServicePointManager]::ServercertificateValidationCallback = { $true }
# Set Request timeout to 3000ms
$timeoutMilliseconds = 3000
$certCheckObject = @()
$checkFail = @()
foreach ($url in $UrlList) {
    $client = $sslStream = $null
    try {

        $cert = ""
        $client = [System.Net.Sockets.TcpClient]::new($url, 443)
        $sslStream = [System.Net.Security.SslStream]::new($client.GetStream(), $false, { $true }, $null)
        $sslStream.ReadTimeout = $timeoutMilliseconds
        $sslStream.WriteTimeout = $timeoutMilliseconds
        $sslStream.AuthenticateAsClient($url)
        $cert = $sslStream.RemoteCertificate
    }
    catch {
        Write-Output "Error: Invalid URL! => $url, exiting"
        $checkFail += $url
    }
    finally {
        if ($sslStream) { $sslStream.Close() }
        if ($clieDnt) { $client.Close() }
    }
    if ($cert) {
        try {
            $tempCert = @()
            $expirationDate = $cert.NotAfter.ToString('yyyy.MM.dd HH:mm:ss')
            $currentDate = $(Get-Date).ToString('yyyy.MM.dd HH:mm:ss')
            $daysLeft = ([Datetime]::ParseExact($expirationDate, 'yyyy.MM.dd HH:mm:ss', $null) - [Datetime]::ParseExact($currentDate, 'yyyy.MM.dd HH:mm:ss', $null)).Days
            
            # Changed from Json Output to standard PowerShell output
            # Generate Compressed JSON output
            $jsonResult = "{`"URL`": `"$($sslStream.TargetHostName)`", `"Expires`": `"$($expirationDate)`", `"DaysLeft`": $daysLeft, `"Issuer`": `"$($cert.Issuer.Split(',')[0].Replace('CN=', ''))`"}"
            Write-Output $jsonResult
           
            $tempCert += [PSCustomObject]@{
                URL      = $sslStream.TargetHostName
                Expires  = $expirationDate
                DaysLeft = $daysLeft
                Issuer   = $cert.Issuer.Split(',')[0].Replace('CN=', '')
                Status   = if ($DaysLeft -le 0) {
                    Write-Output "Expired"
                }
                elseif ($DaysLeft -ge 50) {
                    Write-Output "Valid"
                }
                else {
                    Write-Output "Expiring Soon"
                }
            }
            $certCheckObject += $tempCert            
        }
        catch {
            Write-Output "Error: Fetching of the certificate FAILED! => $url, exiting"
        }
        finally {
            if ($sslStream) { $sslStream.Close() }
            if ($client) { $client.Close() }
        }
    }
}
# $certCheckObject | ConvertTo-Json

# Send message to teams:

$BodyTemplate = @"
   {
       "@type": "MessageCard",
       "@context": "https://schema.org/extensions",
       "summary": "<b>Certificate Warning</b>",
       "themeColor": "D778D7",
       "title": "TitlePlaceHolder",
        "sections": [
           {
           
               "facts": [
                   {
                       "name": "Certificate:",
                       "value": "<b>URL</b>"
                   },
                   {
                       "name": "ExpiryDate:",
                       "value": "Expires"
                   },
                   {
                       "name": "DaysLeft:",
                       "value": "TimeSpan"
                   },
                   {
                       "name": "Issuer:",
                       "value": "IssuerPlaceHolder"
                   }
               ],
               "text": "CertificateText"
           }
       ]
   }
"@


# foreach ($item in $certCheckObject){

#     If ($item.DaysLeft -lt 0) {
#         $body = $BodyTemplate.Replace("URL","$($item.url)").Replace("Expires",$($item.expires)).Replace("TimeSpan","$($item.DaysLeft)").Replace("CertificateText","This certificate is expired!!").replace("IssuerPlaceHolder",$($item.Issuer)).Replace("TitlePlaceHolder","Certificate expired: $($item.url)")
#         Invoke-RestMethod -uri $webhook -Method Post -body $body -ContentType 'application/json'
#     }
#     elseif ($item.DaysLeft -lt 40) {
#         $body = $BodyTemplate.Replace("URL","$($item.url)").Replace("Expires","<p style='color:Tomato;'>$($item.expires)</p>").Replace("TimeSpan","$($item.DaysLeft)").Replace("CertificateText","This certificate will expire in the near future").replace("IssuerPlaceHolder",$($item.Issuer)).Replace("TitlePlaceHolder","Certificate is about to expire: $($item.url)")
#         Invoke-RestMethod -uri $webhook -Method Post -body $body -ContentType 'application/json'
#     }
       
# }


# HTML List





$Newtable = $certCheckObject | ConvertTo-Html -as Table -Fragment
Write-Output $Newtable

# <table><colgroup><col/><col/><col/><col/><col/></colgroup><tr><th>URL</th><th>Expires</th><th>DaysLeft</th><th>Issuer</th><th>ExpiredStatus</th></tr>

$table = $Newtable.Replace("<table><colgroup><col/><col/><col/><col/><col/></colgroup><tr><th>URL</th><th>Expires</th><th>DaysLeft</th><th>Issuer</th><th>ExpiredStatus</th></tr>", "<table bordercolor='black' border= '2'><thead><tr style = 'background-color : Teal; color: White'><th>URL</th><th>Expires</th><th>Issuer</th><th>ExpiredStatus</th></tr></thead><tbody>").Replace("</table>", "</tbody></table>").Replace("Expired", "<p style = 'color:Crimson;'>Expired</p>").Replace("Expiring Soon", "<p style = 'color:DarkOrange;'>Expiring Soon</p>")

Write-Output $table

# $HtmlBodyTemplate = @"
#     {
#         "@type": "MessageCard",
#         "@context": "https://schema.org/extensions",
#         "summary": "<b>Certificate Warning</b>",
#         "themeColor": "D778D7",
#         "title": "HTML Test",
#         "body": [
#             {
#                 "type": "TextBlock",
#                 "text": "$table" 
#             }
#         ] 
#     }
# "@

$HtmlBodyTemplate = @"
{
   "@type": "MessageCard",
   "@context": "http://schema.org/extensions",
   "themeColor": "0076D7",
   "summary": "Certificate Status",
   "sections": [
     {
       "startGroup": true,
       "text": "$table"
     }
   ]
 }
"@

Invoke-RestMethod -uri $webhook -Method Post -body $HtmlBodyTemplate -ContentType 'application/json'
