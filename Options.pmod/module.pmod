/* Public.Poppa.Options
 *
 * Copyright (C) 2011  Pontus Östlund <pontus@poppa.se>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#pike __REAL_VERSION__

#define THROW_ERROR(X...) { if (throw_error) error(X); }

//! @ignore
constant __author = "Pontus Östlund <spam@poppa.se>";
constant __version = "0.1";
constant __components = ({ "Options.pmod/module.pmod" });
//! @endignore

enum Flag {
  OPTIONAL_ARG,
  REQUIRED_ARG
}

enum Type {
  TYPE_NONE,
  TYPE_INT,
  TYPE_FLOAT,
  TYPE_STRING,
  TYPE_ANY
}

class Context
{
  private string context;
  private string program_name;
  private array(Argument) args = ({});
  private int(0..1) help_enabled = 0;
  private Argument help;
  public int(0..1) posix_me_harder = 0; 

  void create(string|void _context, void|int(0..1) _help_enabled,
              void|int(0..1) _posix_me_harder)
  {
    context = _context||"";
    help_enabled = _help_enabled;
    posix_me_harder = zero_type(_posix_me_harder) ? !!getenv("POSIX_ME_HARDER")
                    : _posix_me_harder; 
    add_help();
  }

  private void add_help()
  {
    if (!help_enabled)
      return;

    Argument t = Argument("help", "h", OPTIONAL_ARG, TYPE_NONE, 
                          "Show help options");

    int(0..1) have_h, have_qm; 

    foreach (args, Argument a) {
      string o = a->get_opt();
      string opt = a->get_longopt();

      if (o == "h")
      	have_h = 1;
      else if (o == "?")
      	have_qm = 1;

      if (opt == "help") {
      	help = 0;
      	return;
      }
    }
    
    if (have_h && have_qm)
      t->__set_opt(0);
    else if (have_h)
      t->__set_opt("?");

    help = t;
  }
  
  void set_help_enabled(int(0..1) enable_help)
  {
    help_enabled = enable_help;

    if (help_enabled)
      add_help();
    else
      help = 0;
  }
  
  void|string usage(int(0..1)|void return_value)
  {
    if (!program_name) {
      error("%O->usage() can not be called prior to %[0]O->parse()\n",
            object_program(this));
    }

    string s = "Usage:\n  " + program_name;

    if (sizeof(args)) s += " [OPTIONS...]";
    if (sizeof(context)) s += " " + context;

    s += "\n";
    
    if (help)
      s += "\nHelp options:\n  " + (string)help + "\n";
      
    if (sizeof(args)) {
      s += "\nApplication options:\n  ";
      s += args->cast("string")*"\n  " + "\n";
    }

    s += "\n";
    
    if (return_value)
      return s;

    write(s);
    exit(0);
  }
  
  object_program add_argument(Argument|array(string|array(string)) a)
  {
    if (arrayp(a)) {
      if (arrayp( a[0] )) {
      	foreach (a, array arg)
      	  args += ({ Argument(@arg) });
      }
      else 
      	args += ({ Argument(@((array)a)) });
    }
    else
      args += ({ a });
    
    add_help();

    return this_object();
  }
  
  array(Argument) parse(array argv, int(0..1)|void throw_error)
  { 
    throw_error = zero_type(throw_error) || throw_error;
    
    program_name = argv[0];
    array(string) rest = argv[0..0];

    for (int i = 1; i < sizeof(argv); i++) {
      string o = argv[i];
      string|int(1..1) v;

      if (o[0] == '-' && sizeof(o) > 1) {
	// It's a longopt
	if (o[1] == '-') {
	  o = o[2..];
	}
	else {
	  o = o[1..];
	  switch (sizeof(o))
	  {
	    case 0:
	      // Nothing here, just a dash
	      THROW_ERROR("Malformed option!\n");
	      break;

	    case 1: 
	      // Value in next argv index
	      break;

	    default:
	      // Option with value appended, e.g. -w500
	      string tmp = o[0..0];
	      v = o[1..];
	      // Like -w=500
	      if (v[0] == '=') {
		v = 0;
		break;
	      }
	      o = tmp;
	      break;
	  }

      	  // e.g --arg=value
      	  if (!v && search(o, "=") > -1)
      	    [o, v] = o/"=";
      	}

      	if (Argument a = get_argument(o)) {
      	  if (posix_me_harder && sizeof(rest) > 1) {
      	    THROW_ERROR("Options not allowed after arguments\n");
      	    return args;
      	  }

      	  argv[i] = 0;

      	  if (!v) {
      	    if (a->get_type() != TYPE_NONE) {
      	      if (!has_index(argv, i+1)) {
      	      	if (a->get_type() != TYPE_ANY) {
		  THROW_ERROR("Argument %s is missing required value!\n",
			      a->get_opts());
		}

		a->set_is_found(1);
		a->set_value(1);
		continue;
      	      }

      	      i++;
      	      string tmp = argv[i];

      	      if (tmp[0] == '-' && sizeof(tmp) > 1) {
      	      	if (a->get_type() != TYPE_ANY) {
		  THROW_ERROR("Argument %s is missing required value!\n",
			      a->get_opts());
		}
		i--;
		continue;
      	      }

      	      argv[i] = 0;
      	      v = tmp;
      	    }
      	    else {
      	      v = 1;
      	    }
      	  }

      	  a->set_is_found(1);
      	  a->set_value(v);
      	}
      	else {
      	  if (help && (help->get_opt() == o || help->get_longopt() == o))
      	    usage();

      	  if (posix_me_harder && sizeof(rest) > 1) {
      	    THROW_ERROR("Options not allowed after arguments\n");
      	    return args;
      	  }
      	  else
	    THROW_ERROR("Unknown argument %s\n", o);
      	}
      }
      else {
      	rest += ({ o });
      }
    }

    array(Argument) ret = ({});
    
    foreach (args, Argument a) {
      if (!a->get_is_found()) {
      	if (a->get_flag() == REQUIRED_ARG)
	  THROW_ERROR("Missing required argument \"%s\"\n", a->get_opts());
      }
      else ret += ({ a });
    }

    return args;
  } 

  public Argument `[](string option)
  {
    Argument a = get_argument(option);
    return a && a->get_is_found() && a;
  }
  
  public Argument get_argument(string c)
  {
    foreach (args, Argument a) {
      if (a->get_opt() == c || a->get_longopt() == c)
	return a;
    }
      
    return 0;
  }
  
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%s(%O)", "Context", args);
  }
}

class Argument
{
  private string longopt;
  private string opt;
  private Flag flag;
  private Type type;
  private string description;
  private mixed ref;
  private int(0..1) is_found = 0;
  
  void create(string _longopt, string _opt, Flag _flag, Type _type, 
              string|void _description, mixed|void _ref)
  {
    longopt = _longopt;
    opt = _opt;
    flag = _flag;
    type = _type;
    description = _description;
    ref = _ref;
  }
  
  string get_longopt()
  {
    return longopt;
  }
  
  //! @ignore
  //! Consider internal
  void __set_opt(string t)
  {
    opt = t;
  }
  //! @endignore
  
  string get_opt()
  {
    return opt;
  }
  
  Flag get_flag()
  {
    return flag;
  }
  
  Type get_type()
  {
    return type;
  }
  
  string get_description()
  {
    return description;
  }
  
  mixed get_value()
  {
    return ref;
  }
  
  string get_opts()
  {
    string s = "";
    if (opt && longopt)
      return sprintf("-%s|--%s", opt, longopt);
    else if (opt)
      return sprintf("-%s", opt);
    else if (longopt)
      return sprintf("--%s", longopt);
    
    error("No opt or longopt set in %O\n", object_program(this));
  }
  
  int(0..1) `==(mixed v) 
  {
    return ref == v;
  }
  
  int(0..1) get_is_found()
  {
    return is_found;
  }

  void set_is_found(int yes_or_no)
  {
    is_found = yes_or_no;
  }

  void set_value(string|int|float value)
  {
    switch (type)
    {
      case TYPE_INT:
	ref = (int)value;
	break;

      case TYPE_FLOAT:
	ref = (float)value;
	break;

      case TYPE_STRING:
	ref = (string)value;
	break;

      case TYPE_ANY:
	ref = value;
	break;

      case TYPE_NONE:
	if (!intp(value) || (value < 0 || value > 1))
	  error("Arguments of type TYPE_NONE doesn't take values");
	ref = value;
	break;
    }
  }

  mixed cast(string how)
  {
    if (how == "string") {
      string s;
      if (longopt && opt)
      	s = sprintf("-%s, --%s", opt, longopt);
      else if (opt)
      	s = sprintf("-%s", opt);
      else if (longopt)
      	s = sprintf("    --%s", longopt);
      
      return sprintf("%-20s  %s", s, description||"");
    }
    
    error("Can't cast %O to %s\n", object_program(this), how);
  }
  
  string _sprintf(int t)
  {
    return sprintf("Argument(%s|%s = %O)", opt && "-" + opt || "", 
                   longopt && "--" + longopt || "", ref);
  }
}