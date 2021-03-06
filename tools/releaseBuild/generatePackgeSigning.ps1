param(
    [Parameter(Mandatory)]
    [string] $Path,
    [string[]] $AuthenticodeDualFiles,
    [string[]] $AuthenticodeFiles
)

if ((!$AuthenticodeDualFiles -or $AuthenticodeDualFiles.Count -eq 0) -and (!$AuthenticodeFiles -or $AuthenticodeFiles.Count -eq 0))
{
    throw "At least one file must be specified"
}

function New-Attribute
{
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [object]$Value,
        [Parameter(Mandatory)]
        [System.Xml.XmlElement]$Element
    )

    $attribute = $signingXml.CreateAttribute($Name)
    $attribute.Value = $value
    $null = $fileElement.Attributes.Append($attribute)
}

function New-FileElement
{
    param(
        [Parameter(Mandatory)]
        [string]$File,
        [Parameter(Mandatory)]
        [string]$SignType,
        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$XmlDoc,
        [Parameter(Mandatory)]
        [System.Xml.XmlElement]$Job
    )

    if(Test-Path -Path $file)
    {
        $name = Split-Path -Leaf -Path $File
        $null = $fileElement = $XmlDoc.CreateElement("file")
        New-Attribute -Name 'src' -value $file -Element $fileElement
        New-Attribute -Name 'signType' -value $SignType -Element $fileElement
        New-Attribute -Name 'dest' -value "__OUTPATHROOT__\$name" -Element $fileElement
        $null = $job.AppendChild($fileElement)   
    }
    else
    {
        Write-Warning -Message "Skipping $SignType; $File because it does not exist"
    }
}

[xml]$signingXml = get-content (Join-Path -Path $PSScriptRoot -ChildPath 'packagesigning.xml')
$job = $signingXml.SignConfigXML.job

foreach($file in $AuthenticodeDualFiles)
{
    New-FileElement -File $file -SignType 'AuthenticodeDual' -XmlDoc $signingXml -Job $job
}

foreach($file in $AuthenticodeFiles)
{
    New-FileElement -File $file -SignType 'Authenticode' -XmlDoc $signingXml -Job $job
}

$signingXml.Save($path)
$updateScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'updateSigning.ps1'
& $updateScriptPath -SigningXmlPath $path