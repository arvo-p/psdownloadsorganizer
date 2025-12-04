class Org{
	[ValidateNotNullOrEmpty()][string]$foldername
	[ValidateNotNullOrEmpty()][string[]]$ext
	Org([String]$foldername,[String[]]$ext){
		 $this.foldername = $foldername
		 foreach($e in $ext){
			$this.ext += "."+$e.ToLower()
		 }
	}
}

[Org[]]$types = @()
$types += [Org]::new("PDF",@("PDF","EPUB","DJVU"))
$types += [Org]::new("PROGRAMs",@("EXE","MSI","appinstaller"))
$types += [Org]::new("ISOs",@("ISO"))
$types += [Org]::new("Office",@("docx","xlsx","pptx","odt","xls","sch"))
$types += [Org]::new("Archives",@("ZIP","7Z","rar","TAR.GZ","GZIP","tgz"))
$types += [Org]::new("Media",@("jpg","jpeg","bmp","png","webm","mp4","avi","mkv"))
$types += [Org]::new("Torrents",@("torrent"))
$types += [Org]::new("Misc",@("json","rss","fbx","sql"))
$types += [Org]::new("CODE",@("ps1","sh","py","js","php","html","css","java","c","cpp","cs","vb","xml","yml"))

# --- VARIABLES ---
$OldFileCutoff = (Get-Date).AddDays(-90)
$root = $env:userprofile + "\Downloads\"
$logFile = $root + "organisation_log.html" # Chemin du fichier log

# --- INITIATION DU FICHIER LOG HTML ---
[String]$htmlHeader = "
<!DOCTYPE html>
<html>
<head>
<title>Downloads Organization Log</title>
<meta charset='UTF-8'/>
<style>
body { font-family: Arial, sans-serif; }
table { width: 100%; border-collapse: collapse; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #f2f2f2; }
.old { background-color: #ffe0b2; } /* Couleur pour les fichiers archivés */
</style>
</head>
<body>
<h1>Downloads Organization Log</h1>
<table>
<tr>
    <th>Date/Time</th>
    <th>File</th>
    <th>Destination Path</th>
    <th>Type</th>
</tr>
"
$htmlFooter = "
</table>
</body>
</html>
"

# Note: L'encodage UTF8 est utilisé ici pour le log HTML, ce qui est correct.
Out-File -FilePath $logFile -InputObject $htmlHeader -Encoding UTF8 -Force

# --- CRÉATION DES DOSSIERS DE CATÉGORIE ET DES SOUS-DOSSIERS "OLD" ---
foreach($type in $types){
	[System.IO.Directory]::CreateDirectory($root+$type.foldername)
	[System.IO.Directory]::CreateDirectory($root+$type.foldername+"\OLD")
}

$leave = $false
while(!$leave){
	$currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

	# --- 1. DÉPLACEMENT DES NOUVEAUX FICHIERS VERS LES CATÉGORIES ---
	Get-ChildItem $root | Where {!$_.PSIsContainer} | Foreach-Object{
		$file = $_
		if($file.Name -eq "organisation_log.html"){
			return
		}
		:loop foreach($type in $types){
			foreach($ext in $type.ext){
				if($file.Extension -eq $ext){
					$dir = $root+$type.foldername+"\"+$file.Name;
					Move-Item -Path $file.FullName -Destination $dir; 
					
					# ÉCRITURE DANS LE FICHIER LOG (Nouveaux Fichiers)
					$logEntry = "<tr><td>$currentDate</td><td>$($file.Name)</td><td>$dir</td><td>Classed</td></tr>"
					Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 # Utiliser UTF8 ici
					
					break :loop
				}
			}
		}
	}
	
	# --- 2. DÉPLACEMENT DES FICHIERS ANCIENS VERS LES DOSSIERS "OLD" ---
	foreach($type in $types){
		$categoryPath = $root + $type.foldername
		$oldPath = $categoryPath + "\OLD\"
		
		Get-ChildItem $categoryPath -File | Where {
			$_.LastWriteTime -lt $OldFileCutoff
		} | Foreach-Object {
			$file = $_
			$newDestination = $oldPath + $file.Name
			
			Move-Item -Path $file.FullName -Destination $newDestination
			
			# ÉCRITURE DANS LE FICHIER LOG (Fichiers Archivés)
			$logEntry = "<tr class='old'><td>$currentDate</td><td>$($file.Name)</td><td>$newDestination</td><td>Archived (OLD)</td></tr>"
			Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 # Utiliser UTF8 ici
		}
	}
	
	# --- FINALISATION DU FICHIER LOG ---
	$content = Get-Content -Path $logFile -Encoding UTF8 | Select-Object -SkipLast 1 # Lire en UTF8
    $content += $htmlFooter 

    Out-File -FilePath $logFile -InputObject $content -Encoding UTF8 -Force # Écrire en UTF8
	
	Start-Sleep -Seconds 3600
}
