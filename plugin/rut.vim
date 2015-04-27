command! RutFile call <SID>RutRun(expand('%:p'))
command! RutAll call <SID>RutRunAll()
command! RutOther exe ":e " . <SID>OtherPath(expand('%:p'))
command! RutOtherSplit exe ":sp " . <SID>OtherPath(expand('%:p'))

if mapcheck("<leader>ur") == ""
    nnoremap <leader>ur :RutFile<cr>
endif
if mapcheck("<leader>ua") == ""
    nnoremap <leader>ua :RutAll<cr>
endif
if mapcheck("<leader>uo") == ""
    nnoremap <leader>uo :RutOther<cr>
endif
if mapcheck("<leader>us") == ""
    nnoremap <leader>us :RutOtherSplit<cr>
endif

hi RutPass term=reverse ctermfg=white ctermbg=darkgreen guifg=white guibg=green
hi RutFail   term=reverse ctermfg=white ctermbg=red guifg=white guibg=red

if !exists('g:rut_openQuickFix')
    let g:rut_openQuickFix = 0
endif

if !exists('g:rut_projects')
    let g:rut_projects = []
endif

if !exists('g:rut_async')
    let g:rut_async = 1
endif

if !exists('g:rut_job_id')
    let g:rut_job_id = 0
endif


function! <SID>RutRunAll()
    cal <SID>RutRun(s:project()['test_dir'])
endfunction

" relpath: path to a source or test file, relative to the repo root.
function! <SID>RutRun(relpath)
    let project = s:project()
    if !s:isUnittest(a:relpath)
        let path = <SID>OtherPath(a:relpath)
    else
        let path = a:relpath
    endif
    let makeprg = join([project['runner'], path], ' ')
    let errorformat = project['errorformat']
    if g:rut_async && exists('*jobstart')
        cal s:asyncMake(makeprg, errorformat)
    else
        cal s:syncMake(makeprg, errorformat)
    endif
endfunction

function! s:syncMake(makeprg, errorformat)
    let &l:makeprg = a:makeprg
    let &l:errorformat = a:errorformat
    exe 'cd ' . s:repoRoot()
    silent! make!
    cd -
    redraw!
    cal s:finish()
endfunction

function! s:finish()
    cal s:printSummary()
    if g:rut_openQuickFix && s:validErrorCount() > 0
        copen
    endif
endfunction

function! s:asyncMake(makeprg, errorformat)
    let g:rut_buffer = []
    if g:rut_job_id > 0
        echom printf('rut job %d in progress', g:rut_job_id)
        return
    endif
    cal setqflist([])
    let winshell = '\v(command|cmd)(.exe)?'
    let argv = [&shell, &shell =~ winshell ? '/C' : '-c', a:makeprg]
    let Cb = function('s:jobCallback')
    let cb_dict = {
        \'on_stdout': Cb,
        \'on_stderr': Cb,
        \'on_exit': Cb,
        \'errorformat': a:errorformat
    \}
    exe 'cd ' . s:repoRoot()
    let g:rut_job_id = jobstart(argv, cb_dict)
    cd -
    if g:rut_job_id <= 0
        echoerr 'rut: jobstart returned ' . g:rut_job_id
    endif
endfunction

function! s:jobCallback(job_id, data, event)
    if a:event == 'stdout' || a:event == 'stderr'
        if s:isMultiline(self['errorformat'])
            if type(a:data) == type([])
                cal extend(g:rut_buffer, a:data)
            else
                cal add(g:rut_buffer, a:data)
            endif
        else
            cal s:addqflines(a:data, self['errorformat'])
        endif
    elseif a:event == 'exit'
        let g:rut_job_id = 0
        if s:isMultiline(self['errorformat'])
            cal s:addqflines(g:rut_buffer, self['errorformat'])
            let g:rut_buffer = []
        endif
        cal s:finish()
    endif
endfunction

function! s:addqflines(lines, errorformat)
    " The 'let &l:OPTION = VALUE' dynamic scoping trick to set an option for the
    " duration of a function call doesn't seem to work from a job-control
    " callback, so save-and-restore instead.
    let orig_errorformat = &errorformat
    let &errorformat = a:errorformat
    caddexpr a:lines
    let &errorformat = orig_errorformat
endfunction

function! s:isMultiline(errorformat)
    return a:errorformat =~ '%[EWIA]'
endfunction


function! <SID>OtherPath(fullpath)
    let relpath = s:relpath(s:repoRoot(), a:fullpath)
    let project = s:project()
    if s:isUnittest(a:fullpath)
        let converter = project['unit2source']
    else
        let converter = project['source2unit']
    endif
    if type(converter) == type(function('tr'))
        let other = converter(relpath)
    else
        let [pat, sub] = converter
        let other =  substitute(relpath, pat, sub, '')
    endif
    return fnamemodify(other, ':~:.')
endfunction

function! s:validErrorCount()
    let nvalid = 0
    for entry in getqflist()
        if !entry['valid']
            continue
        endif
        let nvalid += 1
    endfor
    return nvalid
endfunction

function! s:pathToTest(fullpath)
    if a:fullpath == ''
        return ''
    elseif s:isUnittest(a:fullpath)
        return a:fullpath
    else
        return s:source2Unittest(a:fullpath)
    endif
endfunction

function! s:isUnittest(fullpath)
    let project = s:project()
    if stridx(a:fullpath, project['test_dir']) != -1
        return 1
    endif
    return 0
endfunction

function! s:printSummary()
    let nfailed = s:validErrorCount()
    if nfailed > 0
        echohl RutFail
        let msg = printf('Failures: %d', nfailed)
    else
        echohl RutPass
        let msg = 'Success'
    endif
    echon msg repeat(' ', &columns - strlen(msg) - 1)
    echohl None
endfunction

function! s:project()
    let repo_root = s:repoRoot()
    for project in g:rut_projects
        if repo_root =~ project['pattern']
            return project
        endif
    endfor
    throw 'No project found for ' . repo_root
endfunction

function! s:repoRoot()
    let metadir_pattern = '\v/\.(git|hg|svn|bzr)>'
    let orig_dir = getcwd()
    let dir = orig_dir
    while 1
        let metadir = matchstr(globpath(dir, '.*', 1), metadir_pattern)
        if metadir != ''
            return dir
        endif
        let parent = fnamemodify(dir, ':h')
        if parent ==# dir
            throw "Can't find repository root"
        endif
        let dir = parent
    endwhile
endfunction

" parent and child must be absolute paths
" return a relative path from parent to child, or child.
function! s:relpath(parent, child)
    if stridx(a:child, a:parent) == 0
        return substitute(a:child[strlen(a:parent):], '^/', '', '')
    else
        return a:child
    endif
endfunction

function! s:trim(s)
    return substitute(a:s, '\v^(\s|\n)*|(\s|\n)*$', '', 'g')
endfunction
