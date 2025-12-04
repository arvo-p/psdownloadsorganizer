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
$types += [Org]::new("Office",@("docx","xlsx","pptx","odt","xls","sch"))
$types += [Org]::new("Archives",@("ZIP","7Z","TAR.GZ","GZIP","tgz"))
$types += [Org]::new("Media",@("jpg","jpeg","bmp","png","webm","mp4","avi","mkv"))
$types += [Org]::new("Torrents",@("torrent"))
$types += [Org]::new("Misc",@("json","rss","fbx","sql"))

$root = $env:userprofile + "\Downloads\"

foreach($type in $types){
	[System.IO.Directory]::CreateDirectory($root+$type.foldername)
}

$leave = $false
while(!$leave){
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
	Start-Sleep -Seconds 3600
}
