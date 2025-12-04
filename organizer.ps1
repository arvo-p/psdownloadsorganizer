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
$types += [Org]::new("PDF",@("PDF","EPUB"))
$types += [Org]::new("PROGRAMs",@("EXE","MSI","appinstaller"))
$types += [Org]::new("ISOs",@("ISO"))
$types += [Org]::new("Office",@("docm","docx","xlsx","pptx","odt","xls","sch"))
$types += [Org]::new("Archives",@("ZIP","7Z","TAR.GZ","GZIP","tgz"))
$types += [Org]::new("Media",@("webp","srt","jpg","jpeg","bmp","png","webm","mp4","avi","mkv"))
$types += [Org]::new("Torrents",@("torrent"))
$types += [Org]::new("Misc",@("json","rss","fbx","sql"))

# --- NOUVELLE VARIABLE : Délai de péremption (90 jours = 3 mois) ---
$OldFileCutoff = (Get-Date).AddDays(-90)

$root = $env:userprofile + "\Downloads\"

# --- 1. CRÉATION DES DOSSIERS DE CATÉGORIE ET DES SOUS-DOSSIERS "OLD" ---
foreach($type in $types){
	# Crée le dossier de la catégorie (ex: C:\Users\User\Downloads\PDF)
	[System.IO.Directory]::CreateDirectory($root+$type.foldername)
	
	# Crée le sous-dossier "OLD" à l'intérieur (ex: C:\Users\User\Downloads\PDF\OLD)
	[System.IO.Directory]::CreateDirectory($root+$type.foldername+"\OLD")
}

$leave = $false
while(!$leave){
	# --- 2. DÉPLACEMENT DES NOUVEAUX FICHIERS VERS LES CATÉGORIES ---
	Get-ChildItem $root | Where {!$_.PSIsContainer} | Foreach-Object{
		:loop foreach($type in $types){
			$file = $_
			foreach($ext in $type.ext){
				if($file.Extension -eq $ext){
					$dir = $root+$type.foldername+"/"+$file.Name;
					Move-Item -Path $file.FullName -Destination $dir; 
					break :loop
				}
			}
		}
	}
	
	# --- 3. DÉPLACEMENT DES FICHIERS ANCIENS VERS LES DOSSIERS "OLD" ---
	# Pour chaque dossier de catégorie (ex: PDF, Media, etc.)
	foreach($type in $types){
		$categoryPath = $root + $type.foldername
		$oldPath = $categoryPath + "\OLD\"
		
		# Récupère les fichiers DANS la catégorie (ex: DANS C:\...\PDF)
		# Exclut le sous-dossier "OLD" lui-même
		Get-ChildItem $categoryPath -File | Where {
			# Vérifie si le fichier est plus vieux que la date limite
			$_.LastWriteTime -lt $OldFileCutoff
		} | Foreach-Object {
			# Déplace le fichier vers le sous-dossier OLD
			Move-Item -Path $_.FullName -Destination ($oldPath + $_.Name)
		}
	}
	
	Start-Sleep -Seconds 3600
}

