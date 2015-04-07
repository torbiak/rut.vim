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
    let &l:makeprg = join([project['runner'], path], ' ')
    echom &makeprg
    let &l:errorformat = project['errorformat']
    exe 'cd ' . s:repoRoot()
    make!
    cd -
    redraw
    cal s:printSummary()
    if g:rut_openQuickFix && s:validErrorCount() > 0
        copen
    endif
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

function! s:relpath(parent, child)
" parent and child must be absolute paths
" return a relative path from parent to child, or child.
    if stridx(a:child, a:parent) == 0
        return substitute(a:child[strlen(a:parent):], '^/', '', '')
    else
        return a:child
    endif
endfunction

function! s:trim(s)
    return substitute(a:s, '\v^(\s|\n)*|(\s|\n)*$', '', 'g')
endfunction
