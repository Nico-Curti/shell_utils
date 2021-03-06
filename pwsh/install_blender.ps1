#!/usr/bin/env pwsh

Function get_blender
{
  Param (
          [Bool] $add2path,
          [Parameter(Mandatory=$false, ValueFromRemainingArguments=$false)] [String[]] $modules
        )

  $url_blender = "https://mirrors.dotsrc.org/blender/blender-release/Blender2.81/blender-2.81-windows64.zip"
  $url_pip = "https://bootstrap.pypa.io/get-pip.py"

  $out_dir = $url_blender.split('/')[-1]
  $ver = $out_dir.split('-')[1]
  $out = $out_dir.Substring(0, $out_dir.Length - 4) # remove extension (.zip)

  Write-Host download blender from $url_blender

  Invoke-WebRequest -Uri $url_blender -OutFile $out_dir

  Write-Host unzip $out_dir
  Expand-Archive $out_dir -DestinationPath blender
  Remove-Item $out_dir -Force -Recurse -ErrorAction SilentlyContinue
  Set-Location blender
  $dir_name = Get-ChildItem blender* -Name
  If( $add2path )
  {
    $Documents = [Environment]::GetFolderPath('MyDocuments')
    -join('$env:PATH = $env:PATH', " + `";$PWD\blender\$dir_name`"") | Out-File -FilePath "$Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Append -Encoding ASCII
  }
  $env:PATH = $env:PATH + ";$PWD\blender\$dir_name"

  Set-Location $dir_name/$ver/python/bin

  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $url_pip -OutFile $PWD/get-pip.py

  Write-Host "Run get-pip"
  $bpy = Get-ChildItem "python*.exe" -Name
  & ./$bpy get-pip.py
  Remove-Item get-pip.py -Force -ErrorAction SilentlyContinue

  Set-Location ..\Scripts\

  Foreach ( $i in $modules )
  {
    ./pip.exe install $i
  }
}


Function install_blender
{
  Param (
          [Bool] $add2path,
          [Parameter(Mandatory=$false)] [String] $confirm = "",
          [Parameter(Mandatory=$false, ValueFromRemainingArguments=$false)] [String[]] $modules
        )

  # Blender download
  Write-Host "Blender identification: " -NoNewLine
  If( -Not (Get-Command blender -ErrorAction SilentlyContinue) )
  { # blender not installed
    Write-Host "FOUND" -ForegroundColor Red
    If( $confirm -eq "-y" -Or $confirm -eq "-Y" -Or $confirm -eq "yes" )
    {
      get_blender -add2path $add2path -modules $modules
    }
    Else
    {
      $CONFIRM = Read-Host -Prompt "Do you want install it? [y/n]"
      If($CONFIRM -eq "N" -Or $CONFIRM -eq "n")
      {
        Write-Host "Abort" -ForegroundColor Red
      }
      Else
      {
        get_blender -add2path $add2path -modules $modules
      }
    }
  }
  Else
  {
    Write-Host "FOUND" -ForegroundColor Green
  }

}

#install_blender -add2path $true -confirm -y
