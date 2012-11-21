"RelaFile.vim - A utility for generating shortcuts to relative files. {{{1
"
" I Originally created for quickly jumping through django projects where
"
" \1 <appname>/models.py
" \2 <appname>/views.py
" \3 <appname>/admin.py
" \4 <appname>/forms.py
" \5 <appname>/tests.py
"
" etc.
"
"
" Global variables can be set  {{{1
"
" Directories of interest can be populated with a startup script
if !exists('g:relafile_directories_of_interest')
    let g:relafile_directories_of_interest = []
endif

" Active Directories are directories where a buffer has actively been

" altenately Landmark files appear in <app directory structure>
" eg in django ['models.py','views.py','temlatetags/','management/']
" note this will only work with 'quick' and 'active' modes.
"
if !exists('g:relafile_landmark_files')
    let g:relafile_landmark_files = []
endif

" Script level variables {{{1
let s:active_directories = []
let s:last_active_directory = ''

" Inner Functions {{{1
function s:set_active_directory()
    if &modifiable == 0
        return
    endif

    let dir = expand("%:h")

    if (index(s:active_directories,dir) >=0)
        let s:last_active_directory = dir
        return
    endif

    if (index(g:relafile_directories_of_interest, dir) >=0)
        let s:active_directories = add(s:active_directories,dir)
        let s:last_active_directory = dir
    endif

    for landmark in g:relafile_landmark_files
        if filereadable(expand('%:h') .'/'. landmark) || isdirectory(expand('%:h') .'/'. landmark )
            if (index(s:active_directories, dir) == -1)
                let s:active_directories = add(s:active_directories,dir)
            endif

            let s:last_active_directory = dir
        endif
    endfor
endfunction

" Global Functions {{{1
function relafile#getfile(pattern,mode,command)
    if a:mode == 'quick' && s:last_active_directory != ''
        exec a:command . " " . s:last_active_directory . "/" . a:pattern
        return
    endif

    let confirm_directories = []

    if a:mode == 'active' && len( s:active_directories ) > 0
        let confirm_directories = s:active_directories
    endif

    if a:mode == 'all' && len(g:relafile_directories_of_interest) != []
        let confirm_directories = s:active_directories
    endif

    if len(confirm_directories) == 1
        exec a:command . " " . confirm_directories[0] . "/" . a:pattern
        return
    endif

    "TODO: I'm sticking this here until I get a better method of
    " confirm() working
    "
    if len(confirm_directories ) > 9
        echo "relafile is currently limited to 9 directories. This vim session has " .
                    \ len (confirm_directories)
        return
    endif

    if len(confirm_directories )> 1
        let constring = ' '
        let i = 1
        for dir in confirm_directories
            let constring .= '&' . i . ' ' . dir . " \n"
            let i=i+1
        endfor

        let choice = confirm("(". a:pattern . ") from where?",constring,0)

        if choice !=0
            exec a:command . " " . confirm_directories[choice -1 ] . "/" . a:pattern
            return
        endif
    endif

    echo "can't determine relative file. " .s:last_active_directory
endfunction

" Autocommands {{{1

au BufEnter * call <sid>set_active_directory()
