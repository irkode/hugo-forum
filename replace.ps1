
# process all html files in public
Get-ChildItem public -recurse -filter *.html | ForEach-Object {
   # load file
   $content = Get-Content $_.FullName -Encoding utf8
   # collect included styles
   $styles = $content | Select-String -Pattern "MYLINK:(.*)" -AllMatches -CaseSensitive | Foreach-Object {
      $_.Matches | ForEach-Object { '<link rel="stylesheet" href="{0}">' -f $_.Groups[1].Value }
   }
   # remove included styles
   $content = $content -replace "^.*?MYLINK:.*?$", ""
   # add style links to header
   $content = $content -replace "^.*?MYSTYLES.*?$", ($styles -join "`n")
   # Write content back to file
   #### This creates a copy with extension for checking the result
   $content | Set-Content -Force -Encoding utf8 -Path ($_.FullName + ".styles")
   #### This one will overwrite the file
   # Set-Content -Forse -Encoding -Path $_.FullName
}
