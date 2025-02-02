---
title: Paged Rest API in Hugo
---

## Paged Rest API with Hugo v0.143.0

There's automatic following paged results as with Powershell `Invoke-RestMethod -FollowRelLink`. But we now have access
to the Response Header fields incl. link. This enables us to implement a partial that returns all items from a paged
REST API.

Heres a quite bare PoC implementation of a `getRemotePaged` partial that will recursively get all paged results by
following the _Response Headers_ `next` link.

### API header

Some apis require special headers to make the server return valid data, target a specific api version or use
authenticated requests

for GitHub REST API it would be something like this:

```go-html-template
{{ $headers := dict
   "Accept" "application/vnd.github+json"
   "X-GitHub-Api-Version" "2022-11-28"
}}
```

maybe you want to add token authentication to get higher rate limit by using your GitHub token via Environment variable

```go-html-template
{{ with getenv "HUGO_GITHUB_TOKEN" }}
   $headers = merge $headers (dict "Authorization" (printf "Bearer %s" .))
{{ else }}
   {{ warnidf "NOTOKEN" "anonymous access only. To use a github token set ENV:HUGO_GITHUB_TOKEN. \
      Will help to overcome rate limits" }}
{{ end }}
```

### Ask for the Headers Link field

Let's setup the Resonse Header so it will give us the Links back needed for paged results. We will also add our API
headers from above.

The important field is the `response Headers` attribute to the global options.

```go-html-template
{{ $opts := dict
   "method" "get"
   "responseHeaders" (slice "Link")
   "headers" $headers
}}
```

If we now call something like `resources.GetRemote "https://api.github.com/repos/gohugoio/hugo/releases?per_page=50"` we
will not only get the JSON back, which can be retrieved via `.Content` method.

Use the `.Data` method to get a list of all headers. you'll see it now includes our requested `.Data.Headers.Link`
field.

```json
{
   "ContentLength": -1,
   "ContentType": "application/json; charset=utf-8",
   "Headers": {
      "Link": [
         "\u003chttps://api.github.com/repositories/11180687/releases?per_page=50\u0026page=2\u003e; \
         rel=\"next\", \u003chttps://api.github.com/repositories/11180687/releases? \
         per_page=50\u0026page=7\u003e; rel=\"last\""
      ]
   },
   "Status": "200 OK",
   "StatusCode": 200,
   "TransferEncoding": null
}
```

As you can see the _links_ are wrapped in an array with just one element. The value is a string directly from the
response header from the server. It follows the specification for that field. (some resources are listed in the github
issue for this feature: https://github.com/gohugoio/hugo/issues/12521)

### Extract Links

We are only interested in the Link field and need to extract these. a structure like this will be nice:

```JSON
{
   "next": "https://api.github.com/repositories/11180687/releases?per_page=50&page=2",
   "last": "https://api.github.com/repositories/11180687/releases?per_page=50&page=7"
}
```

We will use an inline partial within _getremotePaged_. With some _range_ and split magic it will extract our links and
return a map as shown before.

it's called like this `partial "getLinks" .Data.Headers`

```go-html-template
{{ define "partials/getLinks" }}
   {{ $links := dict }}
   {{ with index .Link 0 }}
      {{ range split . "," }}
         {{ with split .  ";" }}
            {{ $link := trim (index . 0) "<> " }}
            {{ $rel :=  index (split (index . 1) `"`) 1 }}
            {{ $links = merge $links (dict $rel $link) }}
         {{ end }}
      {{ end }}
   {{ else }}
      {{ warnf "NO LINK HERE %v" . }}
   {{ end }}
   {{ return $links }}
{{ end }}
```

### Retrieve full results (recursive)

Now let's just

- get the first page
- if there's a first link
   - call ourself with this next link
   - add the result to all we had before
- return the combined result

```go-html-template
{{ $pages := slice }}
{{ with try (resources.GetRemote $url $opts) }}
   {{ with .Err }}
      {{ errorf ".Err %s" . }}
   {{ else with .Value }}
      {{ $links := partial "getLinks" .Data.Headers }}
      {{ $pages = .Content | transform.Unmarshal }}
      {{ with $links.next }}
         {{ $pages = $pages | append (partial "getRemotePaged" .) }}
      {{ end }}
   {{ else }}
      {{ warnf "Unable to get remote resource %q" $url }}
   {{ end }}
{{ end }}
{{ return $pages }}
```

### Call it from a layout template

with that above as a base you can fetch all data from a paged API and use a standard loop over all objects.

```go-html-template

<h2>Hugo Releases</h2>
{{ $url := "https://api.github.com/repos/gohugoio/hugo/releases?per_page=50" }}

{{ $items := partial "getRemotePaged" $url }}
<ul>
{{ range $items }}
   <li><a href="{{ .html_url }}">{{ or .name .tag_name }}</a></li>
   <p>{{ .body | truncate 100 | $.RenderString }}</p>
{{ end }}
```

## Appendix

### Working example on github

You'll find a more elaborated working example based on the above code on my github repository.

relevant files are

- layouts_default\release.html
- layouts\partials\getRemotePaged.html

```bash
git clone --depth=1 --single-branch -b getRemotePaged https://github.com/irkode/hugo-forum getRemotePaged
cd getRemotePaged
hugo server
```

Browse to

- [http://localhost:1313/](http://localhost:1313/) for more or less this page
- [http://localhost:1313/releases/](http://localhost:1313/releases) to see the result

### References

- [Github issue #12521 Add .Data.Headers in GetRemote](https://github.com/gohugoio/hugo/issues/12521)
- [Release Notes v0.143.0](https://github.com/gohugoio/hugo/releases/tag/v0.143.0)
- Docs
   - [GetRemote ResponseHeaders](https://gohugo.io/functions/resources/getremote/#responseheaders)
   - [Resource.Data](https://gohugo.io/methods/resource/data/)
