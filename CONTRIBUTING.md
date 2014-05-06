## Generating Files

**Never edit files in `build` or the `README.md` manually!**

Instead, edit `README.coffe.md` and the files in `src` and `spec`.

## Releases

When you change the version number, do it in `package.json`, `src/travis.coffee` and `spec/travis-spec.coffee`.

## Compile JavaScript

One off:

    $ grunt build

On file changes:

    $ grunt watch

## Run Specs

In Node.js and local browsers via karma:

    $ grunt

Just in Node.js:

    $ grunt spec

On Saucelabs (set `SAUCE_USER` and `SAUCE_ACCESS_KEY`):

    $ grunt build karma:sauce

You can also open `spec/runner.html` in any browser. Note that source mapping will not work if it is served via the `file` protocol.
