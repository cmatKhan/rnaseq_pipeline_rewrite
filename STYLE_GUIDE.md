# Style

### general
all executables should start with a shebang line including env, eg #!/usr/bin/env python or #!/usr/bin/env nextflow  
Idiosyncracies (please let these conventions override any contradictions in the style guides below)
- variables which start data are underscored, eg combined_df
- functions are camelCase, eg doSomething() 
- main methods go at the top of a script, not the bottom
- variable names should be descriptive
- within reason, everything should be described with an inline comment
- docstrings for all scripts and functions should look like this:  
'''
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
'''  
### bash style guide
https://google.github.io/styleguide/shellguide.html

### R style guide
The first is a derivative (extremely short) of the second.
https://google.github.io/styleguide/Rguide.html  
http://adv-r.had.co.nz/Style.html

### python style guide (note idiosyncratic exceptions)
https://www.python.org/dev/peps/pep-0008/  

### Nextflow
An official style guide doesn't yet exist. However, please use this as a guide:
- https://github.com/nf-core/rnaseq  
