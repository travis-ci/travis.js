## Generating Files

**Never edit files in `build` manually!**

## Releases

When you change the version number, do it in `package.json`, `src/travis.coffee` and `spec/travis-spec.coffee`.

## Compile JavaScript

One off:

    $ grunt build

On file changes:

    $ grunt watch

## Run Specs

In Node.js:

    $ grunt

In the browser:

    $ grunt dev
    # now open http://localhost:9595

Set the `port` env variable if port 9595 is already taken.