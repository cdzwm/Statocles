---
title: Home
---
<div id="index-banner">
<h1>Statocles <small>Static, App-capable Websites</small></h1>
</div>

Statocles is a minimal web content management system with a focus on easy editing
with any plain text editor.

<div class="row" style="display: table">
    <div class="one-half column" style="display: table-cell">
        Markdown and YAML...
        <pre style="margin-top: 0"><code style="white-space: pre-wrap">---
title: Home
---
# Welcome

My name is *Housemoon* and this is [a website](http://example.com)
</code></pre>
    </div>
    <div class="one-half column" style="display: table-cell">
        Becomes HTML...
        <div style="background: #F1F1F1; border: 1px solid #E1E1E1; border-radius: 4px; padding: 1rem 1.5rem; margin: 0 0.2rem;">
            <h1>Welcome</h1>
            <p>My name is <strong>Housemoon</strong> and this is <a href="#">a website</a></p>
        </div>
    </div>
</div>

## Features

* A simple format combining YAML and Markdown for editing site content.
* A [command-line application](/pod/Statocles/Command.html) for building,
  deploying, and editing the site.
* A simple daemon to display a test site before it goes live.
* A [blogging application](/pod/Statocles/App/Blog.html) with
    * RSS and Atom syndication feeds.
    * Tags to organize blog posts. Tags have their own custom feeds.
    * Post-dated blog posts to appear automatically when the date is passed.
* [Customizable themes](/pod/Statocles/Help/Theme.html) using a simple syntax
  of embedded Perl
* A clean default theme using [the Skeleton CSS library](http://getskeleton.com)
* SEO-friendly features such as [sitemaps (sitemap.xml)](http://www.sitemaps.org).

## Installing

Install the latest version of Statocles:

    curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Statocles

## Getting Started

Create a site using the `create` command:

    mkdir www.example.com
    cd www.example.com
    statocles create

See [the Statocles Setup guide](/pod/Statocles/Help/Setup.html) for more
information.

