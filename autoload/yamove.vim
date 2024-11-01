
" script encoding
scriptencoding utf-8

" load control
if !exists('g:loaded_vim_yamove')
    finish
endif

let g:loaded_vim_yamove = 1

let s:save_cpo = &cpo
set cpo&vim

let g:YaMoveLastAttemptedDirection = 0
let g:yaMoveAttemptedInnerMove = 0

function CurrentLineNumber()
    return line(".")
endfunction

function SmartFoldCloseOnMoveOut()
    if !exists("g:enableYaMoveCloseOnMoveOut")
        let g:enableYaMoveCloseOnMoveOut = 1
    endif
    return g:enableYaMoveSmartFolds == 1
endfunction


function SmartFoldsEnabled()
    if !exists("g:enableYaMoveSmartFolds")
        let g:enableYaMoveSmartFolds = 0
    endif
    return g:enableYaMoveSmartFolds == 1
endfunction

function MoveOnMultipleHits()
    if !exists("g:yaMoveOnMultipleHits")
        let g:yaMoveOnMultipleHits = 1
    endif
    return g:yaMoveOnMultipleHits == 1
endfunction

function GetIndentationDepth(lineNumber)
    let lineText = getline(a:lineNumber)
    let index = 0

    " If no text in line, return -1
    if len(trim(lineText)) == 0
        return -1
    endif

    while (lineText[indent] == " " || lineText[index] == '\t')
        let index += 1
    endwhile
    return index
endfunction

function IsFolded(lineNumber)
    return foldclosed(a:lineNumber) != -1
endfunction

function GetEndOfIndentationLevel(lineNumber, direction)
    let lineIndex = a:lineNumber
    let startIndentationDepth = GetIndentationDepth(lineIndex)
    let lastLine = line('$')

    "If at 0 indentation, depth is entire file
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
        let indentationDepth GetIndentationDepth(lineIndex)
        if (lineIndex > lastLine)
            return lastLine
        elseif (lineIndex < 1)
            return 1
        endif
    endwhile
    return lineIndex
endfunction

function GetNextSameIndentation(lineNumber, direction)
    let startIndentationDepth = GetIndentationDepth(a:lineNumber)
    let indentationDepth = GetIndentationDepth(a:lineNumber + a:direction)
    let lineIndex = a:lineNumber + a:direction
    let totalLines = line('$')

    while (indentationDepth >= startIndentationDepth || indentationDepth == -1)
        if (indentationDepth == startIndentationDepth)
            return lineIndex
        endif

        "If beyond top or bottom, return start position
        if (lineIndex < 0 || lineIndex > totalLines)
            return a:lineNumber
        endif

        let lineIndex += a:direction
        let indentationDepth = GetIndentationDepth(lineIndex)
    endwhile
    return a:lineNumber
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


function MoveToLine(...)
    let lineNumber = a:1
    let store = 0
    if (a:0 > 1)
        let store = a:2
    endif
    if (store == 1)
        execute "norm " . lineNumber . "G"
    else
        call cursor(lineNumber, 0)
        execute "norm ^"
    endif
endfunction

function YaMoveUpDownPosition(currentLine, direction)
    let nextPosition = GetNextSameIndentation(a:currentLine, a:direction)
    " TODO: Remove this function
    if (nextPosition != a:currentLine)
        return nextPosition
    endif
    return a:currentLine
endfunction

function yamove#YaMoveUp()
    let currentLine = CurrentLineNumber()
    let position = YaMoveUpDownPosition(currentLine, -1)

    "If new position, move and exit
    if (currentLine != position)
        let g:YaMoveLastAttemptedDirection = 0
        call MoveToLine(position, 1)
    else
        if (g:YaMoveLastAttemptedDirection == -1)
            call yamove#YaMoveOut()
            let g:YaMoveLastAttemptedDirection = 0
        else
            let g:YaMoveLastAttemptedDirection = -1
        endif
    endif
endfunction

function yamove#YaMoveDown()
    let currentLine = CurrentLineNumber()
    let position = YaMoveUpDownPosition(currentLine, 1)

    "If new position, move and exit
    if (currentLine != position)
        let g:YaMoveLastAttemptedDirection = 0
        call MoveToLine(position, 1)
    else
        if (g:YaMoveLastAttemptedDirection == 1)
            call yamove#YaMoveOutDown()
            let g:YaMoveLastAttemptedDirection = 0
        else
            let g:YaMoveLastAttemptedDirection = 1
        endif
    endif
endfunction

function yamove#YaMoveOut()
    let top = GetEndOfIndentationLevel(CurrentLineNumber(), -1)
    call MoveToLine(top)
    if (SmartFoldsEnabled() && SmartFoldCloseOnMoveOut())
        call yamove#YaFoldBelow(top)
    endif
    call MoveToLine(top, 1)
endfunction

function yamove#YaMoveOutDown()
    let currentLine = CurrentLineNumber()
    let bottom = GetEndOfIndentationLevel(currentLine, 1)
    if (SmartFoldsEnabled() && SmartFoldCloseOnMoveOut())
        let top = GetEndOfIndentationLevel(currentLine, -1)
        call MoveToLine(top)
        call yamove#YaFoldBelow(top)
    endif
    call MoveToLine(bottom, 1)
endfunction

function yamove#YaMoveIn()
    let currentLine = CurrentLineNumber()
    if (IsFolded(currentLine))
        return
    endif
    let line = YaMoveInDirectional(1)

    "If not moving, do nothing
    if (line == currentLine)
        if (MoveOnMultipleHits())
            if (g:yaMoveAttemptedInnerMove == 1)

                " TODO
                "echom "Attempt to find next line and move in"
                let g:yaMoveAttemptedInnerMove = 0
            else
                let g:yaMoveAttemptedInnerMove = 1
            endif
        endif
        return
    endif

    if (IsFolded(line))
        call YaUnfoldBelow(currentLine)
    endif

    call MoveToLine(line, 1)
    if (&foldmethod == "indent")
        norm zo
    endif
endfunction

function yamove#YaMoveInUp()
    let currentLine = CurrentLineNumber()
    let line = YaMoveInDirectional(-1)
    if (line == currentLevel)
        " TODO look at YaMoveIn
        return
    endif

    if (IsFolded(line))
        let previousLine = YaMoveUpDownPosition(currentLine, -1)
        call YaUnfoldBelow(previousLine)
    endif

    let startDepth = GetIndentationDepth(currentLine)
    while (GetIndentationDepth(GetEndOfIndentationLevel(line, -1))
            \ != startDepth)
        let line = GetEndOfIndentationLevel(line, -1)
    endwhile

    call MoveToLine(line, 1)
endfunction

function YaFoldBelowIndent(lineNumber)
    call MoveToLine(a:lineNumber)
    norm jzc
    call MoveToLine(a:lineNumber)
endfunction

function yamove#YaFoldBelow(lineNumber)
    let startLine = a:lineNumber
    let foldLine = YaMoveInDirectional(1)
    if (startLine == foldLine)
        return
    endif

    if (IsFolded(foldLine))
        return
    endif

    if (&foldmethod == "indent")
        call YaFoldBelowIndent(a:lineNumber)
        return
    endif
    if (&foldmethod != "manual")
        echom "foldmethod must be set to 'manual' or 'indent' to use YaMove folds"
    endif

    " Get fold range
    let foldTop = GetEndOfIndentationLevel(foldLine, -1) + 1
    let foldBottom = GetEndOfIndentationLevel(foldLine, 1) - 1
    if foldBottom = line('$') - 1
        let foldBottom = foldBottom + 1
    endif

    " Fold
    call FoldSection(foldTop, foldBottom)
    call MoveToLine(a:lineNumber)
endfunction

function FoldSection(startLine, endLine)
    let currentPosition = CurrentLineNumber()
    execute "norm " . a:startLine . "Gzf" . a:endLine . "G"
    call MoveToLine(currentPosition)
endfunction

function yamove#YaUnfoldBelow(lineNumber)
    call MoveToLine(a:lineNumber)
    norm jzok
    call yamove#YaMoveIn()
    let currentLine = CurrentLineNumber()
    call yamove#YaFoldBelow(currentLine)
    let nextLine = YaMoveUpDownPosition(currentLine, 1)
    while (currentLine != nextLine)
        let currentLine = nextLine
        let nextLine = YaMoveUpDownPosition(currentLine, 1)
        call MoveToLine(currentLine)
        call yamove#YaFoldBelow(currentLine)
    endwhile
    call MoveToLine(a:lineNumber)
endfunction

function yamove#ToggleYaFold()
    let startLine = CurrentLineNumber()
    let nextLine = startLine + 1
    if (IsFolded(nextLine))
        call yamove#YaUnfoldBelow(startLine)
    else
        call yamove#YaFoldBelow(startLine)
    endif
endfunction

function yamove#YaMoveToggleSmartFolds()
    if (g:enableYaMoveSmartFolds == 1)
        let g:enableYaMoveSmartFolds = 0
    else
        let g:enableYaMoveSmartFolds = 1
    endif
endfunction



"function yamove#YaMoveOut()
    "let position = GetEndOfIndentationLevel(CurrentLineNumber(), -1)
    "call MoveToLine(position)
    "let g:yaMoveLimitedDirection = 0
"endfunction
"
"function yamove#YaMoveOutDown()
    "let position = GetEndOfIndentationLevel(CurrentLineNumber(), 1)
    "call MoveToLine(position)
    "let g:yaMoveLimitedDirection = 0
"endfunction
"
"function yamove#YaMoveIn()
    "let position = YaMoveInDirectional(1)
    "call MoveToLine(position)
    "let g:yaMoveLimitedDirection = 0
"endfunction
"
"function yamove#YaMoveInUp()
    "let position = YaMoveInDirectional(-1)
    "call MoveToLine(position)
    "let g:yaMoveLimitedDirection = 0
"endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
