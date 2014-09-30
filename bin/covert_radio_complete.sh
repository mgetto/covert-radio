#!/bin/bash

_covert-radio()
{
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="pause resume off tune info information-history stations station"

    if [[ $COMP_CWORD == 1 ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

    if [[ $COMP_CWORD == 2 && $prev == "tune" ]] ; then
		opts=`radio stations`
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

}
complete -F _covert-radio covert-radio

