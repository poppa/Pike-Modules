/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Linear regression
//!
//! @param data
//!  In the form of
//!  @code
//!   ({ /* n elements */
//!     ({ /* 2 elements */
//!        a0,
//!        a1
//!     }),
//!     ({ /* 2 elements */
//!        b0,
//!        b1
//!     }),
//!     and so on...
//!   })
//!  @endcode
array(float) linear(array(array(float)) data)
{
  array(float) sum = allocate(4, 0.0), points = ({});
  float gradient, intercept;
  int n = sizeof(data);

  foreach (data, array(float) row) {
    sum[0] += row[0];
    sum[1] += row[1];
    sum[2] += row[0] * row[0];
    sum[3] += row[0] * row[1];
  }

  gradient  = (n * sum[3] - sum[0] * sum[1]) / (n * sum[2] - sum[0] * sum[0]);
  intercept = (sum[1] / n) - (gradient * sum[0]) / n;

  return ({ gradient, intercept });
}

//! Same as @[linear()] except a mapping is returned with some additional info
//! and the plotting points.
//!
//! @param data
//! @returns
//!  @mapping
//!   @member array "equation"
//!    Same as what's returned from @[linear()]
//!   @member array "points"
//!   @member string "string"
//!    The equation described
//!  @endmapping
mapping(string:mixed) linear2(array(array(float|int)) data)
{
  array(float) points = ({});
  int n = sizeof(data);

  [float gradient, float intercept] = linear(data);

  for (int i; i < n; i++)
    points += ({ ({ data[i][0], data[i][0] * gradient + intercept }) });

  return ([ "equation" : ({ gradient, intercept }),
            "points"   : points,
            "string"   : sprintf("y = %fx + %f", (gradient * 100) / 100,
                                                 (intercept * 100) / 100) ]);
}
