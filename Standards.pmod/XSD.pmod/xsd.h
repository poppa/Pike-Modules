#ifndef XSD_H
#define XSD_H

#define THROW(S,X...) throw(({ sprintf((S),X)+"\n", backtrace() }))

#endif