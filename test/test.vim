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
