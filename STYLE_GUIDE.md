#Style

variables which start data are underscored, eg combined_df

functions are camelCase, eg doSomething()

all scripts should start with a shebang line including env, eg #!/usr/bin/env python or #!/usr/bin/env nextflow

dependencies go under the shebang

for scripts meant to run from the cmd line, main method goes under the dependencies (at the top rather than the bottom of the script).

try for descriptive variable names and frequent comments

docstrings should go at the top of every script, and under every function declaration. For python, use this format for function definitions:

def doSomething(arg1, arg2, *args, **kwargs):
   """
      this is my description. Explain the variable entries somewhere, maybe in the params, maybe here
      usage: doSomething(arg1)
      :throws: any errors that the function throws. To the extent possible, check input and handle errors with a descriptive message. functions should throw errors to be caught in calling script.
      :params arg1: description
      :params arg2: description
      :returns: some value
   """
   raise NotImplementedError
