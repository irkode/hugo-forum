# Hugo Forum Playground

This is my playground repository for Hugo.

This is a bare Hugo setup as described in the docs with some slight additions.

## create a bare themed Hugo site

```bash
hugo new site mysite
cd mysite
hugo new theme mysite
echo "theme = 'mysite' > hugo.toml
```

## additional components

-  keep empty folders

   The initialisation creates a lot of empty folders to hava a good skeleton. Git on the other side
   will not add/commit empty folders.

   To overcome this I added an `.keep` file to all empty folders.

-  Disable Taxonomies and Sitemap

   For playing around I don't want these fils to be generated. Disabled that in the config

   ```
   disableKinds = ['RSS', 'sitemap', 'taxonomy', 'term']
   ```

-  workaround for cleanDestinationDir bug

   hugo won't handle that if no static folder is there. In my case it's there because of the `.keep`
   file. I do not want to get that added to the final site, so I remount the static folder excluding
   it.

   ```
   [module]
      [[module.mounts]]
         source = "static"
         target = "static"
      [[module.mounts]]
         source = "static"
         target = "static"
         excludeFiles = [".keep"]
   ```

-  Prettier code formatter

   I use [Prettier code formatter](https://prettier.io/) to handle all my site stuff. So the
   neccessary config is committed.

   If you have `node.js` installed you may call `npm install --save-dev` to install it. More in
   their installation guide.

   Check the `.prettierrc` file for some useful settings.

-  Git configuration: .gitignore and .gitattributes

   Git configuration for LF conversion and to ignore Hugo's generated stuff and the files I don't
   want to expose.
