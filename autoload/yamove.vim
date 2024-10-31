
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
    while (GetLineIndentationDepth(currentLine) == -1)
        let currentLine += a:direction
    endwhile

    let resultIndentation = GetLineIndentationDepth(currentLine)
    if (resultIndentation > startIndentation)
        return currentLine
    endif
    return startLine
endfunction

function yamove#YaMoveUp()
    let currentLine = CurrentLineNumber()
    let position = GetNextSameIndentation(currentLine, -1)



    if !exists("g:enableYaMoveMultipleHits")
        let g:enableYaMoveMultipleHits = 0
    endif

    if (g:enableYaMoveMultipleHits && currentLine == position)
        if (g:yaMoveLimitedDirection == -1)
            call yamove#YaMoveOut()
        else
            let g:yaMoveLimitedDirection = -1
        endif
    else
        call MoveToLine(position)
    endif

endfunction

function yamove#YaMoveDown()
    let currentLine = CurrentLineNumber()
    let position = GetNextSameIndentation(currentLine, 1)

    if !exists("g:enableYaMoveMultipleHits")
        let g:enableYaMoveMultipleHits = 0
    endif

    if (g:enableYaMoveMultipleHits && currentLine == position)
        if (g:yaMoveLimitedDirection == 1)
            call yamove#YaMoveOutDown()
        else
            let g:yaMoveLimitedDirection = 1
        endif
    else
        call MoveToLine(position)
    endif
endfunction

function yamove#YaMoveOut()
    let position = GetEndOfIndentationLevel(CurrentLineNumber(), -1)
    call MoveToLine(position)
    let g:yaMoveLimitedDirection = 0
endfunction

function yamove#YaMoveOutDown()
    let position = GetEndOfIndentationLevel(CurrentLineNumber(), 1)
    call MoveToLine(position)
    let g:yaMoveLimitedDirection = 0
endfunction

function yamove#YaMoveIn()
    let position = YaMoveInDirectional(1)
    call MoveToLine(position)
    let g:yaMoveLimitedDirection = 0
endfunction

function yamove#YaMoveInUp()
    let position = YaMoveInDirectional(-1)
    call MoveToLine(position)
    let g:yaMoveLimitedDirection = 0
endfunction

function YaFoldBelow(lineNumber)
    let startLine = a:lineNumber
    let foldLine = YaMoveInDirectional(1)
    if (startLine == foldLine)
        return
    endif

    let foldTop = GetEndOfIndentationLevel(foldLine, -1) + 1
    let foldBottom = GetEndOfIndentationLevel(foldLine, 1) - 1
    if foldBottom == line('$') - 1
        let foldBottom += 1
    endif

    " execute "norm " . foldTop . "Gzf" . (foldBottom - foldTop) . "j"
    execute "norm " . foldTop . "Gzf" . foldBottom . "G"
    call MoveToLine(startLine)
endfunction

function YaUnfoldBelow(lineNumber)
    "Open enclosing fold
    call MoveToLine(a:lineNumber)
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
    call YaFoldBelow(nextLine)

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
    call MoveToLine(startLine)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
