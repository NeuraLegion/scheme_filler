# scheme_filler

`scheme_filler` is a CLI tool that helps you populate an OpenAPI 3.0.0 schema with example values.
It does so by accepting an HAR file and a schema file, and then generating a new schema file with the example values.

## Installation

### From Source

1. [Install Crystal](https://crystal-lang.org/docs/installation/)
2. `git clone` this repo
3. `cd` into the repo
4. `shards build`

### Docker Image

1. clone the repo
2. `cd` into the repo
3. `docker build -t neuralegion/scheme_filler .`

## Usage

### Binary

`bin/scheme_filler <scheme_file> <har_file>` will generate a new schema file with the example values.

### Docker

`docker run -v <path_to_schema_file>:/tmp/schema.json -v <path_to_har_file>:/tmp/har.json neuralegion/scheme_filler /tmp/schema.json /tmp/har.json` will generate a new schema file with the example values.

## Contributing

1. Fork it (<https://github.com/NeuraLegion/scheme_filler/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Bar Hofesh](https://github.com/bararchy) - creator and maintainer
