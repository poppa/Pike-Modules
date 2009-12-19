#ifndef _SOCIAL_H

#define _SOCIAL_H

//! Checks if STR is undefined or empty
#define EMPTY(STR) (!STR || !sizeof(STR))

//! If STR is undefined STR will be set to an empty string 
#define NOT_NULL(STR) STR = STR||""

//! Throws an argument error
#define ARG_ERROR(ARG, MSG...) \
 error("Argument exception (%s): %s\n", (ARG), sprintf(MSG))

//! Checks if A is an instance of B (either directly or by inheritance)
#define INSTANCE_OF(A,B) (object_program((A)) == object_program((B)) || \
                          Program.inherits(object_program((A)),         \
			                   object_program(B)))
 
#endif /* ifndef _SOCIAL_H */