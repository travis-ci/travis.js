# Travis CI CoffeeScript Client [![Build Status](https://travis-ci.org/travis-ci/travis.js.svg?branch=master)](https://travis-ci.org/travis-ci/travis.js)

Welcome to **travis.js**, a Travis CI CoffeeScript Client that works both in your web browser and in node.js.

This is in a very early stage right now, so it's not really useful yet. If you are not here to contribute, you probably want to come back later.

A secondary purpose at the moment is getting to know the CoffeeScript tool chain a little better.

## Setup and Usage

### Node.js

Install it via npm:

``` shell
npm install travis
```

And load the module:

``` coffee
Travis = require 'travis'
travis = new Travis

travis.config (config) ->
  console.log config
```

### Web Browser

``` html
<script scr="build/travis.min.js"></script>
<script>
var travis = new Travis;

travis.config(function(config) {
  alert(config.host);
});
</script>
```

### Building from Source

You can compile everything from source by cloning the repository and running `grunt build`.