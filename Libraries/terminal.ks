// Import libraries

print "terminal: LOADING".

// Lexicon to load library functions into main script
global terminal is lex(
    "init", init@,
    "print_t", print_t@
).

function init {}
terminal["init"]().

