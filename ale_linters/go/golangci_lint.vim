" Author: Sascha Grunert <mail@saschagrunert.de>
" Description: Adds support of golangci-lint

call ale#Set('go_golangci_lint_options', '--enable-all')
call ale#Set('go_golangci_lint_executable', 'golangci-lint')
call ale#Set('go_golangci_lint_scope', 'file')
call ale#Set('go_golangci_lint_package', 0)

function! ale_linters#go#golangci_lint#GetCommand(buffer) abort
    let l:filename = ''
    let l:options = ale#Var(a:buffer, 'go_golangci_lint_options')
    let l:lint_scope = ale#Var(a:buffer, 'go_golangci_lint_scope')
    let l:lint_package = ale#Var(a:buffer, 'go_golangci_lint_package')
    let l:cd_string = ale#path#BufferCdString(a:buffer)

    if l:lint_package && l:lint_scope is# 'file'
        let l:lint_scope = 'package'
    endif

    if l:lint_scope is# 'project'
        let l:project_root = ale#go#FindProjectRoot(a:buffer)
        let l:cd_string = ale#path#CdString(l:project_root)
    elseif l:lint_scope is# 'file'
        let l:filename = ale#Escape(expand('#' . a:buffer . ':t'))
    endif

    return l:cd_string
    \   . ale#go#EnvString(a:buffer)
    \   . '%e run '
    \   . l:filename
    \   . ' ' . l:options
endfunction

function! ale_linters#go#golangci_lint#GetMatches(lines) abort
    let l:pattern = '\v^([a-zA-Z]?:?[^:]+):(\d+):?(\d+)?:?:?:?\s\*?(.+)$'

    return ale#util#GetMatches(a:lines, l:pattern)
endfunction

function! ale_linters#go#golangci_lint#Handler(buffer, lines) abort
    let l:dir = expand('#' . a:buffer . ':p:h')
    let l:output = []

    for l:match in ale_linters#go#golangci_lint#GetMatches(a:lines)
        " l:match[1] will already be an absolute path, output from
        " golangci_lint
        call add(l:output, {
        \   'filename': ale#path#GetAbsPath(l:dir, l:match[1]),
        \   'lnum': l:match[2] + 0,
        \   'col': l:match[3] + 0,
        \   'type': 'E',
        \   'text': l:match[4],
        \})
    endfor

    return l:output
endfunction

call ale#linter#Define('go', {
\   'name': 'golangci-lint',
\   'executable': {b -> ale#Var(b, 'go_golangci_lint_executable')},
\   'command': function('ale_linters#go#golangci_lint#GetCommand'),
\   'callback': 'ale_linters#go#golangci_lint#Handler',
\   'lint_file': 1,
\})
