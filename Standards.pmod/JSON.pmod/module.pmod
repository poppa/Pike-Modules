//! JSON encoding/decoding module
//|
//| By Johan Sundström
//| Additions by Pontus Östlund
//|
//| See README.

//! Decode JSON data into Pike type
//!
//! @param json_data
mixed decode(string|Stdio.File json_data)
{
  return decoder->decode_json(json_data);
}

//! Encode Pike type into JSON string
//!
//! @param pike_data
string encode(mixed pike_data)
{
  return encoder->encode_json(pike_data);
}

private __decoder decoder = __decoder();
private __encoder encoder = __encoder();

private class __decoder
{
  inherit "json-import.pike";
}

private class __encoder
{
  inherit "json-export.pike";
}
