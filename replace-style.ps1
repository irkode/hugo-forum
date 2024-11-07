
# process all html files in public
Get-ChildItem public -recurse -filter *.html | Select-Object -first 1 | ForEach-Object {
   $fullName = $_.FullName
   Write-Output "process $fullName"
   # load file
   $content = Get-Content -Raw $FullName -Encoding utf8
   # collect included sytles and remember the url
   $regex = [regex]::new("<style data-name=""(style-.*?)"" title=""(.*?)"">(.*?)</style>", "Compiled,Multiline")
   if ($AllMatches = $regex.Matches($content)) {
      $styles = $AllMatches | ForEach-Object {
         '<link rel="stylesheet" href="{0}">' -f $_.Groups[2].value
      } | Select-Object -Unique
   }
   # remove included styles
   $content = $regex.Replace($content, "")
   # add style links to header
   $content = $content -replace '<style data-name="styleinclude"></style>', ($styles -join "`n")
   # Write content back to file
   #### This creates a copy with extension for checking the result
   $content | Set-Content -Force -Encoding utf8 -Path ($FullName + ".styles")
   #### This one will overwrite the file
   # Set-Content -Forse -Encoding -Path $_.FullName
}
