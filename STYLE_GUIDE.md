# Style

### general
- all executables should start with a shebang line including env, eg #!/usr/bin/env python or #!/usr/bin/env nextflow  
- docstrings should go at the top of all scripts with a usage example and input explanations.
- Python functions should be documented like so:  
```
def doSomething(arg1, arg2, *args, **kwargs):  
   """
      this is my description. Explain the variable entries somewhere, maybe in the params, maybe here
      usage: doSomething(arg1)
      :params arg1: description
      :params arg2: description
      :throws: any errors that the function throws. To the extent possible, check input and handle errors with a descriptive message. functions should throw errors to be caught in calling script.
      :returns: some value
   """
   raise NotImplementedError
```  

### Idiosyncracies (please let these conventions override any contradictions in the style guides below)
- variables which start data are underscored, eg combined_df
- functions are camelCase, eg doSomething() 
- main methods go at the top of a script, not the bottom
- variable names should be descriptive
- within reason, everything should be described with an inline comment

### bash style guide
https://google.github.io/styleguide/shellguide.html  
please see scripts/bash/RunNovoalign.sh for an example, and please feel free to use the styleguide to critique this script and update it as necessary to comply.  
Otherwise, please use the script as a template for other bash scripts for the sake of consistency.

### R style guide
The first is a derivative (extremely short) of the second.  
https://google.github.io/styleguide/Rguide.html  
http://adv-r.had.co.nz/Style.html

### python style guide (note idiosyncratic exceptions)
https://www.python.org/dev/peps/pep-0008/  

### Nextflow
An official style guide doesn't yet exist. However, please use this as a guide:
- https://github.com/nf-core/rnaseq  
