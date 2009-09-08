//! JSON encoding/decoding module
//! See README.

//! Decode JSON data into Pike type
//!
//! @param json_data
mixed decode(string|Stdio.File json_data)
{
  return __decoder()->decode_json(json_data);
}

//! Encode Pike type into JSON string
//!
//! @param pike_data
string encode(mixed pike_data)
{
  return __encoder()->encode_json(pike_data);
}

class __decoder
{
  inherit "json-import.pike";
}

class __encoder
{
  inherit "json-export.pike";
}