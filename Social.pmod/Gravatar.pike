/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! This class generates an URL to a Gravatar image.
//! @url{http://www.gravatar.com@}
//!
//! @b{Example@}
//! @code
//!  // Most simple scenario
//!  Social.Gravatar g = Social.Gravatar("me@@domain.com");
//!  string url = (string)g;
//! @endcode

//! G rated gravatar is suitable for display on all websites with any
//! audience type.
constant RATING_G  = "g";

//! PG rated gravatars may contain rude gestures, provocatively dressed
//! individuals, the lesser swear words, or mild violence.
constant RATING_PG = "pg";

//! R rated gravatars may contain such things as harsh profanity, intense
//! violence, nudity, or hard drug use.
constant RATING_R  = "r";

//! X rated gravatars may contain hardcore sexual imagery or extremely
//! disturbing violence.
constant RATING_X  = "x";

//! Base URI to the gravatar site
protected local string gravatar_url = "http://www.gravatar.com/avatar.php?";

//! Avilable ratings
protected multiset ratings = (< RATING_G, RATING_PG, RATING_R, RATING_X >);

//! Default fallback image. This is a URI and should contain the schema as well.
string image;

//! The email the Gravatar account is registered with
string email;

//! The Gravatar rating. Default is @tt{RATING_G@}
string rating = RATING_G;

//! The size of the Gravatar to display
int size = 80;

//! Creates a new @[Gravatar] object
//!
//! @param _email
//!  The email the account is registerd with
//! @param _size
//!  Sets the size of the image. Default is @tt{80@}
//! @param _rating
//!  The rating the Gravatar is registerd as. Default value is @tt{G@}
void create(void|string _email, void|string|int _size, void|string _rating)
{
  email  = _email;
  size   = (int)_size||size;
  rating = _rating||rating;
}

//! Creates and returns the URL to the Gravatar
string get_avatar()
{
  if (!email || !sizeof(String.trim_all_whites(email)))
    error("Missing requierd \"email\".\n");

  if ( !ratings[rating] ) {
    error("Rating is %O. Must be one of \"%s\".\n",
          rating, String.implode_nicely((array)ratings, "or"));
  }

  if (size < 1 || size > 512)
    error("Size must be between 1 and 512.\n");

  return gravatar_url +
  sprintf("gravatar_id=%s&amp;rating=%s&amp;size=%d",encode_id(),rating,size) +
  (image && ("&amp;default=" + Protocols.HTTP.uri_encode(image))||"");
}

//! Returns the Gravatar as a complete @tt{<img/>@} tag.
string img(void|string alt_text)
{
  alt_text = alt_text||"Gravatar";
  return sprintf("<img src='%s' height='%d' width='%d' alt='%s' title=''/>",
                 get_avatar(), size, size, alt_text);
}

//! Hashes the email.
protected string encode_id()
{
  string hash = String.trim_all_whites(lower_case(email));
#if constant(Crypto.MD5)
  hash = String.string2hex(Crypto.MD5.hash(hash));
#else /* Compat cludge for Pike 7.4 */
  hash = Crypto.string_to_hex(Crypto.md5()->update(hash)->digest());
#endif

  return hash;
}

//! Casting method.
//!
//! @param how
mixed cast(string how)
{
  if (how == "string")
    return get_avatar();

  error("Can't cast %O to %O.\n", object_program(this_object()), how);
}
