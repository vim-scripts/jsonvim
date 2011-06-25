"{{{1 Начало
scriptencoding utf-8
if !exists('s:_pluginloaded')
    "{{{2 Объявление переменных
    execute frawor#Setup('0.0', {'@/options': '0.0',
                \              '@/resources': '0.0',
                \               '@/commands': '0.0',
                \                  '@/table': '0.0',
                \              '@/functions': '0.0',
                \                    '@/fwc': '0.0',}, 0)
    call map(['json', 'cache'], 'extend(s:F, {v:val : {}})')
    "{{{2 Define JSONCache command
    call FraworLoad('@/commands')
    call FraworLoad('@/functions')
    let s:jsoncmd={'@FWC': ['in [show purge] ~start 1', 'filter']}
    call s:_f.command.add('JSONCache', s:jsoncmd,
                \         {'nargs': '1', 'complete': [s:jsoncmd['@FWC'][0]]})
    "}}}2
    finish
elseif s:_pluginloaded
    finish
endif
"{{{1 Вторая загрузка
"{{{2 s:_options
let s:_options={
            \'UsePython': {'default': has('python') || has('python3'),
            \               'filter': 'bool'},
        \}
"{{{2 s:cache
let s:cache={}
"{{{2 Выводимые сообщения
if v:lang=~?'ru'
    let s:_messages={
                \    'r': 'Файл %s недоступен для чтения',
                \    'w': 'Файл недоступен для записи',
                \ 'json': 'Пакет «demjson» не найден',
                \'rjson': 'Не удалось прочитать файл с данными',
                \ 'jstr': 'Неверный JSON',
                \  'jse': 'Строка в формате JSON должна заканчиваться '.
                \         'двойным штрихом («"»)',
                \  'jsu': 'Управляющая последовательность, '.
                \         'начинающаяся с «\u», должна заканчиваться '.
                \         'четырьмя шестнадцатиричными цифрами.',
                \ 'jsie': 'Неверная управляющая последовательность: '.
                \         'обратная косая черта должна следовать либо перед '.
                \         'символом «u» и четырьмя шестнадцатиричными цифрами, '.
                \         'либо перед одним из следующих символов: '.
                \         '«\», «/», «b», «f», «n», «r», «t»',
                \ 'jdup': 'Ключ «%s» уже присутствует в словаре',
                \  'jdt': 'Не найден символ двоеточия («:»)',
                \'jcoma': 'Отсутствует запятая',
                \  'joe': 'Не найдена закрывающая фигурная скобка («}»)',
                \  'jle': 'Не найдена закрывающая квадратная скобка («]»)',
                \ 'uact': 'Неизвестное действие',
                \  'utf': 'Неверный символ: %s',
                \
                \'th': ['Файл', 'Время последнего изменения'],
                \'emptycache': 'Кэш пуст',
            \}
else
    let s:_messages={
                \    'r': 'File %s is not readable',
                \    'w': 'File not writable',
                \ 'json': 'Demjson must be installed in your system',
                \'rjson': 'Failed to read JSON file',
                \ 'jstr': 'Invalid JSON string',
                \  'jse': 'JSON string must end with “"”',
                \  'jsu': '“\u” must be followed by four hex digits',
                \ 'jsie': 'Invalid escape: backslash must be followed by '.
                \         '“u” and four hex digits or '.
                \         'one of the following characters: '.
                \         '“\”, “/”, “b”, “f”, “n”, “r”, “t”',
                \ 'jkey': 'Key in JSON object must be of a type “string”',
                \ 'jdup': 'Key “%s” is already present in this dictionary',
                \  'jdt': 'Colon not found',
                \'jcoma': 'Missing comma',
                \  'joe': 'Object must end with “}”',
                \  'jle': 'List must end with “]”',
                \ 'uact': 'Uknown action',
                \  'utf': 'Invalid UTF symbol: %s'
                \
                \'th': ['File', 'Modification time'],
                \'emptycache': 'Cache is empty',
            \}
endif
"{{{1 Вторая загрузка — функции
"{{{2 json: dump, load, cload
"{{{3 s:json
"  values — значения соответствующих объектов
" escapes — список символов, которые можно экранировать и соответствующих им
"           «реальных» символов
" lstinner, objinner — значения по умолчанию для внутренних функций
"           json.getlst и json.getobj соответственно. Нужны, так как в функцию 
"           json.end необходимо передавать ссылки на переменные (все функции 
"           принадлежат парсеру JSON) (перенесены в начало соответствующих 
"           функций).
let s:json={
            \'values': {
            \    'null': '',
            \    'true': 1,
            \   'false': 0,
            \},
            \'escapes': {
            \   '"': '"',
            \   '\': '\',
            \   '/': '/',
            \   'b': "\b",
            \   'f': "\f",
            \   'n': "\n",
            \   'r': "\r",
            \   't': "\t",
            \},
        \}
" reg — регулярные выражения:
"  val — для получения объектов из json.values,
"  num — для выделения числа из строки,
"  str — для выделения строкового объекта JSON,
"  var — регулярное выражение для определения имени переменной, в которую
"        разрешено писать.
let s:json.reg={
            \'val': join(keys(s:json.values), '\|'),
            \'num': '^-\=\([1-9]\d*\|0\)\(\.\d\+\)\=\([eE][+\-]\=\d\+\)\=',
            \'str': '^"\([^\\"]\|\\\(u\x\{4}\|'.
            \       '['.escape(join(keys(s:json.escapes), ''), '\[]-').']'.
            \       '\)\)*"',
            \'var': '[gb]:[a-zA-Z_]\(\w\@<=\.\w\|\w\)*',
        \}
"{{{3 JSON dumper/vimscript
"{{{4 json.strstr: String->JSON
"{{{5 s:json.escrev
"  escrev — «обращённая» escapes, содержит соответствие реальных символов их
"           текстовым представлениям (под «реальным» здесь понимается то, что 
"           содержалось в памяти до перевода в JSON).
let s:json.escrev={}
call map(copy(s:json.escapes),
            \'extend(s:json.escrev, {v:val : "\\".v:key})')
"}}}5
function s:F.json.strstr(str)
    "{{{5 Пустая строка
    if a:str is# ''
        return 'null'
    endif
    "{{{5 Объявление переменных
    let result='"'
    let idx=0
    let slen=len(a:str)
    "{{{5 Представление
    while idx<slen
        " Так мы получим следующий символ без диакритики (а на следующей 
        " итерации получим диакритику без символа).
        let chnr=char2nr(a:str[(idx):])
        let char=nr2char(chnr)
        let clen=len(char)
        let chkchar=a:str[(idx):(idx+clen-1)]
        if chkchar isnot# char
            call s:_f.throw('utf', strtrans(chkchar))
        endif
        let idx+=clen
        if clen>1
            " На случай, если char2nr вернёт число, большее, чем 0xFFFF.
            if chnr<0x10000
                let result.=printf('\u%0.4x', chnr)
            " Следующий код производит корректный JSON, однако преобразование 
            " его обратно в Vim происходит некорректно (код производит 
            " суррогатную пару utf-16, обозначающую один символ, но результатом 
            " обратного преобразования является пара символов, не 
            " соответствующая стандарту UTF-8).
            elseif chnr<=0x10FFFF
                let U=chnr-0x10000
                let Uh=U/1024
                let W1=0xD800+Uh
                let W2=0xDC00+(U-(Uh*1024))
                let result.=printf('\u%0.4x\u%0.4x', W1, W2)
            else
                let result.=char
            endif
        elseif has_key(s:json.escrev, char)
            " Экранирование
            let result.=s:json.escrev[char]
        else
            let result.=char
        endif
    endwhile
    "}}}5
    return result.'"'
endfunction
"{{{4 json.strlst: List->JSON
function s:F.json.strlst(lst)
    return '['.join(map(copy(a:lst), 's:F.json.str(v:val)'), ',').']'
endfunction
"{{{4 json.strdct: Dictionary->JSON
function s:F.json.strdct(dct)
    return '{'.join(values(map(copy(a:dct),
                \'s:F.json.strstr(v:key).":".s:F.json.str(v:val)')),
                \',').'}'
endfunction
"{{{4 json.strfunc: Funcref->JSON(null)
" Представить функцию в виде JSON
function s:F.json.strfunc(func)
    return 'null'
endfunction
"{{{4 json.str: *->JSON
function s:F.json.str(obj)
    return call(s:json.conv.tojstrfunc[type(a:obj)], [a:obj], {})
endfunction
"{{{4 json.vsdumps
function s:F.json.vsdumps(obj)
    return s:F.json.str(a:obj)
endfunction
"{{{4 s:json.conv.tojstrfunc
" Функции, представляющие произвольный объект. Отсортированы в соответствии 
" с типом объекта
let s:json.conv={}
let s:json.conv.tojstrfunc=[function('string'), s:F.json.strstr,
            \s:F.json.strfunc, s:F.json.strlst, s:F.json.strdct,
            \function('string')]
"{{{3 Парсер JSON на vimscript
"{{{4 json.getnum: JSON->(Number|Float)
function s:F.json.getnum(str)
    let numstr=matchstr(a:str, s:json.reg.num)
    if numstr=~?'e'
        " 0e0 → 0.0e0 (Vim не поддерживает запись чисел с плавающей запятой
        "              без десятичной точки)
        let numstr=substitute(numstr, '^-\=\d\+[eE]\@=', '\0.0', '')
    endif
    return      { 'delta': len(numstr),
                \'result': eval(numstr),}
endfunction
"{{{4 json.getstr: JSON->String
function s:F.json.getstr(str)
    let str=matchstr(a:str, s:json.reg.str)
    let delta=len(str)
    if !delta
        call s:_f.throw('jstr')
    endif
    " Здесь необходимо добавить поддержку суррогатных пар.
    return      { 'delta': delta,
                \'result': eval(str),}
endfunction
"{{{4 json.getobj: JSON->Dictionary
"{{{5 s:json.objinner
let s:json.objinner={
            \'result': {},
            \ 'delta': 1,
            \ 'endch': '}',
            \'emsgid': 'joe',
            \}
"}}}5
function s:F.json.getobj(str)
    "{{{5 Объявление переменных
    let tlen=len(a:str)
    let inner=deepcopy(s:json.objinner)
    let inner.str=a:str
    "{{{5 Основной цикл
    while inner.delta<tlen
        "{{{6 Ключ
        " Ключ — строка, поэтому начинается с «"»
        let keystart=match(a:str, '^\_\s*\zs"', inner.delta)
        if keystart==-1
            return s:F.json.end(inner)
        endif
        let inner.delta=keystart
        " Получить строку
        let lastret=s:F.json.getstr(a:str[(inner.delta):])
        if type(lastret)==type(0)
            call s:_f.throw('jkey')
        endif
        let inner.delta+=lastret.delta
        let key=lastret.result
        unlet lastret

        if has_key(inner.result, key)
            call s:_f.throw('jdup', key)
        endif
        "{{{6 Двоеточие
        let resstart=match(a:str, '^\_\s*\zs:', inner.delta)
        if resstart==-1
            call s:_f.throw('jdt')
        endif
        let inner.delta=resstart+1
        "{{{6 Получить значение
        let lastret=s:F.json.get(a:str[(inner.delta):])
        if type(lastret)==type(0)
            return lastret
        endif
        let inner.delta+=lastret.delta
        let inner.result[key]=lastret.result
        unlet lastret
        "{{{6 Запятая или конец объекта после значения
        let comma=match(a:str, '^\_\s*\zs,', inner.delta)
        if (comma)==-1
            return s:F.json.end(inner)
        endif
        let inner.delta=(comma+1)
        "}}}6
    endwhile
    "}}}5
    call s:_f.throw('joe')
endfunction
"{{{4 json.getlst: JSON->List
"{{{5 s:json.lstinner
let s:json.lstinner={
            \'result': [],
            \ 'delta': 1,
            \ 'endch': ']',
            \'emsgid': 'jle',
            \}
"}}}5
function s:F.json.getlst(str)
    "{{{5 Объявление переменных
    let tlen=len(a:str)
    let inner=deepcopy(s:json.lstinner)
    let inner.str=a:str
    "{{{5 Основной цикл
    while inner.delta<tlen
        "{{{6 Следующий объект
        let lastret=s:F.json.get(a:str[(inner.delta):])
        if type(lastret)==type(0)
            return s:F.json.end(inner)
        endif
        let inner.delta+=lastret.delta
        call add(inner.result, lastret.result)
        unlet lastret
        "{{{6 Запятая
        let comma=match(a:str, '^\_\s*\zs,', inner.delta)
        if (comma)==-1
            return s:F.json.end(inner)
        endif
        let inner.delta=(comma+1)
        "}}}6
    endwhile
    "}}}5
    call s:_f.throw('jle')
endfunction
"{{{4 json.get: JSON->vim
" Получить объект произвольного типа из JSON
function s:F.json.get(str)
    "{{{5 Объявление переменных
    let delta=match(a:str, '\_\s*\zs[[{"tfn[:digit:].\-]')
    if delta==-1
        return 0
    endif
    let char=a:str[(delta)]
    "{{{5 Строка, список или объект
    if has_key(s:json.acts, char)
        let lastret=call(s:json.acts[char], [a:str[(delta):]], {})
        if type(lastret)==type({})
            let lastret.delta+=delta
        endif
        return lastret
    "{{{5 Число
    elseif char=~#'[[:digit:].\-]'
        let lastret=s:F.json.getnum(a:str[(delta):])
        if type(lastret)==type({})
            let lastret.delta+=delta
        endif
        return lastret
    "{{{5 Другое
    else
        let str=matchstr(a:str, s:json.reg.val, delta)
        let lstr=len(str)
        if !lstr
            return 0
        endif
        return      { 'delta': delta+lstr,
                    \'result': s:json.values[str], }
    endif
    "}}}5
    return 0
endfunction
"{{{4 json.end
" Проверить, не конец ли это текущего объекта (словаря или списка)
function s:F.json.end(inner)
    let end=match(a:inner.str, '^\_\s*\zs'.a:inner.endch, a:inner.delta)
    if (end)!=-1
        return      { 'delta': (end+1),
                    \'result': a:inner.result,}
    endif
    call s:_f.throw(a:inner.emsgid)
endfunction
"{{{4 json.vsloads: JSON->vim, throws on error
function s:F.json.vsloads(str)
    let lastret=s:F.json.get(a:str)
    if type(lastret)==type(0)
        call s:_f.throw('rjson')
    endif
    return lastret.result
endfunction
"{{{4 s:json.acts
let s:json.acts={
            \'"': s:F.json.getstr,
            \'[': s:F.json.getlst,
            \'{': s:F.json.getobj,
            \}
"{{{3 json.setpython:
function s:F.json.setpython()
python <<EOF
import vim
try:
    import demjson as json
    loadfunc=json.decode
    dumpfunc=json.encode
except ImportError:
    try:
        import simplejson as json
    except ImportError:
        import json
    loadfunc=json.loads
    dumpfunc=json.dumps
EOF
endfunction
"{{{3 json.loads: JSON string->vim
" Загрузка переменной из JSON
function s:F.json.loads(str)
    "{{{4 Использовать ли Python?
    if !(has('python') || has('python3')) || !s:_f.getoption('UsePython')
        return s:F.json.vsloads(a:str)
    endif
    "{{{4 null, true и false
    for O in keys(s:json.values)
        execute 'let '.O.'=s:json.values[O]'
    endfor
    "{{{4 Собственно, загрузка
    try
        call s:F.json.setpython()
        python jstr=loadfunc(vim.eval('a:str'))
        " Simplejson не поддерживает UTF-8 символы выше 0x10FFFF, а demjson не 
        " сваливается с ошибкой, если встречается неверный UTF-8.
        " //Кроме того, demjson выдаёт UTF-8 строку, которую, если она содержит 
        " //не-ASCII символы, не удаётся засунуть в vim.command, тогда как 
        " //строка, выдаваемая simplejson не содержит не-ASCII символов.
        " Удаётся, через str(bytearray(jstr, "utf-8")) или через 
        " jstr.encode("ascii", "backslashreplace")
        " //И ещё, при попытке использовать в файле суррогатные пары получается 
        " //не тот результат, на который мы рассчитывали (simplejson).
        python vim.eval("extend(l:, {'tmp': '"+
                    \str(bytearray(jstr, 'utf-8')).replace("'", "''")+"'})")
        return tmp
    catch
        return s:F.json.vsloads(a:str)
    endtry
    "}}}4
endfunction
"{{{3 json.dumps: vim->JSON string
function s:F.json.dumps(what)
    "{{{4 Проверка возможности записи
    "{{{4 Использовать ли Python?
    if !has('python') || !s:_f.getoption('UsePython')
        return s:F.json.vsdumps(a:what)
    endif
    "{{{4 Собственно, выгрузка
    try
        call s:F.json.setpython()
        python var=vim.eval('a:what')
        " Simplejson не поддерживает UTF-8 символы выше 0x10FFFF, а demjson не 
        " сваливается с ошибкой, если встречается неверный UTF-8.
        python vim.eval("extend(l:, {'str': '"+
                    \str(bytearray(dumpfunc(var), 'utf-8')).replace("'", "''")+
                    \"'})")
        return str
    catch
        return s:F.json.vsdumps(a:what)
    endtry
    python fd.close()
    "}}}4
    return 1
endfunction
"{{{3 json.dump
function s:F.json.dump(fname, what)
    let fname=fnamemodify(a:fname, ':p')
    let str=s:F.json.dumps(a:what)
    return writefile([str], fname)!=1
endfunction
"{{{2 cache: load, purge
"{{{3 cache.load: cached JSON file->vim
" Загрузить информацию из файла, если этот файл не загружался ранее или 
" изменился со времени последней загрузки. Иначе вернуть значение из кэша. При 
" наличии дополнительного аргумента, равного единице, игнорировать кэш.
function s:F.cache.load(fname, ...)
    let ftime=getftime(a:fname)
    if !(len(a:000) && a:000[0]) && has_key(s:cache, a:fname) &&
                \s:cache[a:fname][0]==ftime
        return s:cache[a:fname][1]
    endif
    let fname=fnamemodify(a:fname, ':p')
    if !filereadable(fname)
        call s:_f.throw('r', fname)
    endif
    let str=join(readfile(fname, 'b'), "\n")
    let result=s:F.json.loads(str)
    let s:cache[a:fname]=[ftime, result]
    return result
endfunction
"{{{3 cache.show
function s:F.cache.show()
    if empty(s:cache)
        echo s:_messages.emptycache
        return 1
    endif
    if exists('*strftime')
        let lines=values(map(copy(s:cache),
                    \'[v:key, strftime("%c", v:val[0])]'))
    else
        let lines=values(map(copy(s:cache),
                    \'[v:key, v:val[0]]'))
    endif
    call s:_r.printtable(lines, {'header': s:_messages.th})
    return 1
endfunction
"{{{2 jsoncmd.function
function s:jsoncmd.function(action)
    if a:action is# 'show'
        return s:F.cache.show()
    elseif a:action is# 'purge'
        let s:cache={}
        return 1
    endif
endfunction
"{{{2 Define json resource
call s:_f.postresource('json', {'dump': s:F.json.dump,
            \                  'dumps': s:F.json.dumps,
            \                   'load': s:F.cache.load,
            \                  'loads': s:F.json.loads,})
"{{{1
call frawor#Lockvar(s:, 'cache,_pluginloaded')
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8
