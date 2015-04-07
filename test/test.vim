function! RutSetupNose()
    let g:rut_projects = [{
      \'pattern': '/rut.vim$',
      \'test_dir': 'test/py/tests',
      \'source2unit': ['\v.*test/py/?(.*)/([^/]*)', 'test/py/tests/\1/test_\2'],
      \'unit2source': ['\v.*tests/?(.*)/test_([^/]*)', 'test/py/\1/\2'],
      \'runner': 'PYTHONPATH=test/py nosetests',
      \'errorformat': '%C %.%#,%A  File "%f"\, line %l%.%#,%Z%[%^ ]%\@=%m',
    \}]
endfunction

function! RutSetupRspec()
    let g:rut_projects = [{
      \'pattern': '/rut.vim$',
      \'test_dir': 'test/rb_test',
      \'source2unit': ['\v.*test/rb/?(.*)/([^/]*).rb', 'test/rb_test/rspec/\1/\2_spec.rb'],
      \'unit2source': ['\v.*test/rb_test/rspec/?(.*)/([^/]*)_spec.rb', 'test/rb/\1/\2.rb'],
      \'runner': 'RUBYLIB=test/rb rspec',
      \'errorformat': '     # %f:%l:%m',
    \}]
endfunction

function! AssertEqual(a, b)
    if a:a != a:b
        throw printf('%s != %s', a:a, a:b)
    endif
endfunction

function! RutRunTests()
    let out = ''
    redir => out
    function /RutTest
    redir END
    let test_names = split(substitute(out, '\vfunction (\w+)\([^)]*\)', '\1', 'g'), '\n')
    for name in test_names
        let Func = function(name)
        cal Func()
    endfor
    b test.vim
    redraw!
endfunction

function! ValidQuickFixErrors()
    let nvalid = 0
    for entry in getqflist()
        if !entry['valid']
            continue
        endif
        let nvalid += 1
    endfor
    return nvalid
endfunction


function! RutTest_RutOther_switches_source2unit_with_rspec()
    cal RutSetupRspec()
    e test/rb/sub/div.rb
    RutOther
    cal AssertEqual(expand('%'), 'test/rb_test/rspec/sub/div_spec.rb')
endfunction

function! RutTest_RutOther_switches_unit2source_with_rspec()
    cal RutSetupRspec()
    e test/rb_test/rspec/sub/div_spec.rb
    RutOther
    cal AssertEqual(expand('%'), 'test/rb/sub/div.rb')
endfunction

function! RutTest_RutOther_switches_unit2source_with_nose()
    cal RutSetupNose()
    e test/py/tests/sub/test_div.py
    RutOther
    cal AssertEqual(expand('%'), 'test/py/sub/div.py')
endfunction

function! RutTest_RutOther_switches_source2unit_with_nose()
    cal RutSetupNose()
    e test/py/sub/div.py
    RutOther
    cal AssertEqual(expand('%'), 'test/py/tests/sub/test_div.py')
endfunction

function! RutTest_RutFile_sets_quickfix_from_tests_using_nose()
    cal RutSetupNose()
    e test/py/toplevel.py
    cal setqflist([])
    silent! RutFile
    cal AssertEqual(ValidQuickFixErrors(), 1)
endfunction

function! RutTest_RutAll_set_quickfix_using_nose()
    cal RutSetupNose()
    cal setqflist([])
    silent! RutAll
    cal AssertEqual(ValidQuickFixErrors(), 3)
endfunction

function! RutTest_RutFile_sets_quickfix_from_source_using_rspec()
    cal RutSetupRspec()
    e test/rb/error.rb
    cal setqflist([])
    silent! RutFile
    cal AssertEqual(ValidQuickFixErrors(), 2)
endfunction

function! RutTest_RutAll_set_quickfix_using_rspec()
    cal RutSetupRspec()
    cal setqflist([])
    silent! RutAll
    cal AssertEqual(ValidQuickFixErrors(), 4)
endfunction
