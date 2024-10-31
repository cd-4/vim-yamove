
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

function CurrentLineNumber()
    return line(".")
endfunction

function GetLineIndentationDepth(lineNumber)
    let lineText = getline(a:lineNumber)
    let index = 0

    " If not text in line, return -1
    if len(trim(lineText)) == 0
        return -1
    endif

    while (lineText[index] == " " || lineText[index] == '\t')
        let index += 1
    endwhile
    return index
endfunction


function GetEndOfIndentationLevel(lineNumber, direction)
    let lineIndex = a:lineNumber
    let startIndentationDepth = GetLineIndentationDepth(lineIndex)
    let lastLine = line('$')

    " If at 0 indentation, depth is entire file
    if (startIndentationDepth == 0)
        if (a:direction == -1)
            return 1
        else
            return lastLine
        endif
    endif

    let indentationDepth = startIndentationDepth
    while (indentationDepth >= startIndentationDepth || indentationDepth == -1)
        let lineIndex += a:direction
        let indentationDepth = GetLineIndentationDepth(lineIndex)
        if (lineIndex > lastLine)
            return lastLine
        elseif (lineIndex < 1)
            return 1
        endif
    endwhile
    return lineIndex
endfunction

function GetNextSameIndentation(lineNumber, direction)
    let startIndentationDepth = GetLineIndentationDepth(a:lineNumber)
    let lineIndex = a:lineNumber + a:direction
    let indentationDepth = GetLineIndentationDepth(lineIndex)
    let totalLines = line('$')

    while (indentationDepth >= startIndentationDepth || indentationDepth == -1)
        if (indentationDepth == startIndentationDepth)
            return lineIndex
        endif

        "If we are beyond t op or bottom of file, return start position
        if (lineIndex < 0 || lineIndex > totalLines)
            return a:lineNumber
        endif

        let lineIndex += a:direction
        let indentationDepth = GetLineIndentationDepth(lineIndex)
    endwhile
    return a:lineNumber
endfunction

function MoveToLine(lineNumber)
    execute "norm " . a:lineNumber . "G"
    execute "norm ^"
endfunction

function YaMoveUpDownPosition(currentLine, direction)
    let nextPosition = GetNextSameIndentation(a:currentLine, a:direction)
    if (nextPosition != a:currentLine)
        return nextPosition
    endif
    return a:currentLine
endfunction

function YaMoveInDirectional(direction)
    let startLine = CurrentLineNumber()
    let startIndentation =  GetLineIndentationDepth(startLine)
    let currentLine = startLine + a:direction
    while (GetIndentationDepth(currentLine) == -1)
        let currentLine += a:direction
    endwhile

    let resultIndentation = GetIndentationDepth(currentLine)
    if (resultIndentation > startIndentation)
        return currentLine
    endif
    return startLine
endfunction

function yamove#YaMoveUp()
    let position = GetNextSameIndentation(CurrentLineNumber(), -1)
    call MoveToLine(position)
endfunction

function yamove#YaMoveDown()
    let position = GetNextSameIndentation(CurrentLineNumber(), 1)
    call MoveToLine(position)
endfunction

function yamove#YaMoveOut()
    let position = GetEndOfIndentationLevel(CurrentLineNumber(), -1)
    call MoveToLine(position)
endfunction

function yamove#YaMoveOutDown()
    let position = GetEndOfIndentationLevel(CurrentLineNumber(), 1)
    call MoveToLine(position)
endfunction

function yamove#YaMoveIn()
    let position = YaMoveInDirectional(1)
    call MoveToLine(position)
endfunction

function yamove#YaMoveInUp()
    let position = YaMoveInDirectional(-1)
    call MoveToLine(position)
endfunction

function YaFoldBelow(lineNumber)
    let startLine = a:lineNumber
    let foldLine = YaMoveInDirectional(1)
    if (startLine == foldLine)
        return
    endif

    let foldTop = GetEndOfIndentationLevel(foldLine, -1) + 1
    let foldBottom = GetEndOfIndentationLevel(foldLine, 1) - 1
    if foldBottom = line('$') - 1
        let foldBottom += 1
    endif

    execute "norm " . foldTop . "Gzf" . (foldBottom - foldTop) . "j"
    call MoveToLine(startLine)
endfunction

function YaUnfoldBelow(lineNumber)
    "Open enclosing fold
    norm jzo

    " Close other folds inside
    let currentLine = CurrentLineNumber()
    let nextLine = YaMoveUpDownPosition(currentLine, 1)
    while (nextLine != currentLine)
        echo currentLine
        call YaFoldBelow(currentLine)
        let currentLine = nextLine
        let nextLine = YaMoveUpDownPosition(currentLine, 1)
    endwhile
    echo nextLine

    call MoveToLine(a:lineNumber)
endfunction

function yamove#ToggleYaFold()
    let startLine = CurrentLineNumber()
    let nextLine = startLine + 1
    if (foldclosed(nextLine) == -1)
        call YaFoldBelow(startLine)
    else
        call YaUnfoldBelow(startLine)
    endif
endfunction



"function LineIndentCount(line)
"    let numSpaces = 0
"    if (len(trim(a:line)) == 0)
"        return -1
"    endif
"    while(a:line[numSpaces] == ' ')
"        let numSpaces += 1
"    endwhile
"    return numSpaces
"endfunction
"
"function GoToLine(lineNumber)
"    execute "norm " . a:lineNumber . "G"
"    execute "norm ^"
"endfunction
"
"function! EchoWarning(msg)
"    echohl WarningMsg
"    echo a:msg
"    echohl None
"endfunction
"
"function yamove#YaMoveRepeat(direction, desiredIndentChange)
"    let max_iterations = v:count ? v:count : 1
"    let iterations = 0
"    while (iterations < max_iterations)
"        let iterations += 1
"        call YaMove(a:direction, a:desiredIndentChange)
"    endwhile
"endfunction
"
"function YaMove(direction, desiredIndentChange)
"    let currentLineIndex = line('.')
"    let totalLines = line('$')
"    let startLine = getline(currentLineIndex)
"    let startIndents = LineIndentCount(startLine)
"
"    if !exists("g:enableYaMoveMultipleHits")
"        let g:enableYaMoveMultipleHits = 0
"    endif
"
"    if (startIndents == -1)
""        let startIndents = 0
"    endif
"
"    let currentLineIndex += a:direction
"    let currentLine = getline(currentLineIndex)
"    let currentIndents = LineIndentCount(currentLine)
"
"    while (currentLineIndex > 0 && currentLineIndex <= totalLines)
"        "If at same depth
"        if (currentIndents == startIndents)
"            " If trying to find another line on same level, move and exit
"            if (a:desiredIndentChange == 0)
"                call GoToLine(currentLineIndex)
"                return
"            " If trying to go in a level, exit
"            elseif (a:desiredIndentChange > 0)
"                return
"            endif
"        endif
"
"        "If we find a higher level
"        if (currentIndents < startIndents && currentIndents != -1)
"            " If looking for higher level, move and exit
"            if (a:desiredIndentChange < 0)
"                call GoToLine(currentLineIndex)
"                return
"            else
"                if (g:yaMoveLimitedDirection == a:direction && g:enableYaMoveMultipleHits == 1)
"                    let g:yaMoveLimitedDirection = 0
"                    call GoToLine(currentLineIndex)
"                    return
"                else
"                    let g:yaMoveLimitedDirection = a:direction
"                    call EchoWarning("YaMove Hit Limit")
"                    return
"                endif
"                "Exit if found higher level for other movements
"                return
"            endif
"        endif
"
"        " If found deeper indentation and we want it, move and exit
"        if (currentIndents > startIndents && a:desiredIndentChange > 0)
"            call GoToLine(currentLineIndex)
"            return
"        endif
"
"        let currentLineIndex += a:direction
"        let currentLine = getline(currentLineIndex)
"        let currentIndents = LineIndentCount(currentLine)
"
"    endwhile
"
"endfunction
"

let &cpo = s:save_cpo
unlet s:save_cpo
