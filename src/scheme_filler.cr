# TODO: Write documentation for `SchemeFiller`
require "swagger"
require "har"
require "http"

module SchemeFiller
  VERSION = "0.1.0"
end

# Lax validation of the Swagger::Objects::Info::Contact
struct Swagger::Objects::Info::Contact
  @name : String = ""
end

# add setter for Swagger::Objects::MediaType
struct Swagger::Objects::MediaType
  def example=(value : String)
    @example = value
  end
end

# add setter for Swagger::Objects::Parameter
struct Swagger::Objects::Parameter
  property example : String? = nil

  def initialize(@name : String, @parameter_location : Location, @schema : Schema,
                 @description : String? = nil, @required = false, @allow_empty_value = false,
                 @deprecated = false, @ref : String? = nil, @example : String? = nil)
    # If the parameter location is "path", this property is REQUIRED and its value MUST be true.
    # Otherwise, the property MAY be included and its default value is false.
    @required = true if @parameter_location.path?
  end
end

if ARGV.size != 2
  puts "Usage: scheme-filler <schema-file> <har-file>"
  exit 1
end

# Read the OpenAPI schema file from the first cli argument
schema = File.read(ARGV[0])
# Parse the schema into a Swagger::Objects::Document
begin
  parsed_schema = Swagger::Objects::Document.from_json(schema)
  puts "Parsed schema with #{parsed_schema.paths.size} paths"
rescue e : JSON::ParseException
  puts "Error parsing Schema: #{e.message}"
  exit 1
end

# Read the HAR file from the second cli argument
har = File.read(ARGV[1])
# Parse the HAR file into a HAR::Data
begin
  parsed_har = HAR::Data.from_json(har)
  puts "Parsed #{parsed_har.log.entries.size} entries from HAR"
rescue e : JSON::ParseException
  puts "Error parsing HAR: #{e.message}"
  exit 1
end

fill_schema(parsed_schema, parsed_har)

# write the schema to a file with hour and minute timestamp
File.write("schema-#{Time.utc.hour}-#{Time.utc.minute}.json", parsed_schema.to_json)

# define a method that will fill the example values for a given schema from the har
def fill_schema(schema : Swagger::Objects::Document, har : HAR::Data)
  match_paths(schema, har) do |operation, entry|
    if req_body = operation.request_body
      if contents = req_body.content
        contents.each do |content_type, content|
          unless content.example
            puts "Added example for #{content_type} body in entry #{entry.request.url}"
            content.example = entry.request.post_data.try &.text || ""
            contents[content_type] = content
          end
        end
      end
    end

    if params = operation.parameters
      har_params = URI.parse(entry.request.url).query_params
      params.each do |param|
        if param.parameter_location == Swagger::Objects::Parameter::Location::Query
          if har_param = har_params[param.name]
            puts "Added example for query param #{param.name} with value #{har_param} in entry #{entry.request.url}"
            param.example = har_param
            params.reject! {|par| par.name == param.name}
            params << param
          end
        end
      end
    end
  end
end

# define a method that will match paths from the har to the schema
def match_paths(schema : Swagger::Objects::Document, har : HAR::Data)
  schema.paths.each do |path|
    har.log.entries.each do |entry|
      if URI.parse(entry.request.url).path.to_s == path[0]
        puts "Matched #{entry.request.url} to #{path[0]}"
        # path is a Tuple(String, Swagger::Objects::PathItem)
        case entry.request.method.downcase
        when "get"
          op = path.last.get
          next unless op
          yield op, entry
        when "post"
          op = path.last.post
          next unless op
          yield op, entry
        when "put"
          op = path.last.put
          next unless op
          yield op, entry
        when "delete"
          op = path.last.delete
          next unless op
          yield op, entry
        when "options"
          op = path.last.options
          next unless op
          yield op, entry
        when "head"
          op = path.last.head
          next unless op
          yield op, entry
        when "patch"
          op = path.last.patch
          next unless op
          yield op, entry
        when "trace"
          op = path.last.trace
          next unless op
          yield op, entry
        else
          raise "Unknown HTTP method: #{entry.request.method}"
        end
      end
    end
  end
end
