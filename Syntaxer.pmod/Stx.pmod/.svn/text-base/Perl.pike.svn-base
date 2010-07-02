inherit "../Parser.pike";

public string title = "Perl";

private multiset(string) _keywords = (<
  "continue","do","else","elsif","for","foreach","goto","if","last","local",
  "lock","map","my","next","package","redo","require","return","sub",
  "unless","until","use","while","STDIN","STDOUT","STDERR","ARGV","ARGVOUT",
  "ENV","INC","SIG","TRUE","FALSE","__FILE__","__LINE__","__PACKAGE__",
  "__END__","__DATA__","lt","gt","le","ge","eq","ne","cmp","x","not","and",
  "or","xor","q","qq","qx","qw"
>);

private multiset(string) _functions = (<
  "abs","accept","alarm","atan2","bind","binmode","bless","caller","chdir",
  "chmod","chomp","chop","chown","chr","chroot","close","closedir","connect",
  "cos","crypt","dbmclose","dbmopen","defined","delete","die","dump","each",
  "eof","eval","exec","exists","exit","exp","fcntl","fileno","flock","fork",
  "format","formline","getc","getlogin","getpeername","getpgrp","getppid",
  "getpriority","getpwnam","getgrnam","gethostbyname","getnetbyname",
  "getprotobyname","getpwuid","getgrgid","getservbyname","gethostbyaddr",
  "getnetbyaddr","getprotobynumber","getservbyport","getpwent","getgrent",
  "gethostent","getnetent","getprotoent","getservent","setpwent","setgrent",
  "sethostent","setnetent","setprotoent","setservent","endpwent","endgrent",
  "endhostent","endnetent","endprotoent","endservent","getsockname",
  "getsockopt","glob","gmtime","grep","hex","import","index","int","ioctl",
  "join","keys","kill","lc","lcfirst","length","link","listen","localtime",
  "log","lstat","mkdir","msgctl","msgget","msgsnd","msgrcv","no","oct",
  "open","opendir","ord","pack","pipe","pop","pos","print","printf",
  "prototype","push","quotemeta","rand","read","readdir","readlink","recv",
  "ref","rename","reset","reverse","rewinddir","rindex","rmdir","scalar",
  "seek","seekdir","select","semctl","semget","semop","send","setpgrp",
  "setpriority","setsockopt","shift","shmctl","shmget","shmread","shmwrite",
  "shutdown","sin","sleep","socket","socketpair","sort","splice","split",
  "sprintf","sqrt","srand","stat","study","substr","symlink","syscall",
  "sysopen","sysread","sysseek","system","syswrite","tell","telldir","tie",
  "tied","time","times","truncate","uc","ucfirst","umask","undef","unlink",
  "unpack","untie","unshift","utime","values","vec","wait","waitpid",
  "wantarray","warn","write",
>);

protected mapping(string:string) prefixes = ([
  "prefix"  : "$",
  "prefix2" : "%",
  "prefix3" : "@"
]);

private mapping(string:string) _colors = ([
  "prefix"    : "#900",
  "prefix2"   : "#909",
  "prefix3"   : "#990",
  "functions" : "#C00"
]);

private mapping(string:array(string)) _styles = ([
  "prefix"  : ({ "<b>", "</b>" }),
  "prefix2" : ({ "<b>", "</b>" }),
  "prefix3" : ({ "<b>", "</b>" })
]);

protected array(array) blockcomments = ({ ({ "=pod", "=cut" }) });
protected array linecomments  = ({ "#" });

void create()
{
  keywords->keywords  = _keywords;
  keywords->functions = _functions;
  colors += _colors;
  styles += _styles;
  case_sensitive = 1;
  ::create();
}