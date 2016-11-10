# Prelinger Archives Crawler

Code to crawl the Internet Archive metadata for the Prelinger Archives and convert it into RDF.

Ensure you have Ruby 2.3, Bundler and `rapper` installed. Then:

```
bundle install
```

And:

```
rake download
rake convert
```

The first rake task downloads and caches the files. The second runs the conversion on the local files.

If you're modifying the output code, try to avoid constantly recrawling the Internet Archive: rely on your local copy
of the data.

If you're just interested in grabbing the metadata, then `rake download` is all you need. This will create a local 
cache of the XML files that describe the film, the various files associated with the film and any user reviews.

The collection is available under a CC0 waiver so I believe its safe to treat the metadata on the same basis.

The code does not download any of the content, but does provide links to it. Again, cache the data you need rather than 
relying on the IA to serve it, if possible.

