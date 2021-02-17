# this holds functions used in more than one of the scripts in this directory

checkPath(){
    # check path for a command
    # input $1 is the argument passed to this function
    # input $2 is the error message to display if it is not found
        # check if novoalign is available on the system
    # cite: https://stackoverflow.com/a/677212/9708266
    if ! command -v $1 &> /dev/null
    then
        echo $2
        exit 1
    fi
}