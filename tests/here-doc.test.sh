#!/bin/bash

### Here redirect with explicit descriptor
# A space betwen 0 and <<EOF causes it to pass '0' as an arg to cat.
cat 0<<EOF
one
EOF
# stdout: one

### Here doc from another input file descriptor
# NOTE: dash seemed to fail on descriptor 99, but descriptor 5 works.
tests/read_from_fd.py 5  5<<EOF
fd5
EOF
# stdout: 5: fd5

### Multiple here docs with different descriptors
tests/read_from_fd.py 0 3 <<EOF 3<<EOF3
fd0
EOF
fd3
EOF3
# stdout-json: "0: fd0\n3: fd3\n"

### Multiple here docs in pipeline
# The second instance reads its stdin from the pipe, and fd 5 from a here doc.
tests/read_from_fd.py 3 3<<EOF3 | tests/read_from_fd.py 0 5 5<<EOF5
fd3
EOF3
fd5
EOF5
# stdout-json: "0: 3: fd3\n5: fd5\n"

### Multiple here docs in pipeline on multiple lines
# The second instance reads its stdin from the pipe, and fd 5 from a here doc.
tests/read_from_fd.py 3 3<<EOF3 |
fd3
EOF3
tests/read_from_fd.py 0 5 5<<EOF5
fd5
EOF5
# stdout-json: "0: 3: fd3\n5: fd5\n"

### Here doc with bad var delimiter
cat <<${a}
here
${a}
# stdout: here

### Here doc with bad comsub delimiter
# bash is OK with this; dash isn't.  Should be a parse error.
cat <<$(a)
here
$(a)
# stdout-json: ""
# status: 2
# BUG bash stdout: here
# BUG bash status: 0
# OK mksh status: 1

### Here doc and < redirect -- last one wins
cat <<EOF <tests/hello.txt
here
EOF
# stdout: hello

### < redirect and here doc -- last one wins
cat <tests/hello.txt <<EOF
here
EOF
# stdout: here

### Here doc with var sub, command sub, arith sub
var=v
cat <<EOF
var: ${var}
command: $(echo hi)
arith: $((1+2))
EOF
# stdout-json: "var: v\ncommand: hi\narith: 3\n"

### Here doc in middle.  And redirects in the middle.
# This isn't specified by the POSIX grammar, but it's accepted by both dash and
# bash!
echo foo > _tmp/foo.txt
echo bar > _tmp/bar.txt
cat <<EOF 1>&2 _tmp/foo.txt - _tmp/bar.txt
here
EOF
# stderr-json: "foo\nhere\nbar\n"

### Here doc line continuation
cat <<EOF \
; echo two
one
EOF
# stdout-json: "one\ntwo\n"

### Here doc with quote expansion in terminator
cat <<'EOF'"2"
one
two
EOF2
# stdout-json: "one\ntwo\n"

### Here doc with multiline double quoted string
cat <<EOF; echo "two
three"
one
EOF
# stdout-json: "one\ntwo\nthree\n"

### Two here docs -- first is ignored; second ones wins!
<<EOF1 cat <<EOF2
hello
EOF1
there
EOF2
# stdout: there

### Here doc with line continuation, then pipe.  Syntax error.
cat <<EOF \
1
2
3
EOF
| tac
# status: 2
# OK mksh status: 1

### Here doc with pipe on first line
cat <<EOF | tac
1
2
3
EOF
# stdout-json: "3\n2\n1\n"

### Here doc with pipe continued on last line
cat <<EOF |
1
2
3
EOF
tac
# stdout-json: "3\n2\n1\n"

### Here doc with builtin 'read'
# read can't be run in a subshell.
read v1 v2 <<EOF
val1 val2
EOF
echo =$v1= =$v2=
# stdout: =val1= =val2=

### Compound command here doc
while read line; do
  echo X $line
done <<EOF
1
2
3
EOF
# stdout-json: "X 1\nX 2\nX 3\n"


### Here doc in while condition and here doc in body
while cat <<E1 && cat <<E2; do cat <<E3; break; done
1
E1
2
E2
3
E3
# stdout-json: "1\n2\n3\n"

### Here doc in while condition and here doc in body on multiple lines
while cat <<E1 && cat <<E2
1
E1
2
E2
do
  cat <<E3
3
E3
  break
done
# stdout-json: "1\n2\n3\n"

### Here doc in while loop split up more
while cat <<E1
1
E1

cat <<E2
2
E2

do
  cat <<E3
3
E3
  break
done
# stdout-json: "1\n2\n3\n"

### Mixing << and <<-
cat <<-EOF; echo --; cat <<EOF2
	one
EOF
two
EOF2
# stdout-json: "one\n--\ntwo\n"



### Two compound commands with two here docs
while read line; do echo X $line; done <<EOF; echo ==;  while read line; do echo Y $line; done <<EOF2
1
2
EOF
3
4
EOF2
# stdout-json: "X 1\nX 2\n==\nY 3\nY 4\n"

### Function def and execution with here doc
func() { cat; } <<EOF; echo before; func; echo after 
1
2
EOF
# stdout-json: "before\n1\n2\nafter\n"

### Here doc as command prefix
<<EOF tac
1
2
3
EOF
# stdout-json: "3\n2\n1\n"

  # NOTE that you can have redirection AFTER the here doc thing.  And you don't
  # need a space!  Those are operators.
  #
  # POSIX doesn't seem to have this?  They have io_file, which is for
  # filenames, and io_here, which is here doc.  But about 1>&2 syntax?  Geez.
### Redirect after here doc
cat <<EOF 1>&2
out
EOF
# stderr: out

### here doc stripping tabs
cat <<-EOF
	1
	2
  3
EOF
# stdout-json: "1\n2\n  3\n"
