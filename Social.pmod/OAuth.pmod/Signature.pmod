/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{OAuth.Signature module@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! This file is part of OAuth.pmod
//!
//! OAuth.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! OAuth.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with OAuth.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "oauth.h"

import ".";

//! Signature type for the Base class.
protected constant NONE = 0;

//! Signature type for plaintext signing
constant PLAINTEXT = 1;

//! Signature type for hmac sha1 signing
constant HMAC_SHA1 = 2;

//! Signature type for rsa sha1 signing
constant RSA_SHA1  = 3;

//! Signature types to signature key mapping
constant SIGTYPE = ([
  NONE      : "",
  PLAINTEXT : "PLAINTEXT",
  HMAC_SHA1 : "HMAC-SHA1",
  RSA_SHA1  : "RSA-SHA1"
]);

//! Returns a signature class for signing with @[type]
//!
//! @param type
//!  Either @[Signature.PLAINTEXT], @[Signature.HMAC_SHA1] or
//!  @[Signature.RSA_SHA1].
object get_object(int type)
{
  switch (type)
  {
    case PLAINTEXT: return Plaintext();
    case HMAC_SHA1: return HmacSha1();
    case RSA_SHA1:  return RsaSha1();
    default: /* nothing */
  }

  error("Uknknown signature type");
}

//! Base signature class
protected class Base
{
  //! Signature type
  protected int type = NONE;

  //! String representation of signature typ
  protected string method = SIGTYPE[NONE];

  //! Returns the @[type]
  int get_type()
  {
    return type;
  }

  //! Returns the @[method]
  string get_method()
  {
    return method;
  }

  //! Builds the signature string
  //! @param request
  //! @param cosumer
  //! @param token
  string build_signature(Request request, Consumer consumer, Token token);
}

//! Plaintext signature
protected class Plaintext
{
  inherit Base;
  protected int    type   = PLAINTEXT;
  protected string method = SIGTYPE[PLAINTEXT];

  string build_signature(Request request, Consumer consumer, Token token)
  {
    return uri_encode(sprintf("%s&%s", consumer->secret, token->secret));
  }
}

//! HMAC_SHA1 signature
protected class HmacSha1
{
  inherit Base;
  protected int    type   = HMAC_SHA1;
  protected string method = SIGTYPE[HMAC_SHA1];

  string build_signature(Request request, Consumer consumer, Token token)
  {
    if (!token) token = Token("","");
    string sigbase = request->get_signature_base();
    string key = sprintf("%s&%s", uri_encode(consumer->secret),
				  uri_encode(token->secret||""));
    return MIME.encode_base64(
#if constant(Crypto.HMAC)
      Crypto.HMAC(Crypto.SHA1)(key)(sigbase)
#else /* Compat for Pike 7.4 */
      Crypto.hmac(Crypto.sha)(key)(sigbase)
#endif
    );
  }
}

//! RSA_SHA1 signature
protected class RsaSha1
{
  inherit Base;
  protected int    type   = RSA_SHA1;
  protected string method = SIGTYPE[RSA_SHA1];

  string build_signature(Request request, Consumer consumer, Token token)
  {
    error("%s is not implemented.\n", CLASS_NAME(this));
  }
}
