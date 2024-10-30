
" script encoding
scriptencoding utf-8

" load control
if !exists('g:loaded_vim_yamove')
    finish
endif

let g:loaded_vim_yamove = 1

let s:save_cpo = &cpo
set cpo&vim

let g:yaMoveLimitedDirection = 0

function LineIndentCount(line)
    let numSpaces = 0
    if (len(trim(a:line)) == 0)
        return -1
    endif
    while(a:line[numSpaces] == ' ')
        let numSpaces += 1
    endwhile
    return numSpaces
endfunction

function GoToLine(lineNumber)
    execute "norm " . a:lineNumber . "G"
    execute "norm ^"
endfunction

function! EchoWarning(msg)
    echohl WarningMsg
    echo a:msg
    echohl None
endfunction

function yamove#YaMove(direction, desiredIndentChange)
    let currentLineIndex = line('.')
    let totalLines = line('$')
    let startLine = getline(currentLineIndex)
    let startIndents = LineIndentCount(startLine)

    if !exists("g:enableYaMoveMultipleHits")
        let g:enableYaMoveMultipleHits = 0
    endif

    if (startIndents == -1)
        let startIndents = 0
    endif

    let currentLineIndex += a:direction
    let currentLine = getline(currentLineIndex)
    let currentIndents = LineIndentCount(currentLine)

    while (currentLineIndex > 0 && currentLineIndex <= totalLines)
        "If at same depth
        if (currentIndents == startIndents)
            " If trying to find another line on same level, move and exit
            if (a:desiredIndentChange == 0)
                call GoToLine(currentLineIndex)
                return
            " If trying to go in a level, exit
            elseif (a:desiredIndentChange > 0)
                return
            endif
        endif

        "If we find a higher level
        if (currentIndents < startIndents && currentIndents != -1)
            " If looking for higher level, move and exit
            if (a:desiredIndentChange < 0)
                call GoToLine(currentLineIndex)
                return
            else
                if (g:yaMoveLimitedDirection == a:direction && g:enableYaMoveMultipleHits == 1)
                    let g:yaMoveLimitedDirection = 0
                    call GoToLine(currentLineIndex)
                    return
                else
                    let g:yaMoveLimitedDirection = a:direction
                    call EchoWarning("YaMove Hit Limit")
                    return
                endif
                "Exit if found higher level for other movements
                return
            endif
        endif

        " If found deeper indentation and we want it, move and exit
        if (currentIndents > startIndents && a:desiredIndentChange > 0)
            call GoToLine(currentLineIndex)
            return
        endif

        let currentLineIndex += a:direction
        let currentLine = getline(currentLineIndex)
        let currentIndents = LineIndentCount(currentLine)

    endwhile

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
