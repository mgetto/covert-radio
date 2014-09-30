#!/bin/bash

_covert-radio()
{
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="pause resume off listen on-air on-air-history station-list station"

    if [[ $COMP_CWORD == 1 ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

    if [[ $COMP_CWORD == 2 && $prev == "listen" ]] ; then
		opts=`covert-radio station-list`
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

}
complete -F _covert-radio covert-radio

