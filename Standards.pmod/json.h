#ifndef JSON_H
#define JSON_H

private Decoder __decoder = Decoder();
private Encoder __encoder = Encoder();

/*******************************************************************************
 *                                                                             *
 *                             Encoder macros                                  *
 *                                                                             *
 ******************************************************************************/

#define add(X...) buf->add(sprintf(X))

/*******************************************************************************
 *                                                                             *
 *                             Decoder macros                                  *
 *                                                                             *
 ******************************************************************************/

#define skip_white() do {                                                      \
    whites: do {                                                               \
      switch ( data[p] ) {                                                     \
	case ' ': case '\r': case 0..10: break;                                \
	default: break whites;                                                 \
      }                                                                        \
    } while (p++ < len);                                                       \
  } while(0)

#define read_to(CHR,BUF) do {                                                  \
    int char = (int)CHR;                                                       \
    while (++p < len) {                                                        \
      if (data[p] == '\\' && data[p+1] == 'u') {                               \
	sscanf(data[p+2..p+5], "%4x", int uc);                                 \
	BUF += sprintf("%c", uc);                                              \
	p += 5;                                                                \
	continue;                                                              \
      }                                                                        \
      if (data[p] == char && data[p-1] != '\\')                                \
	break;                                                                 \
      if (BUF) BUF += data[p..p];                                              \
    }                                                                          \
  } while(0)

#define read_to_chars(CHRS,BUF) do { \
    while (p < len && !has_value( CHRS, data[++p] ))                           \
      BUF += data[p..p];                                                       \
  } while(0)
  
#define getc(STR) do {                                                         \
    lblgetc: do {                                                              \
      string c = data[p..p];                                                   \
      switch ( c[0] ) {                                                        \
	case '{':                                                              \
	case '}':                                                              \
	case '[':                                                              \
	case ']':                                                              \
	case ':':                                                              \
	case ',':                                                              \
	  STR = c;                                                             \
	  break lblgetc;                                                       \
	                                                                       \
	case '-':                                                              \
	case '0'..'9':                                                         \
	  STR = c;                                                             \
	  read_to_chars(({ ',', '\n','\t',' ', ':','}',']' }), STR);           \
	  break lblgetc;                                                       \
	                                                                       \
	case '\'':                                                             \
	case '"':                                                              \
	  STR = c;                                                             \
	  break lblgetc;                                                       \
	default:                                                               \
	  STR = c;                                                             \
	  break lblgetc;                                                       \
      }                                                                        \
    } while (++p < len);                                                       \
  } while (0);
  
#endif /* ifdef JSON_H */

